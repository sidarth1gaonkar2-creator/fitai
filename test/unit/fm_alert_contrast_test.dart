// The default Field Manual theme's alert/error tone must hold WCAG AA for
// body text on every FM surface.
//
// It didn't. The original brick #C24A38 read 3.54 / 3.24 / 2.85:1 on
// ink/field/field-raised — surfaced by the Woodland audit, where routing
// around it was the only option. Worse, the default theme carried TWO alert
// reds: FieldManual.alert (brick) and Palette.destructive (iOS red #FF453A,
// via the fallback, since the FM registry entry sets no darkAlert), so which
// red a screen showed depended on which token it happened to read — and the
// iOS red failed too (4.06:1 on field-raised).
//
// Both now resolve to one AA-safe tone. This test pins that, and pins the
// consequence: the tone is light enough that anything sitting ON an alert
// fill must be ink, not bone.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/app_colors.dart';
import 'package:fitai/core/theme/field_manual.dart';
import 'package:fitai/core/theme/fm_skin.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The three Field Manual surfaces alert text can land on.
const _fmSurfaces = <String, Color>{
  'ink': Color(0xFF1A1C1A),
  'field': Color(0xFF21241F),
  'fieldRaised': Color(0xFF2A2E26),
};

void main() {
  group('Field Manual alert tone', () {
    test('holds WCAG AA for body text on every FM surface', () {
      const skin = FmSkin.fieldManual();
      final alert = skin.alert;
      _fmSurfaces.forEach((name, surface) {
        final r = _contrast(alert, surface);
        // ignore: avoid_print
        print('alert ${_hex(alert)} on $name ${_hex(surface)}: '
            '${r.toStringAsFixed(2)}:1');
        expect(r, greaterThanOrEqualTo(4.5),
            reason: 'FM alert fails AA for body text on $name');
      });
    });

    test('the default theme resolves ONE alert red, not two', () {
      // FieldManual.alert (skin) and Palette.destructive (palette) are read by
      // different screens; if they diverge the same error shows two colours.
      final palette =
          AppColors.resolve(theme: defaultTheme, brightness: Brightness.dark);
      const skin = FmSkin.fieldManual();
      expect(palette.destructive, skin.alert,
          reason: 'FieldManual.alert and Palette.destructive disagree on the '
              'default theme');
    });

    test('the accent-swap packs inherit the same AA-safe alert', () {
      // They ride FM chrome and set no darkAlert, so they shared the failing
      // red and must share the fix.
      for (final theme in themeRegistry) {
        if (theme.darkAlert != null) continue; // full skins route their own
        final palette =
            AppColors.resolve(theme: theme, brightness: Brightness.dark);
        for (final surface in _fmSurfaces.values) {
          expect(_contrast(palette.destructive, surface),
              greaterThanOrEqualTo(4.5),
              reason: '${theme.id} alert fails AA on ${_hex(surface)}');
        }
      }
    });

    test('a glyph on an alert FILL must be ink, not bone', () {
      const skin = FmSkin.fieldManual();
      final alert = skin.alert;
      // Opaque fill.
      expect(_contrast(FieldManual.ink, alert), greaterThanOrEqualTo(4.5));
      expect(_contrast(FieldManual.bone, alert), lessThan(3.0),
          reason: 'bone on alert would pass — the ink rule may be stale');
      // The 0.9-alpha swipe-background idiom, composited over field.
      final swipe = Color.alphaBlend(
        alert.withValues(alpha: 0.9),
        _fmSurfaces['field']!,
      );
      expect(_contrast(FieldManual.ink, swipe), greaterThanOrEqualTo(3.0),
          reason: 'ink glyph on the swipe-delete fill fails the graphic bar');
    });

    test('the other full skins keep their own alert routing', () {
      // Night Ops routes off red to amber (its accent IS red); Woodland and
      // Dress Blues carry their own lifted tones. None may be dragged onto
      // the FM default by this change.
      const expected = {
        'night_ops': Color(0xFFFFB000),
        'woodland': Color(0xFFF8B0A0),
        'dress_blues': Color(0xFFF0857A),
      };
      expected.forEach((id, tone) {
        expect(themeById(id).darkAlert, tone,
            reason: '$id alert handling changed');
      });
    });
  });
}
