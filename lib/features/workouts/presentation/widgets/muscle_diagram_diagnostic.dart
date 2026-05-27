import 'package:flutter/material.dart' show Brightness;

import '../../../../models/enums.dart';
import 'muscle_highlight_widget.dart';

/// One row in the diagnostic report — represents an exercise that was
/// fed into the muscle-aggregation pipeline. Callers pre-resolve
/// `lookupExercise` and pass the result here so the helper stays
/// data-source agnostic (the workout detail screen uses name-based
/// lookup, template preview uses id-based).
class MuscleDiagramDiagnosticEntry {
  const MuscleDiagramDiagnosticEntry({
    required this.id,
    this.name,
    this.primary = const [],
    this.secondary = const [],
  });

  final String id;
  final String? name;
  final List<MuscleGroup> primary;
  final List<MuscleGroup> secondary;
}

/// Builds the multi-line text report shown inside the diagnostic
/// CupertinoAlertDialog. Output is plain text — readable on a phone
/// screen without scrolling sideways — and includes:
///   • Per-exercise resolution status (`HIT` / `NOT FOUND`)
///   • Aggregated primary + secondary MuscleGroup enums
///   • The final `List<String>` values passed to the widget
///   • Each string's resolved front/back PNG stem + full asset path
///   • Per-side BASE image + OVERLAY masks summary
///
/// Use the output verbatim — the comparison between a template's
/// report and a working custom-workout's report is what surfaces the
/// bug. The dialog reports both light- and dark-mode paths so the
/// reader can spot a theme-specific issue without re-running the app.
String buildMuscleDiagramDiagnostic({
  required String contextLabel,
  String? extraIdLine,
  required List<MuscleDiagramDiagnosticEntry> entries,
  required Set<MuscleGroup> computedPrimary,
  required Set<MuscleGroup> computedSecondary,
  required String Function(MuscleGroup) muscleStringFn,
}) {
  final buf = StringBuffer();
  buf.writeln('=== $contextLabel ===');
  if (extraIdLine != null) buf.writeln(extraIdLine);
  buf.writeln('Exercises: ${entries.length}');
  buf.writeln('');
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    buf.writeln('${i + 1}. ${e.name ?? "(NOT FOUND)"}');
    buf.writeln('   id: ${e.id}');
    buf.writeln(
        '   primary:   ${e.primary.isEmpty ? "(empty)" : e.primary.join(", ")}');
    buf.writeln(
        '   secondary: ${e.secondary.isEmpty ? "(empty)" : e.secondary.join(", ")}');
  }
  buf.writeln('');
  buf.writeln('--- AGGREGATED ---');
  buf.writeln(
      'primary enums:   ${computedPrimary.isEmpty ? "(empty)" : computedPrimary.join(", ")}');
  buf.writeln(
      'secondary enums: ${computedSecondary.isEmpty ? "(empty)" : computedSecondary.join(", ")}');
  buf.writeln('');

  final primaryStrs = computedPrimary
      .map(muscleStringFn)
      .where((s) => s.isNotEmpty)
      .toList();
  final secondaryStrs = computedSecondary
      .map(muscleStringFn)
      .where((s) => s.isNotEmpty)
      .toList();
  buf.writeln('--- PASSED TO WIDGET ---');
  buf.writeln(
      'targetMuscles:    ${primaryStrs.isEmpty ? "(empty)" : primaryStrs.join(", ")}');
  buf.writeln(
      'secondaryMuscles: ${secondaryStrs.isEmpty ? "(empty)" : secondaryStrs.join(", ")}');
  buf.writeln('');

  // Resolve the two panels in BOTH themes so the report shows exactly
  // which asset paths the renderer will load. Dark first (the app
  // default), light second.
  for (final brightness in [Brightness.dark, Brightness.light]) {
    final tag = brightness == Brightness.dark ? 'DARK' : 'LIGHT';
    final frontRes = MuscleHighlightWidget.resolvePanel(
      side: MuscleSide.front,
      targetMuscles: primaryStrs,
      secondaryMuscles: secondaryStrs,
      brightness: brightness,
    );
    final backRes = MuscleHighlightWidget.resolvePanel(
      side: MuscleSide.back,
      targetMuscles: primaryStrs,
      secondaryMuscles: secondaryStrs,
      brightness: brightness,
    );
    buf.writeln('--- $tag THEME — per-muscle paths ---');
    for (final s in primaryStrs) {
      _writeMusclePaths(buf, s, 'target', brightness, frontRes, backRes);
    }
    for (final s in secondaryStrs) {
      _writeMusclePaths(buf, s, 'second', brightness, frontRes, backRes);
    }
    buf.writeln('');
    buf.writeln('--- $tag THEME — panel summary ---');
    _writePanelSummary(buf, 'FRONT', frontRes);
    _writePanelSummary(buf, 'BACK', backRes);
    buf.writeln('');
  }
  return buf.toString();
}

/// Per-muscle line: lookup key, side hits, BASE-vs-OVERLAY role, and
/// the full asset paths the renderer will actually load.
void _writeMusclePaths(
  StringBuffer buf,
  String muscle,
  String role,
  Brightness brightness,
  PanelResolution frontRes,
  PanelResolution backRes,
) {
  final fSheet = MuscleHighlightWidget.frontSheetFor(muscle);
  final bSheet = MuscleHighlightWidget.backSheetFor(muscle);
  if (fSheet == null && bSheet == null) {
    buf.writeln('$role  "$muscle" → UNMAPPED');
    return;
  }
  buf.writeln('$role  "$muscle"');
  if (fSheet != null) {
    final basePath = '${MuscleHighlightWidget.originalDir(brightness)}/$fSheet.png';
    final maskPath = '${MuscleHighlightWidget.maskDir(brightness)}/$fSheet.png';
    final assignedRole = _roleInPanel(muscle, fSheet, frontRes);
    buf.writeln('    front sheet: $fSheet   role: $assignedRole');
    buf.writeln('      base path: $basePath');
    buf.writeln('      mask path: $maskPath');
  }
  if (bSheet != null) {
    final basePath = '${MuscleHighlightWidget.originalDir(brightness)}/$bSheet.png';
    final maskPath = '${MuscleHighlightWidget.maskDir(brightness)}/$bSheet.png';
    final assignedRole = _roleInPanel(muscle, bSheet, backRes);
    buf.writeln('    back  sheet: $bSheet   role: $assignedRole');
    buf.writeln('      base path: $basePath');
    buf.writeln('      mask path: $maskPath');
  }
}

/// Tells whether a muscle/sheet pair landed in the BASE slot or one of
/// the overlay-mask slots for a given panel.
String _roleInPanel(String muscle, String sheet, PanelResolution res) {
  if (res.isEmpty) return 'side-empty (not rendered)';
  if (res.baseSheet == sheet) {
    if (res.baseFromMuscle == muscle) return 'BASE (first primary on this side)';
    return 'BASE (sheet shared with another muscle)';
  }
  if (res.primaryMaskSheets.contains(sheet)) {
    return 'OVERLAY (primary, full opacity)';
  }
  if (res.secondaryMaskSheets.contains(sheet)) {
    return 'OVERLAY (secondary, 50% opacity)';
  }
  return 'NOT IN THIS PANEL';
}

void _writePanelSummary(StringBuffer buf, String label, PanelResolution res) {
  if (res.isEmpty) {
    buf.writeln('$label: side-empty (no muscles hit, panel not rendered)');
    return;
  }
  buf.writeln(
      '$label BASE IMAGE: ${res.baseImagePath}   from muscle: "${res.baseFromMuscle ?? "(fallback)"}"');
  buf.writeln('$label OVERLAY MASKS (Image.asset count = ${res.imageCount}):');
  if (res.secondaryMaskPaths.isEmpty && res.primaryMaskPaths.isEmpty) {
    buf.writeln('  (none — base layer alone)');
    return;
  }
  for (var i = 0; i < res.secondaryMaskPaths.length; i++) {
    final muscle = res.secondaryMaskFromMuscles[i];
    buf.writeln(
        '  [secondary @50%] ${res.secondaryMaskPaths[i]}'
        '${muscle.isEmpty ? "" : "   from \"$muscle\""}');
  }
  for (var i = 0; i < res.primaryMaskPaths.length; i++) {
    final muscle = res.primaryMaskFromMuscles[i];
    buf.writeln(
        '  [primary  @100%] ${res.primaryMaskPaths[i]}'
        '${muscle.isEmpty ? "" : "   from \"$muscle\""}');
  }
}
