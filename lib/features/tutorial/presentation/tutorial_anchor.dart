import 'package:flutter/widgets.dart';

import '../domain/tutorial_steps.dart';

/// Wraps a target widget with the GlobalKey registered for tutorial step [id].
/// The tutorial overlay reads that GlobalKey's RenderBox to position the
/// spotlight, so the anchor needs to sit *immediately* around the visible
/// element (not around a padded container that would inflate the highlight).
///
/// Returns the child unchanged if [id] isn't in [tutorialKeys] — defensive in
/// case a step is removed without unwiring its anchors.
class TutorialAnchor extends StatelessWidget {
  const TutorialAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = tutorialKeys[id];
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }
}
