import 'package:flutter/widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../domain/milestone.dart';

/// Horizontal strip of milestone badges — FM chrome: field panels with
/// hairline borders. Earned badges carry the live accent (brass on the
/// default issue); unearned ones sit quiet in olive structure. No ramp
/// existed before this reskin, so brass-on-field is the earned identity.
class MilestoneBadges extends StatelessWidget {
  const MilestoneBadges({super.key, required this.milestones});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return SizedBox(
      // Scales with Dynamic Type so two label lines always fit.
      height: MediaQuery.textScalerOf(context).scale(80),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: milestones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = milestones[index];
          final earned = m.isEarned;

          return Semantics(
            label:
                'Milestone: ${m.title}, ${earned ? 'earned' : 'not yet earned'}',
            child: ExcludeSemantics(
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FieldManual.field,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: earned
                        ? palette.accent.withValues(alpha: 0.45)
                        : FieldManual.hairline,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      m.icon,
                      color: earned ? palette.accent : FieldManual.olive,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FieldManual.label(
                        fontSize: 11,
                        color: earned
                            ? FieldManual.bone
                            : FieldManual.mutedBone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
