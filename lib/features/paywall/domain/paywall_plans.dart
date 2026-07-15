import 'package:purchases_flutter/purchases_flutter.dart';

/// Billing period of a displayable Airborne plan.
enum PaywallPeriod { monthly, annual }

/// A plan the paywall can render: the display-ready projection of a
/// RevenueCat [Package]. Keeping the UI on this model (instead of raw SDK
/// types) lets widget tests build plans without the platform channel.
class PaywallPlan {
  const PaywallPlan({
    required this.period,
    required this.priceString,
    this.trialDays,
    this.savingsPercent,
    this.package,
  });

  final PaywallPeriod period;

  /// Localized per-period price from StoreKit, e.g. `$59.99`.
  final String priceString;

  /// Length of the free introductory offer in days; null when none.
  final int? trialDays;

  /// Whole-percent saving of annual vs 12 × monthly; null when not computable.
  /// Only ever set on the annual plan.
  final int? savingsPercent;

  /// The underlying RevenueCat package. Null only in tests/previews.
  final Package? package;

  String get periodLabel =>
      period == PaywallPeriod.annual ? 'ANNUAL' : 'MONTHLY';

  String get periodSuffix =>
      period == PaywallPeriod.annual ? '/ YEAR' : '/ MONTH';

  /// Human trial phrase for card chips and fine print, e.g. `7 DAYS`.
  String? get trialPhrase {
    final days = trialDays;
    if (days == null) return null;
    return days == 1 ? '1 DAY' : '$days DAYS';
  }
}

/// Maps the current RevenueCat offering to display plans, annual first.
/// Packages without a monthly/annual type are ignored — the paywall sells
/// exactly the two periods the brief defines.
List<PaywallPlan> plansFromOffering(Offering offering) {
  Package? monthly;
  Package? annual;
  for (final p in offering.availablePackages) {
    if (p.packageType == PackageType.monthly) monthly ??= p;
    if (p.packageType == PackageType.annual) annual ??= p;
  }

  int? savings;
  if (monthly != null && annual != null) {
    final yearAtMonthly = monthly.storeProduct.price * 12;
    if (yearAtMonthly > 0 && annual.storeProduct.price < yearAtMonthly) {
      savings =
          ((1 - annual.storeProduct.price / yearAtMonthly) * 100).round();
      if (savings <= 0) savings = null;
    }
  }

  return [
    if (annual != null)
      PaywallPlan(
        period: PaywallPeriod.annual,
        priceString: annual.storeProduct.priceString,
        trialDays: _freeTrialDays(annual.storeProduct.introductoryPrice),
        savingsPercent: savings,
        package: annual,
      ),
    if (monthly != null)
      PaywallPlan(
        period: PaywallPeriod.monthly,
        priceString: monthly.storeProduct.priceString,
        trialDays: _freeTrialDays(monthly.storeProduct.introductoryPrice),
        package: monthly,
      ),
  ];
}

/// Total free-trial length in days, or null when the intro offer is missing
/// or paid (an intro *price* is not a trial and must not be sold as one).
int? _freeTrialDays(IntroductoryPrice? intro) {
  if (intro == null || intro.price != 0) return null;
  final unitDays = switch (intro.periodUnit) {
    PeriodUnit.day => 1,
    PeriodUnit.week => 7,
    PeriodUnit.month => 30,
    PeriodUnit.year => 365,
    PeriodUnit.unknown => 0,
  };
  final cycles = intro.cycles < 1 ? 1 : intro.cycles;
  final days = intro.periodNumberOfUnits * unitDays * cycles;
  return days > 0 ? days : null;
}
