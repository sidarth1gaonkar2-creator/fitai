import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/field_manual.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/jump_wings.dart';
import '../domain/paywall_plans.dart';

/// Outcome of a single purchase attempt, as reported to the sheet.
enum PaywallPurchaseOutcome { success, cancelled, failed }

typedef LoadPlans = Future<List<PaywallPlan>> Function();
typedef PurchasePlan = Future<PaywallPurchaseOutcome> Function(PaywallPlan);

/// Restores purchases; returns true when the user ends up entitled.
typedef RestorePurchases = Future<bool> Function();

const _kTermsUrl = 'https://drillfit.com/terms.html';
const _kPrivacyUrl = 'https://drillfit.com/privacy.html';

/// Presents the Field Manual Airborne paywall. Returns true when the user
/// ends up entitled (purchased or restored), false otherwise. Dismissal is
/// explicit (the ✕) so a stray barrier tap can't kill the sheet mid-purchase.
Future<bool> showAirbornePaywallSheet(
  BuildContext context, {
  required LoadPlans loadPlans,
  required PurchasePlan purchase,
  required RestorePurchases restore,
}) async {
  final result = await showCupertinoModalPopup<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AirbornePaywallSheet(
      loadPlans: loadPlans,
      purchase: purchase,
      restore: restore,
    ),
  );
  return result ?? false;
}

/// The sheet body. Pure presentation: all store traffic comes in through the
/// three callbacks, which is what lets widget tests drive every state without
/// the platform channel.
class AirbornePaywallSheet extends StatefulWidget {
  const AirbornePaywallSheet({
    super.key,
    required this.loadPlans,
    required this.purchase,
    required this.restore,
  });

  final LoadPlans loadPlans;
  final PurchasePlan purchase;
  final RestorePurchases restore;

  @override
  State<AirbornePaywallSheet> createState() => _AirbornePaywallSheetState();
}

class _AirbornePaywallSheetState extends State<AirbornePaywallSheet> {
  List<PaywallPlan>? _plans;
  bool _loadFailed = false;
  int _selectedIndex = 0;
  bool _purchasing = false;
  bool _restoring = false;
  bool _success = false;
  Timer? _dismissTimer;

  bool get _busy => _purchasing || _restoring;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _plans = null;
      _loadFailed = false;
    });
    try {
      final plans = await widget.loadPlans();
      if (!mounted) return;
      setState(() => _plans = plans);
    } catch (e, st) {
      AppLogger.error('Airborne paywall failed to load plans',
          error: e, stack: st);
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _buy() async {
    final plans = _plans;
    if (plans == null || plans.isEmpty || _busy) return;
    final plan = plans[_selectedIndex];
    setState(() => _purchasing = true);
    final outcome = await widget.purchase(plan);
    if (!mounted) return;
    switch (outcome) {
      case PaywallPurchaseOutcome.success:
        HapticFeedback.mediumImpact();
        setState(() {
          _purchasing = false;
          _success = true;
        });
        _dismissTimer = Timer(const Duration(milliseconds: 2600), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      case PaywallPurchaseOutcome.cancelled:
      case PaywallPurchaseOutcome.failed:
        // Cancel is silent, failure was already toasted by the caller —
        // either way the sheet stays open and interactive.
        setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _restoring = true);
    final entitled = await widget.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (entitled) Navigator.of(context).pop(true);
  }

  Future<void> _openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      AppLogger.error('Paywall link failed to open: $url',
          error: e, stack: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: FieldManual.hairlineStrong)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
          child: _success
              ? _SuccessView(
                  key: const ValueKey('success'),
                  reduceMotion: reduceMotion,
                  onDone: () => Navigator.of(context).pop(true),
                )
              : _mainView(context),
        ),
      ),
    );
  }

  Widget _mainView(BuildContext context) {
    final plans = _plans;
    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close — explicit dismissal, disabled mid-purchase.
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Icon(
              CupertinoIcons.xmark,
              size: 20,
              color: FieldManual.mutedBone,
              semanticLabel: 'Close',
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                const Center(child: JumpWings(width: 84)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'VOLUNTEERS ONLY',
                    style: FieldManual.label(color: FieldManual.brass),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'GO AIRBORNE',
                    style: FieldManual.display(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      "The one thing in DrillFit you don't earn. "
                      'You volunteer.',
                      style: FieldManual.body(color: FieldManual.mutedBone),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // ── What Airborne issues ──
                if (plans == null)
                  _loadFailed ? _LoadFailure(onRetry: _load) : const _Skeleton()
                else ...[
                  const _IssueManifest(),
                  const SizedBox(height: 14),
                  const _SacredRankLine(),
                  const SizedBox(height: 18),
                  for (var i = 0; i < plans.length; i++) ...[
                    _PlanCard(
                      plan: plans[i],
                      selected: i == _selectedIndex,
                      enabled: !_busy,
                      onTap: () {
                        if (_selectedIndex == i) return;
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIndex = i);
                      },
                    ),
                    if (i < plans.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  _CtaButton(
                    busy: _purchasing,
                    enabled: !_busy,
                    onPressed: _buy,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _finePrintFor(plans[_selectedIndex]),
                    style: FieldManual.finePrint(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _LinksRow(
                    enabled: !_busy,
                    restoring: _restoring,
                    onRestore: _restore,
                    onTerms: () => _openLink(_kTermsUrl),
                    onPrivacy: () => _openLink(_kPrivacyUrl),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _finePrintFor(PaywallPlan plan) {
    final period = plan.period == PaywallPeriod.annual ? 'year' : 'month';
    final trial = plan.trialPhrase;
    final lead = trial == null
        ? '${plan.priceString}/$period.'
        : '${trial.toLowerCase()} free, then ${plan.priceString}/$period.';
    return '$lead Auto-renews until cancelled in your App Store settings.';
  }
}

// ─── What Airborne issues: one instrument panel, two readouts ────────────────

class _IssueManifest extends StatelessWidget {
  const _IssueManifest();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Column(
        children: [
          _readoutRow(
            label: 'COACH MESSAGES / DAY',
            value: Text.rich(
              TextSpan(
                style: FieldManual.readout(color: FieldManual.mutedBone),
                children: const [
                  TextSpan(text: '15'),
                  TextSpan(
                    text: '  →  ',
                    style: TextStyle(color: FieldManual.olive),
                  ),
                  TextSpan(
                    text: '100',
                    style: TextStyle(color: FieldManual.brass),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: FieldManual.hairline),
          _readoutRow(
            label: 'STANDARD THEMES',
            value: Text(
              'ALL ISSUED',
              style: FieldManual.readout(
                color: FieldManual.brass,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readoutRow({required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: FieldManual.label()),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}

// ─── The doctrine line ────────────────────────────────────────────────────────

class _SacredRankLine extends StatelessWidget {
  const _SacredRankLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _HairRule()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "YOUR RANK IS EARNED.\nAIRBORNE DOESN'T TOUCH IT.",
            style: FieldManual.label(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        const Expanded(child: _HairRule()),
      ],
    );
  }
}

class _HairRule extends StatelessWidget {
  const _HairRule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: FieldManual.hairline);
}

// ─── Plan cards ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PaywallPlan plan;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.periodLabel} plan, ${plan.priceString} '
          '${plan.period == PaywallPeriod.annual ? 'per year' : 'per month'}'
          '${plan.trialPhrase != null ? ', ${plan.trialPhrase!.toLowerCase()} free trial' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? FieldManual.fieldRaised : FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? FieldManual.brass : FieldManual.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.periodLabel, style: FieldManual.title()),
                        if (plan.savingsPercent != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: FieldManual.brass.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              'SAVE ${plan.savingsPercent}%',
                              style: FieldManual.label(
                                color: FieldManual.brass,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        style: FieldManual.finePrint(),
                        children: [
                          if (plan.trialPhrase != null) ...[
                            TextSpan(
                              text: '${plan.trialPhrase} FREE',
                              style:
                                  const TextStyle(color: FieldManual.brass),
                            ),
                            const TextSpan(
                              text: ' → ',
                              style: TextStyle(color: FieldManual.olive),
                            ),
                          ],
                          TextSpan(
                              text:
                                  '${plan.priceString} ${plan.periodSuffix}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? FieldManual.brass : null,
        border: selected
            ? null
            : Border.all(color: FieldManual.hairlineStrong, width: 1.5),
      ),
      child: selected
          ? const Icon(
              CupertinoIcons.checkmark,
              size: 12,
              color: FieldManual.ink,
            )
          : null,
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: FieldManual.brass,
      disabledColor: FieldManual.brassPressed,
      borderRadius: BorderRadius.circular(4),
      onPressed: enabled ? onPressed : null,
      child: busy
          ? const CupertinoActivityIndicator(color: FieldManual.ink)
          : Text(
              'GO AIRBORNE',
              style: FieldManual.title(color: FieldManual.ink),
            ),
    );
  }
}

// ─── Footer links ─────────────────────────────────────────────────────────────

class _LinksRow extends StatelessWidget {
  const _LinksRow({
    required this.enabled,
    required this.restoring,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
  });

  final bool enabled;
  final bool restoring;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _link(restoring ? 'RESTORING…' : 'RESTORE PURCHASES', onRestore),
        _dot(),
        _link('TERMS', onTerms),
        _dot(),
        _link('PRIVACY', onPrivacy),
      ],
    );
  }

  Widget _link(String text, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      onPressed: enabled ? onTap : null,
      child: Text(
        text,
        style: FieldManual.label(color: FieldManual.mutedBone, fontSize: 10),
      ),
    );
  }

  Widget _dot() => Text('·',
      style: FieldManual.label(color: FieldManual.olive, fontSize: 10));
}

// ─── Loading & failure ───────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(104),
        const SizedBox(height: 42),
        block(72),
        const SizedBox(height: 10),
        block(72),
        const SizedBox(height: 18),
        block(50),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          "Couldn't reach the App Store. Check your connection and try again.",
          style: FieldManual.body(color: FieldManual.mutedBone),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 28),
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(4),
          onPressed: onRetry,
          child: Text('RETRY', style: FieldManual.title()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Success ─────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.reduceMotion,
    required this.onDone,
  });

  final bool reduceMotion;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    const wings = JumpWings(width: 132, glow: true);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: reduceMotion
                ? wings
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuart,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: wings,
                  ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'WELCOME ABOARD',
              style: FieldManual.display(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Airborne is active. 100 coach messages a day. '
                'Every standard theme, issued.',
                style: FieldManual.body(color: FieldManual.mutedBone),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 26),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: FieldManual.brass,
            borderRadius: BorderRadius.circular(4),
            onPressed: onDone,
            child: Text(
              'CARRY ON',
              style: FieldManual.title(color: FieldManual.ink),
            ),
          ),
        ],
      ),
    );
  }
}
