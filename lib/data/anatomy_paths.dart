import 'package:flutter/material.dart';

/// Anatomical body silhouettes and muscle group paths used by
/// [MuscleHighlightWidget]. All coordinates are expressed as fractions of
/// the widget bounds so the same paths scale across compact (120dp) and
/// full (280dp) renders.
///
/// The shapes are deliberately stylised — recognisable as the relevant
/// muscle group without trying to be a medical illustration. Every curve
/// uses `cubicTo` for smooth contours; the only `lineTo` calls are very
/// short connector segments where straight edges read better (the cleft
/// between the abdominal grid, the inner glute crease).
///
/// Paired muscles (biceps, lats, quads, …) are returned as a single Path
/// containing BOTH sides. That way the painter can fill the whole muscle
/// group with one call and the union shape carries any subtle inner detail
/// (e.g. the ab grid lines).
abstract final class AnatomyPaths {
  // ───────────────────────────────────────────────────────────────────
  //  Body silhouettes
  // ───────────────────────────────────────────────────────────────────

  /// 8-head-tall body outline, identical for front and back views.
  /// Built by walking down the left side and back up the right.
  static Path silhouette(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();

    // Head (oval, ~0.13 wide × 0.12 tall, centred at x=0.5)
    path.addOval(Rect.fromLTRB(
      0.43 * w,
      0.005 * h,
      0.57 * w,
      0.125 * h,
    ));

    // Walk the silhouette starting at the right side of the neck.
    path.moveTo(p(0.535, 0.125).dx, p(0.535, 0.125).dy);
    // Neck → right shoulder
    path.cubicTo(
      p(0.55, 0.14).dx, p(0.55, 0.14).dy,
      p(0.66, 0.145).dx, p(0.66, 0.145).dy,
      p(0.775, 0.16).dx, p(0.775, 0.16).dy,
    );
    // Down outer right arm to elbow
    path.cubicTo(
      p(0.81, 0.20).dx, p(0.81, 0.20).dy,
      p(0.83, 0.28).dx, p(0.83, 0.28).dy,
      p(0.83, 0.37).dx, p(0.83, 0.37).dy,
    );
    // Forearm to wrist
    path.cubicTo(
      p(0.85, 0.45).dx, p(0.85, 0.45).dy,
      p(0.87, 0.50).dx, p(0.87, 0.50).dy,
      p(0.88, 0.55).dx, p(0.88, 0.55).dy,
    );
    // Hand
    path.cubicTo(
      p(0.89, 0.57).dx, p(0.89, 0.57).dy,
      p(0.88, 0.59).dx, p(0.88, 0.59).dy,
      p(0.84, 0.58).dx, p(0.84, 0.58).dy,
    );
    // Inner forearm back up to underarm
    path.cubicTo(
      p(0.81, 0.50).dx, p(0.81, 0.50).dy,
      p(0.78, 0.42).dx, p(0.78, 0.42).dy,
      p(0.76, 0.34).dx, p(0.76, 0.34).dy,
    );
    // Down right side of torso (lat → waist → hip)
    path.cubicTo(
      p(0.74, 0.37).dx, p(0.74, 0.37).dy,
      p(0.68, 0.39).dx, p(0.68, 0.39).dy,
      p(0.675, 0.42).dx, p(0.675, 0.42).dy,
    );
    // Hip flare
    path.cubicTo(
      p(0.71, 0.44).dx, p(0.71, 0.44).dy,
      p(0.71, 0.46).dx, p(0.71, 0.46).dy,
      p(0.70, 0.48).dx, p(0.70, 0.48).dy,
    );
    // Outer right thigh
    path.cubicTo(
      p(0.70, 0.55).dx, p(0.70, 0.55).dy,
      p(0.68, 0.60).dx, p(0.68, 0.60).dy,
      p(0.66, 0.66).dx, p(0.66, 0.66).dy,
    );
    // Knee
    path.cubicTo(
      p(0.66, 0.70).dx, p(0.66, 0.70).dy,
      p(0.65, 0.72).dx, p(0.65, 0.72).dy,
      p(0.64, 0.74).dx, p(0.64, 0.74).dy,
    );
    // Calf belly
    path.cubicTo(
      p(0.66, 0.80).dx, p(0.66, 0.80).dy,
      p(0.65, 0.88).dx, p(0.65, 0.88).dy,
      p(0.62, 0.96).dx, p(0.62, 0.96).dy,
    );
    // Ankle / foot
    path.lineTo(p(0.55, 0.99).dx, p(0.55, 0.99).dy);
    // Up inner right leg
    path.cubicTo(
      p(0.54, 0.85).dx, p(0.54, 0.85).dy,
      p(0.53, 0.70).dx, p(0.53, 0.70).dy,
      p(0.53, 0.58).dx, p(0.53, 0.58).dy,
    );
    // Crotch
    path.cubicTo(
      p(0.52, 0.56).dx, p(0.52, 0.56).dy,
      p(0.50, 0.55).dx, p(0.50, 0.55).dy,
      p(0.50, 0.55).dx, p(0.50, 0.55).dy,
    );
    // Inner left leg down
    path.cubicTo(
      p(0.50, 0.55).dx, p(0.50, 0.55).dy,
      p(0.47, 0.70).dx, p(0.47, 0.70).dy,
      p(0.46, 0.85).dx, p(0.46, 0.85).dy,
    );
    path.lineTo(p(0.45, 0.99).dx, p(0.45, 0.99).dy);
    path.lineTo(p(0.38, 0.96).dx, p(0.38, 0.96).dy);
    // Outer left calf
    path.cubicTo(
      p(0.35, 0.88).dx, p(0.35, 0.88).dy,
      p(0.34, 0.80).dx, p(0.34, 0.80).dy,
      p(0.36, 0.74).dx, p(0.36, 0.74).dy,
    );
    path.cubicTo(
      p(0.35, 0.72).dx, p(0.35, 0.72).dy,
      p(0.34, 0.70).dx, p(0.34, 0.70).dy,
      p(0.34, 0.66).dx, p(0.34, 0.66).dy,
    );
    // Outer left thigh
    path.cubicTo(
      p(0.32, 0.60).dx, p(0.32, 0.60).dy,
      p(0.30, 0.55).dx, p(0.30, 0.55).dy,
      p(0.30, 0.48).dx, p(0.30, 0.48).dy,
    );
    path.cubicTo(
      p(0.29, 0.46).dx, p(0.29, 0.46).dy,
      p(0.29, 0.44).dx, p(0.29, 0.44).dy,
      p(0.325, 0.42).dx, p(0.325, 0.42).dy,
    );
    // Up left side of torso
    path.cubicTo(
      p(0.32, 0.39).dx, p(0.32, 0.39).dy,
      p(0.26, 0.37).dx, p(0.26, 0.37).dy,
      p(0.24, 0.34).dx, p(0.24, 0.34).dy,
    );
    // Inner upper-arm down to hand
    path.cubicTo(
      p(0.22, 0.42).dx, p(0.22, 0.42).dy,
      p(0.19, 0.50).dx, p(0.19, 0.50).dy,
      p(0.16, 0.58).dx, p(0.16, 0.58).dy,
    );
    path.cubicTo(
      p(0.12, 0.59).dx, p(0.12, 0.59).dy,
      p(0.11, 0.57).dx, p(0.11, 0.57).dy,
      p(0.12, 0.55).dx, p(0.12, 0.55).dy,
    );
    // Outer forearm back up to elbow
    path.cubicTo(
      p(0.13, 0.50).dx, p(0.13, 0.50).dy,
      p(0.15, 0.45).dx, p(0.15, 0.45).dy,
      p(0.17, 0.37).dx, p(0.17, 0.37).dy,
    );
    // Outer upper arm to shoulder
    path.cubicTo(
      p(0.17, 0.28).dx, p(0.17, 0.28).dy,
      p(0.19, 0.20).dx, p(0.19, 0.20).dy,
      p(0.225, 0.16).dx, p(0.225, 0.16).dy,
    );
    // Trapezius back to neck
    path.cubicTo(
      p(0.34, 0.145).dx, p(0.34, 0.145).dy,
      p(0.45, 0.14).dx, p(0.45, 0.14).dy,
      p(0.465, 0.125).dx, p(0.465, 0.125).dy,
    );
    path.close();
    return path;
  }

  // ───────────────────────────────────────────────────────────────────
  //  Front view muscles
  // ───────────────────────────────────────────────────────────────────

  /// Pectorals — two fan-shaped paths meeting at the sternum, splaying
  /// outward to the armpit. Combined as a single Path with both halves.
  static Path chest(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left pec
    path.moveTo(p(0.50, 0.175).dx, p(0.50, 0.175).dy);
    path.cubicTo(
      p(0.46, 0.175).dx, p(0.46, 0.175).dy,
      p(0.40, 0.16).dx, p(0.40, 0.16).dy,
      p(0.31, 0.175).dx, p(0.31, 0.175).dy,
    );
    path.cubicTo(
      p(0.28, 0.20).dx, p(0.28, 0.20).dy,
      p(0.30, 0.235).dx, p(0.30, 0.235).dy,
      p(0.34, 0.265).dx, p(0.34, 0.265).dy,
    );
    path.cubicTo(
      p(0.40, 0.275).dx, p(0.40, 0.275).dy,
      p(0.47, 0.265).dx, p(0.47, 0.265).dy,
      p(0.50, 0.255).dx, p(0.50, 0.255).dy,
    );
    path.close();
    // Right pec (mirror)
    path.moveTo(p(0.50, 0.175).dx, p(0.50, 0.175).dy);
    path.cubicTo(
      p(0.54, 0.175).dx, p(0.54, 0.175).dy,
      p(0.60, 0.16).dx, p(0.60, 0.16).dy,
      p(0.69, 0.175).dx, p(0.69, 0.175).dy,
    );
    path.cubicTo(
      p(0.72, 0.20).dx, p(0.72, 0.20).dy,
      p(0.70, 0.235).dx, p(0.70, 0.235).dy,
      p(0.66, 0.265).dx, p(0.66, 0.265).dy,
    );
    path.cubicTo(
      p(0.60, 0.275).dx, p(0.60, 0.275).dy,
      p(0.53, 0.265).dx, p(0.53, 0.265).dy,
      p(0.50, 0.255).dx, p(0.50, 0.255).dy,
    );
    path.close();
    return path;
  }

  /// Anterior deltoid caps — rounded shapes wrapping over the front of
  /// each shoulder. Both halves combined.
  static Path frontDeltoids(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left front delt
    path.moveTo(p(0.225, 0.16).dx, p(0.225, 0.16).dy);
    path.cubicTo(
      p(0.20, 0.18).dx, p(0.20, 0.18).dy,
      p(0.19, 0.22).dx, p(0.19, 0.22).dy,
      p(0.21, 0.255).dx, p(0.21, 0.255).dy,
    );
    path.cubicTo(
      p(0.25, 0.26).dx, p(0.25, 0.26).dy,
      p(0.29, 0.24).dx, p(0.29, 0.24).dy,
      p(0.30, 0.21).dx, p(0.30, 0.21).dy,
    );
    path.cubicTo(
      p(0.30, 0.185).dx, p(0.30, 0.185).dy,
      p(0.27, 0.16).dx, p(0.27, 0.16).dy,
      p(0.225, 0.16).dx, p(0.225, 0.16).dy,
    );
    path.close();
    // Right front delt
    path.moveTo(p(0.775, 0.16).dx, p(0.775, 0.16).dy);
    path.cubicTo(
      p(0.80, 0.18).dx, p(0.80, 0.18).dy,
      p(0.81, 0.22).dx, p(0.81, 0.22).dy,
      p(0.79, 0.255).dx, p(0.79, 0.255).dy,
    );
    path.cubicTo(
      p(0.75, 0.26).dx, p(0.75, 0.26).dy,
      p(0.71, 0.24).dx, p(0.71, 0.24).dy,
      p(0.70, 0.21).dx, p(0.70, 0.21).dy,
    );
    path.cubicTo(
      p(0.70, 0.185).dx, p(0.70, 0.185).dy,
      p(0.73, 0.16).dx, p(0.73, 0.16).dy,
      p(0.775, 0.16).dx, p(0.775, 0.16).dy,
    );
    path.close();
    return path;
  }

  /// Biceps — elongated, tapered shapes on the inner upper arm.
  static Path biceps(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left biceps
    path.moveTo(p(0.22, 0.23).dx, p(0.22, 0.23).dy);
    path.cubicTo(
      p(0.19, 0.27).dx, p(0.19, 0.27).dy,
      p(0.185, 0.32).dx, p(0.185, 0.32).dy,
      p(0.195, 0.36).dx, p(0.195, 0.36).dy,
    );
    path.cubicTo(
      p(0.22, 0.36).dx, p(0.22, 0.36).dy,
      p(0.25, 0.34).dx, p(0.25, 0.34).dy,
      p(0.26, 0.31).dx, p(0.26, 0.31).dy,
    );
    path.cubicTo(
      p(0.26, 0.27).dx, p(0.26, 0.27).dy,
      p(0.245, 0.24).dx, p(0.245, 0.24).dy,
      p(0.22, 0.23).dx, p(0.22, 0.23).dy,
    );
    path.close();
    // Right biceps (mirror)
    path.moveTo(p(0.78, 0.23).dx, p(0.78, 0.23).dy);
    path.cubicTo(
      p(0.81, 0.27).dx, p(0.81, 0.27).dy,
      p(0.815, 0.32).dx, p(0.815, 0.32).dy,
      p(0.805, 0.36).dx, p(0.805, 0.36).dy,
    );
    path.cubicTo(
      p(0.78, 0.36).dx, p(0.78, 0.36).dy,
      p(0.75, 0.34).dx, p(0.75, 0.34).dy,
      p(0.74, 0.31).dx, p(0.74, 0.31).dy,
    );
    path.cubicTo(
      p(0.74, 0.27).dx, p(0.74, 0.27).dy,
      p(0.755, 0.24).dx, p(0.755, 0.24).dy,
      p(0.78, 0.23).dx, p(0.78, 0.23).dy,
    );
    path.close();
    return path;
  }

  /// Forearms (front view) — tapered shapes from elbow to wrist.
  static Path forearmsFront(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left forearm
    path.moveTo(p(0.16, 0.38).dx, p(0.16, 0.38).dy);
    path.cubicTo(
      p(0.14, 0.43).dx, p(0.14, 0.43).dy,
      p(0.13, 0.48).dx, p(0.13, 0.48).dy,
      p(0.135, 0.54).dx, p(0.135, 0.54).dy,
    );
    path.cubicTo(
      p(0.16, 0.55).dx, p(0.16, 0.55).dy,
      p(0.20, 0.50).dx, p(0.20, 0.50).dy,
      p(0.21, 0.44).dx, p(0.21, 0.44).dy,
    );
    path.cubicTo(
      p(0.21, 0.41).dx, p(0.21, 0.41).dy,
      p(0.19, 0.39).dx, p(0.19, 0.39).dy,
      p(0.16, 0.38).dx, p(0.16, 0.38).dy,
    );
    path.close();
    // Right forearm
    path.moveTo(p(0.84, 0.38).dx, p(0.84, 0.38).dy);
    path.cubicTo(
      p(0.86, 0.43).dx, p(0.86, 0.43).dy,
      p(0.87, 0.48).dx, p(0.87, 0.48).dy,
      p(0.865, 0.54).dx, p(0.865, 0.54).dy,
    );
    path.cubicTo(
      p(0.84, 0.55).dx, p(0.84, 0.55).dy,
      p(0.80, 0.50).dx, p(0.80, 0.50).dy,
      p(0.79, 0.44).dx, p(0.79, 0.44).dy,
    );
    path.cubicTo(
      p(0.79, 0.41).dx, p(0.79, 0.41).dy,
      p(0.81, 0.39).dx, p(0.81, 0.39).dy,
      p(0.84, 0.38).dx, p(0.84, 0.38).dy,
    );
    path.close();
    return path;
  }

  /// Abdominals — rounded rectangle between chest and hips with subtle
  /// "6-pack" grid lines built in via subpath strokes.
  static Path abs(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    path.moveTo(p(0.43, 0.28).dx, p(0.43, 0.28).dy);
    path.cubicTo(
      p(0.42, 0.31).dx, p(0.42, 0.31).dy,
      p(0.42, 0.36).dx, p(0.42, 0.36).dy,
      p(0.43, 0.41).dx, p(0.43, 0.41).dy,
    );
    path.cubicTo(
      p(0.46, 0.43).dx, p(0.46, 0.43).dy,
      p(0.54, 0.43).dx, p(0.54, 0.43).dy,
      p(0.57, 0.41).dx, p(0.57, 0.41).dy,
    );
    path.cubicTo(
      p(0.58, 0.36).dx, p(0.58, 0.36).dy,
      p(0.58, 0.31).dx, p(0.58, 0.31).dy,
      p(0.57, 0.28).dx, p(0.57, 0.28).dy,
    );
    path.cubicTo(
      p(0.53, 0.275).dx, p(0.53, 0.275).dy,
      p(0.47, 0.275).dx, p(0.47, 0.275).dy,
      p(0.43, 0.28).dx, p(0.43, 0.28).dy,
    );
    path.close();
    return path;
  }

  /// Obliques — diagonal strips on each side of the abs.
  static Path obliques(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left oblique
    path.moveTo(p(0.36, 0.30).dx, p(0.36, 0.30).dy);
    path.cubicTo(
      p(0.34, 0.34).dx, p(0.34, 0.34).dy,
      p(0.34, 0.39).dx, p(0.34, 0.39).dy,
      p(0.37, 0.42).dx, p(0.37, 0.42).dy,
    );
    path.cubicTo(
      p(0.40, 0.43).dx, p(0.40, 0.43).dy,
      p(0.42, 0.42).dx, p(0.42, 0.42).dy,
      p(0.42, 0.40).dx, p(0.42, 0.40).dy,
    );
    path.cubicTo(
      p(0.41, 0.36).dx, p(0.41, 0.36).dy,
      p(0.40, 0.32).dx, p(0.40, 0.32).dy,
      p(0.36, 0.30).dx, p(0.36, 0.30).dy,
    );
    path.close();
    // Right oblique
    path.moveTo(p(0.64, 0.30).dx, p(0.64, 0.30).dy);
    path.cubicTo(
      p(0.66, 0.34).dx, p(0.66, 0.34).dy,
      p(0.66, 0.39).dx, p(0.66, 0.39).dy,
      p(0.63, 0.42).dx, p(0.63, 0.42).dy,
    );
    path.cubicTo(
      p(0.60, 0.43).dx, p(0.60, 0.43).dy,
      p(0.58, 0.42).dx, p(0.58, 0.42).dy,
      p(0.58, 0.40).dx, p(0.58, 0.40).dy,
    );
    path.cubicTo(
      p(0.59, 0.36).dx, p(0.59, 0.36).dy,
      p(0.60, 0.32).dx, p(0.60, 0.32).dy,
      p(0.64, 0.30).dx, p(0.64, 0.30).dy,
    );
    path.close();
    return path;
  }

  /// Hip flexors — small V-shape between abs and quads.
  static Path hipFlexors(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    path.moveTo(p(0.42, 0.43).dx, p(0.42, 0.43).dy);
    path.cubicTo(
      p(0.43, 0.46).dx, p(0.43, 0.46).dy,
      p(0.46, 0.48).dx, p(0.46, 0.48).dy,
      p(0.50, 0.49).dx, p(0.50, 0.49).dy,
    );
    path.cubicTo(
      p(0.54, 0.48).dx, p(0.54, 0.48).dy,
      p(0.57, 0.46).dx, p(0.57, 0.46).dy,
      p(0.58, 0.43).dx, p(0.58, 0.43).dy,
    );
    path.cubicTo(
      p(0.55, 0.43).dx, p(0.55, 0.43).dy,
      p(0.45, 0.43).dx, p(0.45, 0.43).dy,
      p(0.42, 0.43).dx, p(0.42, 0.43).dy,
    );
    path.close();
    return path;
  }

  /// Quadriceps — teardrop shapes on each thigh, wider at hip, narrowing
  /// just above the knee.
  static Path quadriceps(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left quad
    path.moveTo(p(0.34, 0.47).dx, p(0.34, 0.47).dy);
    path.cubicTo(
      p(0.31, 0.55).dx, p(0.31, 0.55).dy,
      p(0.32, 0.62).dx, p(0.32, 0.62).dy,
      p(0.36, 0.66).dx, p(0.36, 0.66).dy,
    );
    path.cubicTo(
      p(0.42, 0.67).dx, p(0.42, 0.67).dy,
      p(0.47, 0.66).dx, p(0.47, 0.66).dy,
      p(0.48, 0.62).dx, p(0.48, 0.62).dy,
    );
    path.cubicTo(
      p(0.48, 0.55).dx, p(0.48, 0.55).dy,
      p(0.46, 0.49).dx, p(0.46, 0.49).dy,
      p(0.42, 0.47).dx, p(0.42, 0.47).dy,
    );
    path.cubicTo(
      p(0.39, 0.46).dx, p(0.39, 0.46).dy,
      p(0.36, 0.46).dx, p(0.36, 0.46).dy,
      p(0.34, 0.47).dx, p(0.34, 0.47).dy,
    );
    path.close();
    // Right quad
    path.moveTo(p(0.66, 0.47).dx, p(0.66, 0.47).dy);
    path.cubicTo(
      p(0.69, 0.55).dx, p(0.69, 0.55).dy,
      p(0.68, 0.62).dx, p(0.68, 0.62).dy,
      p(0.64, 0.66).dx, p(0.64, 0.66).dy,
    );
    path.cubicTo(
      p(0.58, 0.67).dx, p(0.58, 0.67).dy,
      p(0.53, 0.66).dx, p(0.53, 0.66).dy,
      p(0.52, 0.62).dx, p(0.52, 0.62).dy,
    );
    path.cubicTo(
      p(0.52, 0.55).dx, p(0.52, 0.55).dy,
      p(0.54, 0.49).dx, p(0.54, 0.49).dy,
      p(0.58, 0.47).dx, p(0.58, 0.47).dy,
    );
    path.cubicTo(
      p(0.61, 0.46).dx, p(0.61, 0.46).dy,
      p(0.64, 0.46).dx, p(0.64, 0.46).dy,
      p(0.66, 0.47).dx, p(0.66, 0.47).dy,
    );
    path.close();
    return path;
  }

  /// Tibialis (front shin) — slim vertical strip on each lower leg.
  static Path tibialis(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left
    path.moveTo(p(0.41, 0.76).dx, p(0.41, 0.76).dy);
    path.cubicTo(
      p(0.40, 0.82).dx, p(0.40, 0.82).dy,
      p(0.41, 0.88).dx, p(0.41, 0.88).dy,
      p(0.43, 0.92).dx, p(0.43, 0.92).dy,
    );
    path.cubicTo(
      p(0.45, 0.88).dx, p(0.45, 0.88).dy,
      p(0.45, 0.82).dx, p(0.45, 0.82).dy,
      p(0.44, 0.76).dx, p(0.44, 0.76).dy,
    );
    path.close();
    // Right
    path.moveTo(p(0.59, 0.76).dx, p(0.59, 0.76).dy);
    path.cubicTo(
      p(0.60, 0.82).dx, p(0.60, 0.82).dy,
      p(0.59, 0.88).dx, p(0.59, 0.88).dy,
      p(0.57, 0.92).dx, p(0.57, 0.92).dy,
    );
    path.cubicTo(
      p(0.55, 0.88).dx, p(0.55, 0.88).dy,
      p(0.55, 0.82).dx, p(0.55, 0.82).dy,
      p(0.56, 0.76).dx, p(0.56, 0.76).dy,
    );
    path.close();
    return path;
  }

  // ───────────────────────────────────────────────────────────────────
  //  Back view muscles
  // ───────────────────────────────────────────────────────────────────

  /// Trapezius — diamond/kite shape from base of skull to mid-back.
  static Path trapezius(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    path.moveTo(p(0.50, 0.13).dx, p(0.50, 0.13).dy);
    path.cubicTo(
      p(0.37, 0.15).dx, p(0.37, 0.15).dy,
      p(0.30, 0.20).dx, p(0.30, 0.20).dy,
      p(0.36, 0.24).dx, p(0.36, 0.24).dy,
    );
    path.cubicTo(
      p(0.42, 0.26).dx, p(0.42, 0.26).dy,
      p(0.48, 0.27).dx, p(0.48, 0.27).dy,
      p(0.50, 0.28).dx, p(0.50, 0.28).dy,
    );
    path.cubicTo(
      p(0.52, 0.27).dx, p(0.52, 0.27).dy,
      p(0.58, 0.26).dx, p(0.58, 0.26).dy,
      p(0.64, 0.24).dx, p(0.64, 0.24).dy,
    );
    path.cubicTo(
      p(0.70, 0.20).dx, p(0.70, 0.20).dy,
      p(0.63, 0.15).dx, p(0.63, 0.15).dy,
      p(0.50, 0.13).dx, p(0.50, 0.13).dy,
    );
    path.close();
    return path;
  }

  /// Latissimus dorsi — wing/V shape from mid-back fanning out to armpits.
  static Path lats(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    path.moveTo(p(0.50, 0.27).dx, p(0.50, 0.27).dy);
    // Left wing
    path.cubicTo(
      p(0.42, 0.27).dx, p(0.42, 0.27).dy,
      p(0.30, 0.30).dx, p(0.30, 0.30).dy,
      p(0.28, 0.36).dx, p(0.28, 0.36).dy,
    );
    path.cubicTo(
      p(0.30, 0.39).dx, p(0.30, 0.39).dy,
      p(0.40, 0.41).dx, p(0.40, 0.41).dy,
      p(0.48, 0.40).dx, p(0.48, 0.40).dy,
    );
    path.cubicTo(
      p(0.49, 0.36).dx, p(0.49, 0.36).dy,
      p(0.50, 0.32).dx, p(0.50, 0.32).dy,
      p(0.50, 0.27).dx, p(0.50, 0.27).dy,
    );
    path.close();
    // Right wing
    path.moveTo(p(0.50, 0.27).dx, p(0.50, 0.27).dy);
    path.cubicTo(
      p(0.58, 0.27).dx, p(0.58, 0.27).dy,
      p(0.70, 0.30).dx, p(0.70, 0.30).dy,
      p(0.72, 0.36).dx, p(0.72, 0.36).dy,
    );
    path.cubicTo(
      p(0.70, 0.39).dx, p(0.70, 0.39).dy,
      p(0.60, 0.41).dx, p(0.60, 0.41).dy,
      p(0.52, 0.40).dx, p(0.52, 0.40).dy,
    );
    path.cubicTo(
      p(0.51, 0.36).dx, p(0.51, 0.36).dy,
      p(0.50, 0.32).dx, p(0.50, 0.32).dy,
      p(0.50, 0.27).dx, p(0.50, 0.27).dy,
    );
    path.close();
    return path;
  }

  /// Rear deltoids — posterior cap on each shoulder.
  static Path rearDeltoids(Size size) {
    // Same geometry as front deltoids — the cap visible from behind sits
    // in the same spot. Reusing keeps everything aligned.
    return frontDeltoids(size);
  }

  /// Triceps — horseshoe shapes on back of upper arm, slightly thicker
  /// than biceps.
  static Path triceps(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left triceps — horseshoe (open at bottom)
    path.moveTo(p(0.20, 0.22).dx, p(0.20, 0.22).dy);
    path.cubicTo(
      p(0.165, 0.27).dx, p(0.165, 0.27).dy,
      p(0.16, 0.33).dx, p(0.16, 0.33).dy,
      p(0.18, 0.37).dx, p(0.18, 0.37).dy,
    );
    path.cubicTo(
      p(0.21, 0.37).dx, p(0.21, 0.37).dy,
      p(0.24, 0.35).dx, p(0.24, 0.35).dy,
      p(0.255, 0.33).dx, p(0.255, 0.33).dy,
    );
    path.cubicTo(
      p(0.27, 0.29).dx, p(0.27, 0.29).dy,
      p(0.26, 0.24).dx, p(0.26, 0.24).dy,
      p(0.23, 0.22).dx, p(0.23, 0.22).dy,
    );
    path.close();
    // Right triceps
    path.moveTo(p(0.80, 0.22).dx, p(0.80, 0.22).dy);
    path.cubicTo(
      p(0.835, 0.27).dx, p(0.835, 0.27).dy,
      p(0.84, 0.33).dx, p(0.84, 0.33).dy,
      p(0.82, 0.37).dx, p(0.82, 0.37).dy,
    );
    path.cubicTo(
      p(0.79, 0.37).dx, p(0.79, 0.37).dy,
      p(0.76, 0.35).dx, p(0.76, 0.35).dy,
      p(0.745, 0.33).dx, p(0.745, 0.33).dy,
    );
    path.cubicTo(
      p(0.73, 0.29).dx, p(0.73, 0.29).dy,
      p(0.74, 0.24).dx, p(0.74, 0.24).dy,
      p(0.77, 0.22).dx, p(0.77, 0.22).dy,
    );
    path.close();
    return path;
  }

  /// Erector spinae (lower back) — two parallel vertical strips along
  /// the spine.
  static Path lowerBack(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left strip
    path.moveTo(p(0.46, 0.34).dx, p(0.46, 0.34).dy);
    path.cubicTo(
      p(0.45, 0.38).dx, p(0.45, 0.38).dy,
      p(0.45, 0.42).dx, p(0.45, 0.42).dy,
      p(0.47, 0.45).dx, p(0.47, 0.45).dy,
    );
    path.cubicTo(
      p(0.49, 0.43).dx, p(0.49, 0.43).dy,
      p(0.49, 0.38).dx, p(0.49, 0.38).dy,
      p(0.49, 0.34).dx, p(0.49, 0.34).dy,
    );
    path.close();
    // Right strip
    path.moveTo(p(0.54, 0.34).dx, p(0.54, 0.34).dy);
    path.cubicTo(
      p(0.55, 0.38).dx, p(0.55, 0.38).dy,
      p(0.55, 0.42).dx, p(0.55, 0.42).dy,
      p(0.53, 0.45).dx, p(0.53, 0.45).dy,
    );
    path.cubicTo(
      p(0.51, 0.43).dx, p(0.51, 0.43).dy,
      p(0.51, 0.38).dx, p(0.51, 0.38).dy,
      p(0.51, 0.34).dx, p(0.51, 0.34).dy,
    );
    path.close();
    return path;
  }

  /// Glutes — two large rounded shapes at the hip line.
  static Path glutes(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left glute
    path.moveTo(p(0.50, 0.44).dx, p(0.50, 0.44).dy);
    path.cubicTo(
      p(0.41, 0.44).dx, p(0.41, 0.44).dy,
      p(0.31, 0.46).dx, p(0.31, 0.46).dy,
      p(0.31, 0.50).dx, p(0.31, 0.50).dy,
    );
    path.cubicTo(
      p(0.33, 0.535).dx, p(0.33, 0.535).dy,
      p(0.42, 0.55).dx, p(0.42, 0.55).dy,
      p(0.49, 0.535).dx, p(0.49, 0.535).dy,
    );
    path.cubicTo(
      p(0.50, 0.51).dx, p(0.50, 0.51).dy,
      p(0.50, 0.47).dx, p(0.50, 0.47).dy,
      p(0.50, 0.44).dx, p(0.50, 0.44).dy,
    );
    path.close();
    // Right glute
    path.moveTo(p(0.50, 0.44).dx, p(0.50, 0.44).dy);
    path.cubicTo(
      p(0.59, 0.44).dx, p(0.59, 0.44).dy,
      p(0.69, 0.46).dx, p(0.69, 0.46).dy,
      p(0.69, 0.50).dx, p(0.69, 0.50).dy,
    );
    path.cubicTo(
      p(0.67, 0.535).dx, p(0.67, 0.535).dy,
      p(0.58, 0.55).dx, p(0.58, 0.55).dy,
      p(0.51, 0.535).dx, p(0.51, 0.535).dy,
    );
    path.cubicTo(
      p(0.50, 0.51).dx, p(0.50, 0.51).dy,
      p(0.50, 0.47).dx, p(0.50, 0.47).dy,
      p(0.50, 0.44).dx, p(0.50, 0.44).dy,
    );
    path.close();
    return path;
  }

  /// Hamstrings — elongated shapes on back of each thigh.
  static Path hamstrings(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left ham
    path.moveTo(p(0.34, 0.55).dx, p(0.34, 0.55).dy);
    path.cubicTo(
      p(0.33, 0.60).dx, p(0.33, 0.60).dy,
      p(0.34, 0.65).dx, p(0.34, 0.65).dy,
      p(0.37, 0.68).dx, p(0.37, 0.68).dy,
    );
    path.cubicTo(
      p(0.43, 0.68).dx, p(0.43, 0.68).dy,
      p(0.47, 0.65).dx, p(0.47, 0.65).dy,
      p(0.48, 0.60).dx, p(0.48, 0.60).dy,
    );
    path.cubicTo(
      p(0.48, 0.56).dx, p(0.48, 0.56).dy,
      p(0.45, 0.54).dx, p(0.45, 0.54).dy,
      p(0.40, 0.54).dx, p(0.40, 0.54).dy,
    );
    path.cubicTo(
      p(0.37, 0.54).dx, p(0.37, 0.54).dy,
      p(0.35, 0.54).dx, p(0.35, 0.54).dy,
      p(0.34, 0.55).dx, p(0.34, 0.55).dy,
    );
    path.close();
    // Right ham
    path.moveTo(p(0.66, 0.55).dx, p(0.66, 0.55).dy);
    path.cubicTo(
      p(0.67, 0.60).dx, p(0.67, 0.60).dy,
      p(0.66, 0.65).dx, p(0.66, 0.65).dy,
      p(0.63, 0.68).dx, p(0.63, 0.68).dy,
    );
    path.cubicTo(
      p(0.57, 0.68).dx, p(0.57, 0.68).dy,
      p(0.53, 0.65).dx, p(0.53, 0.65).dy,
      p(0.52, 0.60).dx, p(0.52, 0.60).dy,
    );
    path.cubicTo(
      p(0.52, 0.56).dx, p(0.52, 0.56).dy,
      p(0.55, 0.54).dx, p(0.55, 0.54).dy,
      p(0.60, 0.54).dx, p(0.60, 0.54).dy,
    );
    path.cubicTo(
      p(0.63, 0.54).dx, p(0.63, 0.54).dy,
      p(0.65, 0.54).dx, p(0.65, 0.54).dy,
      p(0.66, 0.55).dx, p(0.66, 0.55).dy,
    );
    path.close();
    return path;
  }

  /// Calves (gastrocnemius) — diamond/heart shape on back of each lower
  /// leg.
  static Path calves(Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = Path();
    // Left calf
    path.moveTo(p(0.40, 0.74).dx, p(0.40, 0.74).dy);
    path.cubicTo(
      p(0.36, 0.78).dx, p(0.36, 0.78).dy,
      p(0.36, 0.82).dx, p(0.36, 0.82).dy,
      p(0.39, 0.86).dx, p(0.39, 0.86).dy,
    );
    path.cubicTo(
      p(0.42, 0.86).dx, p(0.42, 0.86).dy,
      p(0.44, 0.83).dx, p(0.44, 0.83).dy,
      p(0.45, 0.80).dx, p(0.45, 0.80).dy,
    );
    path.cubicTo(
      p(0.45, 0.77).dx, p(0.45, 0.77).dy,
      p(0.43, 0.74).dx, p(0.43, 0.74).dy,
      p(0.40, 0.74).dx, p(0.40, 0.74).dy,
    );
    path.close();
    // Right calf
    path.moveTo(p(0.60, 0.74).dx, p(0.60, 0.74).dy);
    path.cubicTo(
      p(0.64, 0.78).dx, p(0.64, 0.78).dy,
      p(0.64, 0.82).dx, p(0.64, 0.82).dy,
      p(0.61, 0.86).dx, p(0.61, 0.86).dy,
    );
    path.cubicTo(
      p(0.58, 0.86).dx, p(0.58, 0.86).dy,
      p(0.56, 0.83).dx, p(0.56, 0.83).dy,
      p(0.55, 0.80).dx, p(0.55, 0.80).dy,
    );
    path.cubicTo(
      p(0.55, 0.77).dx, p(0.55, 0.77).dy,
      p(0.57, 0.74).dx, p(0.57, 0.74).dy,
      p(0.60, 0.74).dx, p(0.60, 0.74).dy,
    );
    path.close();
    return path;
  }

  /// Forearms on back view — same geometry as front since both heads of
  /// the forearm are visible in profile silhouette.
  static Path forearmsBack(Size size) => forearmsFront(size);

  // ───────────────────────────────────────────────────────────────────
  //  Lookups keyed by the normalised muscle name (matches MuscleMap keys)
  // ───────────────────────────────────────────────────────────────────

  static Path? frontPathFor(String muscle, Size size) {
    switch (muscle) {
      case 'chest':
      case 'pectorals':
        return chest(size);
      case 'deltoids':
        return frontDeltoids(size);
      case 'biceps':
        return biceps(size);
      case 'forearms':
        return forearmsFront(size);
      case 'abs':
      case 'abdominals':
        return abs(size);
      case 'obliques':
        return obliques(size);
      case 'hip flexors':
        return hipFlexors(size);
      case 'quadriceps':
      case 'quads':
        return quadriceps(size);
      case 'tibialis':
        return tibialis(size);
    }
    return null;
  }

  static Path? backPathFor(String muscle, Size size) {
    switch (muscle) {
      case 'traps':
      case 'trapezius':
        return trapezius(size);
      case 'lats':
      case 'latissimus dorsi':
        return lats(size);
      case 'rear deltoids':
        return rearDeltoids(size);
      case 'triceps':
        return triceps(size);
      case 'lower back':
      case 'erector spinae':
        return lowerBack(size);
      case 'glutes':
      case 'gluteus maximus':
        return glutes(size);
      case 'hamstrings':
        return hamstrings(size);
      case 'calves':
      case 'gastrocnemius':
        return calves(size);
      case 'forearms':
        return forearmsBack(size);
    }
    return null;
  }
}
