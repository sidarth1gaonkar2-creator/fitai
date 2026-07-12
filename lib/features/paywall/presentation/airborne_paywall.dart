import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../providers/entitlement_providers.dart';
import '../../../services/revenuecat_service.dart';

const _kUnavailableMessage =
    'Purchases are unavailable right now. Try again later.';
const _kFailedMessage = "That didn't go through. Please try again.";

/// Presents the RevenueCat remote paywall (current Offering) for Airborne.
/// Returns true when the user ends up entitled (purchased or restored).
///
/// Error contract (mission §8): user cancellation is silent; every other
/// failure is AppLogger.error'd and surfaced as a friendly toast. In degraded
/// mode (no RC key) the tap explains itself instead of dead-ending.
Future<bool> presentAirbornePaywall(BuildContext context, WidgetRef ref) async {
  if (!RevenueCatService.instance.isConfigured) {
    showCupertinoToast(context, _kUnavailableMessage);
    return false;
  }
  try {
    final result = await RevenueCatUI.presentPaywall(displayCloseButton: true);
    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        // The update listener also fires, but refresh explicitly so gating
        // flips before the user's next frame of interaction.
        await ref.read(airborneEntitlementProvider.notifier).refresh();
        if (context.mounted) {
          showCupertinoToast(context, 'Welcome aboard — Airborne is active!');
        }
        return true;
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        return false;
      case PaywallResult.error:
        AppLogger.error('Airborne paywall reported an error result');
        if (context.mounted) showCupertinoToast(context, _kFailedMessage);
        return false;
    }
  } on PlatformException catch (e, st) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.purchaseCancelledError) {
      return false; // user backed out — not an error
    }
    AppLogger.error('Airborne paywall failed', error: e, stack: st);
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return false;
  } catch (e, st) {
    AppLogger.error('Airborne paywall failed', error: e, stack: st);
    if (context.mounted) showCupertinoToast(context, _kFailedMessage);
    return false;
  }
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
