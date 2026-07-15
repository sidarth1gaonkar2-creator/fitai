import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/entitlement_providers.dart';
import '../../../services/revenuecat_service.dart';
import '../domain/paywall_plans.dart';
import 'airborne_paywall_sheet.dart';

const _kUnavailableMessage =
    'Purchases are unavailable right now. Try again later.';
const _kFailedMessage = "That didn't go through. Please try again.";

/// Presents the Field Manual Airborne paywall (custom sheet over the current
/// RevenueCat Offering). Returns true when the user ends up entitled
/// (purchased or restored).
///
/// Error contract (mission §8): user cancellation is silent; every other
/// failure is AppLogger.error'd and surfaced as a friendly toast. In degraded
/// mode (no RC key) the tap explains itself instead of dead-ending.
Future<bool> presentAirbornePaywall(BuildContext context, WidgetRef ref) async {
  if (!RevenueCatService.instance.isConfigured) {
    showCupertinoToast(context, _kUnavailableMessage);
    return false;
  }
  final entitled = await showAirbornePaywallSheet(
    context,
    loadPlans: _loadPlans,
    purchase: (plan) => _purchasePlan(context, plan),
    restore: () => _restoreForSheet(context, ref),
  );
  if (entitled) {
    // The update listener also fires, but refresh explicitly so gating
    // flips before the user's next frame of interaction.
    await ref.read(airborneEntitlementProvider.notifier).refresh();
  }
  return entitled;
}

/// Restores previous purchases (Settings action, required by App Review).
/// Same error contract as [presentAirbornePaywall].
Future<void> restoreAirbornePurchases(
    BuildContext context, WidgetRef ref) async {
  if (!RevenueCatService.instance.isConfigured) {
    showCupertinoToast(context, _kUnavailableMessage);
    return;
  }
  try {
    final info = await Purchases.restorePurchases();
    await ref.read(airborneEntitlementProvider.notifier).refresh();
    if (!context.mounted) return;
    showCupertinoToast(
      context,
      airborneActiveFrom(info)
          ? 'Airborne restored — welcome back!'
          : 'No previous purchases found for this account.',
    );
  } on PlatformException catch (e, st) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.purchaseCancelledError) {
      return;
    }
    AppLogger.error('Restore purchases failed', error: e, stack: st);
    if (context.mounted) {
      showCupertinoToast(context, "Couldn't restore purchases. Please try again.");
    }
  } catch (e, st) {
    AppLogger.error('Restore purchases failed', error: e, stack: st);
    if (context.mounted) {
      showCupertinoToast(context, "Couldn't restore purchases. Please try again.");
    }
  }
}

/// Loads the current Offering and projects it into display plans. Throws on
/// any gap — the sheet renders its retry state and the error is logged there.
Future<List<PaywallPlan>> _loadPlans() async {
  final offerings = await Purchases.getOfferings();
  final current = offerings.current;
  if (current == null) {
    throw StateError('No current RevenueCat offering configured');
  }
  final plans = plansFromOffering(current);
  if (plans.isEmpty) {
    throw StateError(
        'Current offering has no monthly/annual package to display');
  }
  return plans;
}

/// One purchase attempt against the App Store. Success requires the Airborne
/// entitlement to actually be active afterwards — a purchase that completes
/// without the entitlement is a dashboard misconfiguration, not a win.
Future<PaywallPurchaseOutcome> _purchasePlan(
    BuildContext context, PaywallPlan plan) async {
  final package = plan.package;
  if (package == null) {
    AppLogger.error('Airborne plan is missing its RevenueCat package');
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return PaywallPurchaseOutcome.failed;
  }
  try {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    if (airborneActiveFrom(result.customerInfo)) {
      return PaywallPurchaseOutcome.success;
    }
    AppLogger.error(
        'Airborne purchase completed without an active entitlement');
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return PaywallPurchaseOutcome.failed;
  } on PlatformException catch (e, st) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.purchaseCancelledError) {
      return PaywallPurchaseOutcome.cancelled; // user backed out — not an error
    }
    AppLogger.error('Airborne purchase failed', error: e, stack: st);
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return PaywallPurchaseOutcome.failed;
  } catch (e, st) {
    AppLogger.error('Airborne purchase failed', error: e, stack: st);
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return PaywallPurchaseOutcome.failed;
  }
}

/// Restore reached from inside the sheet: runs the standard restore flow
/// (which handles its own logging and toasts), then reports whether the user
/// ended up entitled so the sheet can close on success.
Future<bool> _restoreForSheet(BuildContext context, WidgetRef ref) async {
  await restoreAirbornePurchases(context, ref);
  return ref.read(airborneActiveProvider);
}
