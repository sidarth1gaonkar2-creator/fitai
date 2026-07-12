import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/utils/logger.dart';
import '../services/revenuecat_service.dart';
import 'auth_provider.dart';

/// Whether [info] carries an active Airborne entitlement.
bool airborneActiveFrom(CustomerInfo info) =>
    info.entitlements.active.containsKey(kAirborneEntitlementId);

/// Live Airborne entitlement state, sourced from RevenueCat's [CustomerInfo]:
/// seeded by a fetch on creation and kept current by the SDK's customer-info
/// update listener (which fires after purchases, restores, and logIn/logOut).
final airborneEntitlementProvider =
    StateNotifierProvider<AirborneEntitlementNotifier, bool>((ref) {
  // Rebuild on account transitions so the state is re-fetched for the active
  // uid (the session coordinator has just logIn/logOut'd RevenueCat).
  ref.watch(currentUserIdProvider);
  return AirborneEntitlementNotifier(
    configured: RevenueCatService.instance.isConfigured,
  );
});

/// Public read surface: true while the current user has Airborne. Watch this
/// for gating (themes, AI Coach upsell) — false in degraded mode, when signed
/// out, or whenever the entitlement can't be confirmed.
final airborneActiveProvider =
    Provider<bool>((ref) => ref.watch(airborneEntitlementProvider));

/// Holds the Airborne bool and tracks RevenueCat's customer-info updates.
///
/// The SDK hooks are injectable so unit tests can drive the notifier with a
/// mocked [CustomerInfo] and never touch the platform channel; production
/// callers use the defaults. When [configured] is false (degraded mode /
/// non-iOS host) the notifier is inert: state stays false and no SDK call is
/// ever made.
class AirborneEntitlementNotifier extends StateNotifier<bool> {
  AirborneEntitlementNotifier({
    required bool configured,
    Future<CustomerInfo> Function() getCustomerInfo =
        Purchases.getCustomerInfo,
    void Function(CustomerInfoUpdateListener) addListener =
        Purchases.addCustomerInfoUpdateListener,
    void Function(CustomerInfoUpdateListener) removeListener =
        Purchases.removeCustomerInfoUpdateListener,
  })  : _configured = configured,
        _getCustomerInfo = getCustomerInfo,
        _removeListener = removeListener,
        super(false) {
    if (!_configured) return;
    _listener = _onCustomerInfo;
    addListener(_listener!);
    refresh();
  }

  final bool _configured;
  final Future<CustomerInfo> Function() _getCustomerInfo;
  final void Function(CustomerInfoUpdateListener) _removeListener;
  CustomerInfoUpdateListener? _listener;

  void _onCustomerInfo(CustomerInfo info) {
    if (mounted) state = airborneActiveFrom(info);
  }

  /// Re-reads CustomerInfo and updates the state. Runs on creation (and thus
  /// on every uid switch via the provider rebuild) and after purchase/restore
  /// flows as a belt-and-braces alongside the update listener. On failure the
  /// previous state is kept — a transient fetch error must not yank a paid
  /// unlock out from under the user mid-session.
  Future<void> refresh() async {
    if (!_configured) return;
    try {
      final info = await _getCustomerInfo();
      if (mounted) state = airborneActiveFrom(info);
    } catch (e, st) {
      AppLogger.error('Airborne entitlement refresh failed',
          error: e, stack: st);
    }
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      try {
        _removeListener(listener);
      } catch (e, st) {
        AppLogger.error('Airborne listener removal failed',
            error: e, stack: st);
      }
    }
    super.dispose();
  }
}
