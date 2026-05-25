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
///   • Each string's resolved front/back PNG stem (or "UNMAPPED")
///
/// Use the output verbatim — the comparison between a template's
/// report and a working custom-workout's report is what surfaces the
/// bug.
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
    buf.writeln('   primary:   ${e.primary.isEmpty ? "(empty)" : e.primary.join(", ")}');
    buf.writeln('   secondary: ${e.secondary.isEmpty ? "(empty)" : e.secondary.join(", ")}');
  }
  buf.writeln('');
  buf.writeln('--- AGGREGATED ---');
  buf.writeln('primary enums:   ${computedPrimary.isEmpty ? "(empty)" : computedPrimary.join(", ")}');
  buf.writeln('secondary enums: ${computedSecondary.isEmpty ? "(empty)" : computedSecondary.join(", ")}');
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
  buf.writeln('targetMuscles:    ${primaryStrs.isEmpty ? "(empty)" : primaryStrs.join(", ")}');
  buf.writeln('secondaryMuscles: ${secondaryStrs.isEmpty ? "(empty)" : secondaryStrs.join(", ")}');
  buf.writeln('');

  buf.writeln('--- PNG RESOLUTION ---');
  for (final s in primaryStrs) {
    final f = MuscleHighlightWidget.frontSheetFor(s);
    final b = MuscleHighlightWidget.backSheetFor(s);
    if (f == null && b == null) {
      buf.writeln('target  "$s" → UNMAPPED');
    } else {
      buf.writeln('target  "$s" → front:${f ?? "—"}  back:${b ?? "—"}');
    }
  }
  for (final s in secondaryStrs) {
    final f = MuscleHighlightWidget.frontSheetFor(s);
    final b = MuscleHighlightWidget.backSheetFor(s);
    if (f == null && b == null) {
      buf.writeln('second  "$s" → UNMAPPED');
    } else {
      buf.writeln('second  "$s" → front:${f ?? "—"}  back:${b ?? "—"}');
    }
  }
  return buf.toString();
}
