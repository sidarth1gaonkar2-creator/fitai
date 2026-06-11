import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../core/utils/logger.dart';
import '../features/onboarding/data/remote_profile_repository.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';
import 'isar_provider.dart';
import 'unit_system_provider.dart';
import 'user_profile_provider.dart';

/// SharedPreferences key recording which uid the on-device [UserProfile]
/// belongs to. The local profile collection isn't uid-scoped yet, so this is
/// how the gate avoids treating a previous user's profile as the current user's
/// (and avoids backfilling it up to the wrong Firestore doc) on a shared device.
const localProfileOwnerKey = 'localProfileOwnerUid';

/// Where a signed-in user should land.
enum OnboardingGate { ready, needsOnboarding }

/// THE single source of truth for the onboarding-vs-app routing decision,
/// shared by every sign-in provider (Google, email/password, future ones).
///
/// Resolution order:
///   1. Firestore private profile doc (`users/{uid}/private/profile`) — the
///      cross-device source of truth.
///   2. Local Isar [UserProfile] — a cache used to (a) tolerate an offline /
///      flaky fetch for a user we already know, and (b) one-time backfill of
///      pre-update users who completed onboarding before this doc existed. Only
///      trusted when it can be attributed to the current uid (see
///      [localProfileOwnerKey]).
///
/// A fetch ERROR with no trusted local cache surfaces as an AsyncError (router
/// → retry screen) — NEVER as "needs onboarding". An existing user on a flaky
/// connection must not be dumped into onboarding, where re-completing it could
/// overwrite their profile.
final onboardingGateProvider = FutureProvider<OnboardingGate>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  // Unauthenticated: the router resolves /welcome before ever reading this.
  if (uid == null) return OnboardingGate.needsOnboarding;

  final repo = ref.watch(remoteProfileRepositoryProvider);
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final localProfile =
      await isar.userProfiles.where().anyId().build().findFirst();

  // Can the on-device profile be trusted as THIS account's?
  final localOwner = prefs.getString(localProfileOwnerKey);
  bool localBelongsToUser;
  if (localProfile == null) {
    localBelongsToUser = false;
  } else if (localOwner == uid) {
    localBelongsToUser = true;
  } else if (localOwner == null) {
    // Pre-update profile with no recorded owner. Assume it belongs to the
    // signed-in user (the single-device case backfill targets) and claim it.
    // On a shared device where a different user signs in FIRST after the update
    // this would mis-assign — the real fix is uid-scoping UserProfile (tracked
    // in the cross-account audit).
    localBelongsToUser = true;
    await prefs.setString(localProfileOwnerKey, uid);
  } else {
    // Owner recorded as a different uid → not ours.
    localBelongsToUser = false;
  }

  try {
    final remote = await repo.fetch(uid);

    if (remote != null) {
      // Firestore says onboarded. Make the local cache reflect THIS user:
      // hydrate on a fresh device, or replace a different user's stale profile
      // left on a shared device, so the dashboard shows the right goals/TDEE.
      if (!localBelongsToUser) {
        try {
          await _writeLocalProfile(isar, localProfile?.id, remote);
          await prefs.setString(localProfileOwnerKey, uid);
          ref.invalidate(userProfileProvider);
        } catch (e, st) {
          AppLogger.error('Onboarding gate: local hydration failed',
              error: e, stack: st);
        }
      }
      return OnboardingGate.ready;
    }

    // No complete remote profile. Backfill ONLY from a profile we can attribute
    // to this user (a pre-update existing user on their own device) — never
    // from another account's leftover profile.
    if (localBelongsToUser) {
      try {
        await repo.save(uid, RemoteProfile.fromLocal(localProfile!));
      } catch (e, st) {
        AppLogger.error(
            'Onboarding gate: backfill write failed (retries next launch)',
            error: e,
            stack: st);
      }
      return OnboardingGate.ready;
    }

    // Genuinely new account (or an untrusted local profile we won't touch).
    return OnboardingGate.needsOnboarding;
  } catch (e, st) {
    AppLogger.error('Onboarding gate: remote profile fetch failed',
        error: e, stack: st);
    // Never push a possibly-existing user into onboarding on a transient error.
    // Trust the local cache only if it's attributable to this user; otherwise
    // surface the error so the router shows a retry screen.
    if (localBelongsToUser) return OnboardingGate.ready;
    rethrow;
  }
});

/// Overwrites the single on-device profile row with [remote] (reusing
/// [existingId] when present so we replace rather than duplicate).
Future<void> _writeLocalProfile(
    Isar isar, int? existingId, RemoteProfile remote) async {
  final profile = remote.toUserProfile();
  if (existingId != null) profile.id = existingId;
  await isar.writeTxn(() => isar.userProfiles.put(profile));
}
