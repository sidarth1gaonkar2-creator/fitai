import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'onboarding_controller.dart';
import 'widgets/activity_step.dart';
import 'widgets/body_info_step.dart';
import 'widgets/goal_step.dart';
import 'widgets/measurements_step.dart';
import 'widgets/name_step.dart';
import 'widgets/summary_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await ref.read(onboardingControllerProvider.notifier).loadProgress();
    final step = ref.read(onboardingControllerProvider).currentStep;
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (step > 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(step);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final step = state.currentStep;
    final previousStep = state.previousStep;

    ref.listen<int>(
      onboardingControllerProvider.select((s) => s.currentStep),
      (previous, next) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    final palette = AppColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: CupertinoNavigationBar(
          backgroundColor: palette.background.withValues(alpha: 0.8),
          border: null,
          middle: Text(
            'Welcome to DrillFit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ),
        body: Center(
          child: CupertinoActivityIndicator(color: palette.accent),
        ),
      );
    }

    final goingForward = previousStep == null || step > previousStep;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        middle: Text(
          'Welcome to DrillFit',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        leading: step > 0
            ? CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => ref
                    .read(onboardingControllerProvider.notifier)
                    .previousStep(),
                child: Icon(
                  CupertinoIcons.back,
                  color: palette.text,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _DotProgressIndicator(
            totalSteps: AppConstants.onboardingStepCount,
            currentStep: step,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AnimatedStep(goingForward: goingForward, child: const NameStep()),
                _AnimatedStep(goingForward: goingForward, child: const BodyInfoStep()),
                _AnimatedStep(goingForward: goingForward, child: const MeasurementsStep()),
                _AnimatedStep(goingForward: goingForward, child: const GoalStep()),
                _AnimatedStep(goingForward: goingForward, child: const ActivityStep()),
                _AnimatedStep(goingForward: goingForward, child: const SummaryStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotProgressIndicator extends StatelessWidget {
  const _DotProgressIndicator({
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      color: palette.surface,
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? palette.accent
                    : palette.text.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedStep extends StatefulWidget {
  const _AnimatedStep({
    required this.goingForward,
    required this.child,
  });

  final bool goingForward;
  final Widget child;

  @override
  State<_AnimatedStep> createState() => _AnimatedStepState();
}

class _AnimatedStepState extends State<_AnimatedStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _updateSlideAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goingForward != widget.goingForward) {
      _updateSlideAnimation();
      _controller.forward(from: 0);
    }
  }

  void _updateSlideAnimation() {
    final beginOffset = widget.goingForward
        ? const Offset(0.08, 0)
        : const Offset(-0.08, 0);
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
