import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Welcome to FitAI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine animation direction for child steps
    final goingForward = previousStep == null || step > previousStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to FitAI'),
        leading: step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref
                    .read(onboardingControllerProvider.notifier)
                    .previousStep(),
              )
            : null,
      ),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: step / AppConstants.onboardingStepCount,
              end: (step + 1) / AppConstants.onboardingStepCount,
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value),
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
  late final Animation<Offset> _slideAnimation;

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
