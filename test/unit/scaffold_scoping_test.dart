// Guards the app-wide texture hoist: the new Palette.scaffold token must be
// byte-identical to background for every theme WITHOUT a surface texture, and
// transparent only for the texture skins. This is the whole basis of the
// "other 8 themes are unaffected" claim, so it is asserted, not eyeballed.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/app_colors.dart';
import 'package:fitai/core/theme/field_manual.dart';
import 'package:fitai/core/theme/fm_skin.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';

void main() {
  test('non-texture themes: scaffold IS background (no visual change)', () {
    var checked = 0;
    for (final theme in themeRegistry) {
      if (theme.surfaceTexture != null) continue;
      final p = AppColors.resolve(theme: theme, brightness: Brightness.dark);
      expect(p.scaffold, p.background,
          reason: '${theme.id} scaffold diverged from background');
      checked++;
    }
    // Field Manual + the eight accent-swap packs.
    expect(checked, 9, reason: 'expected 9 non-texture themes');
  });

  test('texture skins: scaffold is transparent so the layer shows through', () {
    for (final id in ['night_ops', 'woodland', 'dress_blues']) {
      final p = AppColors.resolve(
          theme: themeById(id), brightness: Brightness.dark);
      expect(p.scaffold.a, 0.0, reason: '$id scaffold is not transparent');
      expect(p.background, isNot(p.scaffold));
    }
  });

  test('FieldManual.scaffold mirrors the palette token', () {
    // Many screens set a scaffold colour with no Palette in scope and used to
    // hardcode FieldManual.ink — which is exactly what occluded the texture on
    // dashboard / nutrition / progress. The static twin must scope identically.
    FieldManual.skin = const FmSkin.fieldManual();
    expect(FieldManual.scaffold, FieldManual.ink,
        reason: 'non-texture skins must keep their opaque ink ground');

    for (final id in ['night_ops', 'woodland', 'dress_blues']) {
      FieldManual.skin = FmSkin.fromTheme(themeById(id));
      expect(FieldManual.scaffold.a, 0.0,
          reason: '$id scaffold ground is not transparent');
    }
    FieldManual.skin = const FmSkin.fieldManual();
  });

  test('no screen hardcodes an opaque ink scaffold ground', () {
    // Regression guard for Bug 2. The first sweep only converted
    // `palette.background`, so 23 screens still hardcoded `FieldManual.ink`
    // as their scaffold and painted straight over the global texture —
    // which is why dashboard/nutrition/progress were blank but settings
    // (which used the palette token) worked.
    //
    // Sheets and cards legitimately keep `color: FieldManual.ink`; only
    // `backgroundColor:` denotes a scaffold ground.
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.readAsStringSync().contains('backgroundColor: FieldManual.ink,')) {
        offenders.add(f.path.split(RegExp(r'[\\/]')).last);
      }
    }
    expect(offenders, isEmpty,
        reason: 'these paint an opaque ground over the global texture: '
            '${offenders.join(", ")}');
  });
}
