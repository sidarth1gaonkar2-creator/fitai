import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../theme/app_colors.dart';

/// Shared Cupertino-styled helpers used throughout the app.
/// These replace Material chrome widgets (Card, ExpansionTile, SnackBar, etc.)
/// that have no direct Cupertino equivalent.

// ---------------------------------------------------------------------------
// Dark iOS-style card
// ---------------------------------------------------------------------------

class CupertinoCard extends StatelessWidget {
  const CupertinoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    // Field Manual cards are 8px; sheets are the 12px surface (DESIGN.md).
    this.borderRadius = 8,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Linear progress bar (Cupertino has no built-in equivalent)
// ---------------------------------------------------------------------------

class CupertinoProgressBar extends StatelessWidget {
  const CupertinoProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.backgroundColor,
    this.borderRadius = 3,
  });

  final double value; // 0..1
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            color: backgroundColor ?? palette.surfaceElevated,
          ),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              color: color ?? palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expand / collapse tile
// ---------------------------------------------------------------------------

class CupertinoExpansionTile extends StatefulWidget {
  const CupertinoExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.initiallyExpanded = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<CupertinoExpansionTile> createState() => _CupertinoExpansionTileState();
}

class _CupertinoExpansionTileState extends State<CupertinoExpansionTile>
    with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.of(context).text,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            child: widget.title,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.of(context).textSecondary,
                                fontSize: 12,
                              ),
                              child: widget.subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// iOS-style toast overlay
// ---------------------------------------------------------------------------

void showCupertinoToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastWidget(
      message: message,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// iOS-style toast with an inline "Undo" action button. Stays visible for
/// [duration] (default 5 seconds) or until the user taps Undo.
void showCupertinoUndoToast(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
  String actionLabel = 'Undo',
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  bool undone = false;
  entry = OverlayEntry(
    builder: (ctx) => _ToastWidget(
      message: message,
      duration: duration,
      onDismiss: () {
        try {
          entry.remove();
        } catch (_) {/* already removed */}
      },
      actionLabel: actionLabel,
      onAction: () {
        if (undone) return;
        undone = true;
        onUndo();
        try {
          entry.remove();
        } catch (_) {/* already removed */}
      },
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  // Duration is resolved against Reduce Motion in didChangeDependencies —
  // context isn't safe to read here.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.duration = Duration.zero;
      _controller.value = 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Positioned(
      left: 20,
      right: 20,
      bottom: padding.bottom + 24,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
          child: Center(
            child: Builder(builder: (context) {
              final palette = AppColors.of(context);
              // Field Manual chrome: raised field surface, hairline border,
              // no shadow (the Quiet Chrome rule).
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: palette.text,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onAction,
                        // ≥44pt tap target for the action label.
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Text(
                                widget.actionLabel!,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience buttons
// ---------------------------------------------------------------------------

/// Readable label color for text sitting ON an accent fill: ink for bright
/// accents (brass and most packs), bone for the dark ones (e.g. Stealth).
/// Mirrors [Palette.onAccent] — keep the two in lockstep.
Color _onAccent(Color accent) =>
    accent.computeLuminance() >= 0.18
        ? const Color(0xFF1A1C1A) // ink
        : const Color(0xFFE8E4D8); // bone

/// Filled primary CTA — Field Manual issue: accent fill, ink label,
/// condensed uppercase, sharp 4px corners (DESIGN.md §Buttons).
class CupertinoPrimaryButton extends StatelessWidget {
  const CupertinoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.of(context).accent;
    final onAccent = _onAccent(accent);
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: onAccent, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Oswald',
            fontVariations: const [FontVariation('wght', 600)],
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.6,
            color: onAccent,
          ),
        ),
      ],
    );
    // Spoken label stays sentence case; the uppercase is visual only.
    return Semantics(
      label: label,
      button: true,
      child: ExcludeSemantics(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          color: accent,
          borderRadius: BorderRadius.circular(4),
          onPressed: onPressed,
          child: content,
        ),
      ),
    );
  }
}

/// Outlined secondary button — transparent with hairline border, sharp 4px
/// (DESIGN.md §Buttons).
class CupertinoSecondaryButton extends StatelessWidget {
  const CupertinoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Semantics(
      label: label,
      button: true,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: palette.text),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.6,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

