// Bug 1: the app-wide background kept painting the PREVIOUS skin after
// switching, correcting only on a full app restart.
//
// The cache was NOT the cause — SurfaceTexture._cache is keyed by texture id
// and those ids are unique per skin. The cause was that GlobalSkinBackground
// was a `const` widget reading a mutable static: const instances are
// canonicalized, Element.updateChild short-circuits on identical(new, old),
// so build() ran exactly once and captured whichever skin was equipped at
// first frame.
//
// This drives a LIVE provider switch (not a re-pump) and asserts the painted
// texture follows it.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/surface_texture.dart';
import 'package:fitai/core/widgets/tactical_surface.dart';
import 'package:fitai/features/themes/domain/app_theme_data.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

/// Drives the equipped theme, standing in for the real equip flow.
final _equipped = StateProvider<AppThemeData>((_) => themeById('night_ops'));

String? _paintedTextureId(WidgetTester tester) {
  for (final w in tester.widgetList<CustomPaint>(find.byType(CustomPaint))) {
    final p = w.painter;
    if (p is SurfaceTexturePainter) return p.texture.id;
  }
  return null;
}

void main() {
  testWidgets('global background follows a live skin switch, no restart',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeThemeProvider.overrideWith((ref) => ref.watch(_equipped)),
        ],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [Positioned.fill(child: GlobalSkinBackground())],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_paintedTextureId(tester), 'night_ops');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GlobalSkinBackground)),
    );

    // Equip Woodland — no re-pumpWidget, no restart. Just the provider moving.
    container.read(_equipped.notifier).state = themeById('woodland');
    await tester.pump();
    expect(_paintedTextureId(tester), 'woodland',
        reason: 'background still painting the previous skin — Bug 1 is back');

    // And Dress Blues, which also carries a header band.
    container.read(_equipped.notifier).state = themeById('dress_blues');
    await tester.pump();
    expect(_paintedTextureId(tester), 'dress_blues_twill');

    // Back to a non-texture theme: the layer must disappear entirely.
    container.read(_equipped.notifier).state = defaultTheme;
    await tester.pump();
    expect(_paintedTextureId(tester), isNull,
        reason: 'Field Manual should mount no texture painter');
  });
}
