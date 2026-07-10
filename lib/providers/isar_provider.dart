import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../core/database/isar_service.dart';
import '../core/utils/logger.dart';

/// The ACTIVE per-account Isar instance (uid-scoping batch, see
/// docs/uid-scoping-audit.md §2b/§4). Seeded in main.dart with the
/// uid-correct boot instance; swapped by [IsarSessionManager] on auth
/// transitions. Never read directly — go through [isarProvider].
final activeIsarProvider = StateProvider<Isar>((ref) {
  throw UnimplementedError(
      'activeIsarProvider must be overridden in main.dart');
});

/// Facade over [activeIsarProvider]. Deliberately kept a plain
/// `Provider<Isar>` with this exact name so the ~200 existing call sites are
/// untouched by per-uid instance scoping — they transparently rebuild when
/// the session manager swaps the active instance.
final isarProvider = Provider<Isar>((ref) => ref.watch(activeIsarProvider));

final isarSessionManagerProvider = Provider<IsarSessionManager>((ref) {
  return IsarSessionManager(ref);
});

/// Swaps the active per-account Isar instance on auth transitions with
/// publish-new-before-close-old semantics: the new instance is published to
/// [activeIsarProvider] FIRST (so every provider watching [isarProvider]
/// rebuilds onto it), and the replaced instance is closed after a grace
/// period, once its watchers have unsubscribed during those rebuilds.
///
/// All swaps are serialized on a single chain so a rapid
/// sign-out → sign-in can't interleave opens and closes.
class IsarSessionManager {
  IsarSessionManager(this._ref);

  final Ref _ref;

  /// Serializes swap/delete tasks (see class doc).
  Future<void> _chain = Future.value();

  /// Grace period before closing a replaced instance — long enough for the
  /// synchronous provider rebuilds (triggered by the publish) to have torn
  /// down their Isar watchers.
  static const _closeGrace = Duration(seconds: 2);

  /// Makes [uid]'s instance (or `anon` for null) the active one. No-op when
  /// it already is — e.g. the first auth emission after boot, where
  /// main.dart already opened the uid-correct instance.
  Future<void> switchToUid(String? uid) => _enqueue(() => _switchTo(uid));

  /// Account deletion: swaps to the anon instance, then closes the account's
  /// instance WITH `deleteFromDisk` — removing `u_<uid>.isar` entirely.
  Future<void> deleteAccountData(String uid) =>
      _enqueue(() => _deleteAccount(uid));

  Future<void> _enqueue(Future<void> Function() task) {
    final run = _chain.then((_) => task());
    // Keep the chain alive when a task fails; the failure still reaches the
    // caller of THIS task through `run`.
    _chain = run.then((_) {}, onError: (Object e, StackTrace st) {});
    return run;
  }

  Future<void> _switchTo(String? uid) async {
    final targetName = IsarService.instanceNameForUid(uid);
    final current = _ref.read(activeIsarProvider);
    if (current.isOpen && current.name == targetName) return;

    final next = await IsarService.openByName(targetName);
    // Publish FIRST — dependents rebuild onto the new instance before the
    // old one goes away.
    _ref.read(activeIsarProvider.notifier).state = next;
    _closeLater(current);
  }

  Future<void> _deleteAccount(String uid) async {
    final name = IsarService.instanceNameForUid(uid);
    final current = _ref.read(activeIsarProvider);
    if (current.isOpen && current.name == name) {
      final anon = await IsarService.openByName(IsarService.anonInstanceName);
      _ref.read(activeIsarProvider.notifier).state = anon; // publish FIRST
      // Short grace so rebuilds move off the doomed instance before the file
      // is destroyed (deletion is the point here, so no 2s deferral).
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await current.close(deleteFromDisk: true);
    } else {
      // Not the active instance (already swapped away) — open a handle just
      // to delete the file through Isar.
      final inst =
          Isar.getInstance(name) ?? await IsarService.openByName(name);
      await inst.close(deleteFromDisk: true);
    }
  }

  void _closeLater(Isar old) {
    unawaited(
      Future<void>.delayed(_closeGrace).then((_) async {
        if (old.isOpen) await old.close();
      }).catchError((Object e, StackTrace st) {
        AppLogger.error('IsarSessionManager: deferred close failed',
            error: e, stack: st);
      }),
    );
  }
}
