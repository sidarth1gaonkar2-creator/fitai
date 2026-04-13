import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/enums.dart';

/// Anatomical body diagram that highlights primary/secondary muscle groups
/// on a realistic SVG silhouette. Supports a front/back toggle and an
/// animated glow pulse on highlighted muscles.
class MuscleGroupDiagram extends StatefulWidget {
  const MuscleGroupDiagram({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.height = 360,
  });

  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final double height;

  @override
  State<MuscleGroupDiagram> createState() => _MuscleGroupDiagramState();
}

class _MuscleGroupDiagramState extends State<MuscleGroupDiagram>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFFFF4444);
  static const _secondaryColor = Color(0xFF7B5CF6);
  static const _inactiveFill = '#2E2E2E';
  static const _background = Color(0xFF1A1A1A);

  late final AnimationController _controller;
  late final Animation<double> _glow;

  String? _frontSvg;
  String? _backSvg;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadSvgs();
  }

  Future<void> _loadSvgs() async {
    final front = await rootBundle.loadString('assets/images/body_front.svg');
    final back = await rootBundle.loadString('assets/images/body_back.svg');
    if (mounted) {
      setState(() {
        _frontSvg = front;
        _backSvg = back;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Maps a MuscleGroup to the list of SVG path ids it affects on each side.
  List<String> _idsFor(MuscleGroup m, {required bool front}) {
    if (front) {
      return switch (m) {
        MuscleGroup.chest => ['chest'],
        MuscleGroup.shoulders => ['front_deltoid'],
        MuscleGroup.biceps => ['biceps'],
        MuscleGroup.forearms => ['forearms_front'],
        MuscleGroup.abs => ['abs'],
        MuscleGroup.obliques => ['obliques'],
        MuscleGroup.quads => ['quads', 'hip_flexors'],
        MuscleGroup.calves => ['tibialis'],
        _ => const [],
      };
    }
    return switch (m) {
      MuscleGroup.upperBack => ['traps', 'lower_back'],
      MuscleGroup.lats => ['lats'],
      MuscleGroup.shoulders => ['rear_deltoid'],
      MuscleGroup.triceps => ['triceps'],
      MuscleGroup.forearms => ['forearms_back'],
      MuscleGroup.glutes => ['glutes'],
      MuscleGroup.hamstrings => ['hamstrings'],
      MuscleGroup.calves => ['calves'],
      _ => const [],
    };
  }

  String _colorToHex(Color c) {
    final r = (c.r * 255).round() & 0xff;
    final g = (c.g * 255).round() & 0xff;
    final b = (c.b * 255).round() & 0xff;
    String two(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${two(r)}${two(g)}${two(b)}';
  }

  /// Recolour the raw SVG string based on highlighted muscles.
  /// For each highlighted id we rewrite the first `fill="#2E2E2E"` that
  /// appears inside that `id="..."` element to the target colour.
  String _applyHighlights(String raw, {required bool front}) {
    var svg = raw;

    // Build id → color map (primary wins over secondary)
    final idColors = <String, Color>{};
    for (final m in widget.secondaryMuscles) {
      for (final id in _idsFor(m, front: front)) {
        idColors[id] = _secondaryColor;
      }
    }
    for (final m in widget.primaryMuscles) {
      for (final id in _idsFor(m, front: front)) {
        idColors[id] = _primaryColor;
      }
    }

    idColors.forEach((id, color) {
      final hex = _colorToHex(color);
      // Replace the fill attribute on the path element with matching id.
      // Our hand-authored SVGs always place fill immediately after the path's d attribute.
      final pattern = RegExp(
        'id="$id"([^>]*?)fill="$_inactiveFill"',
        dotAll: true,
      );
      svg = svg.replaceFirstMapped(
        pattern,
        (m) => 'id="$id"${m.group(1)}fill="$hex"',
      );
    });
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    final hasLoaded = _frontSvg != null && _backSvg != null;
    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height,
            child: !hasLoaded
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AnimatedBuilder(
                    animation: _glow,
                    builder: (context, _) {
                      final raw = _showFront ? _frontSvg! : _backSvg!;
                      final svg = _applyHighlights(raw, front: _showFront);
                      final glowOpacity = 0.7 + 0.3 * _glow.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Blurred glow layer beneath
                          if (widget.primaryMuscles.isNotEmpty ||
                              widget.secondaryMuscles.isNotEmpty)
                            Opacity(
                              opacity: glowOpacity,
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 6,
                                  sigmaY: 6,
                                ),
                                child: SvgPicture.string(
                                  svg,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          // Crisp SVG on top with animated opacity on highlights
                          Opacity(
                            opacity: glowOpacity,
                            child: SvgPicture.string(
                              svg,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          _FrontBackToggle(
            showFront: _showFront,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _showFront = v);
            },
          ),
          if (widget.primaryMuscles.isNotEmpty ||
              widget.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Legend(
              primary: widget.primaryMuscles,
              secondary: widget.secondaryMuscles,
            ),
          ],
        ],
      ),
    );
  }
}

class _FrontBackToggle extends StatelessWidget {
  const _FrontBackToggle({
    required this.showFront,
    required this.onChanged,
  });

  final bool showFront;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleButton(
          label: 'Front',
          active: showFront,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 10),
        _ToggleButton(
          label: 'Back',
          active: !showFront,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC6FF3D);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? lime : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.primary, required this.secondary});

  final List<MuscleGroup> primary;
  final List<MuscleGroup> secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (primary.isNotEmpty) ...[
          _dot(const Color(0xFFFF4444)),
          const SizedBox(width: 4),
          const Text(
            'Primary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
        if (primary.isNotEmpty && secondary.isNotEmpty)
          const SizedBox(width: 16),
        if (secondary.isNotEmpty) ...[
          _dot(const Color(0xFF7B5CF6)),
          const SizedBox(width: 4),
          const Text(
            'Secondary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
