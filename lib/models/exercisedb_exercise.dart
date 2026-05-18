/// Lightweight POJO for a single ExerciseDB API record. The service maps
/// raw JSON into this shape so callers don't have to deal with the half-
/// dozen field aliases the API uses across endpoints.
///
/// All list fields default to `const []` so checks like
/// `exercise.targetMuscles.isNotEmpty` don't trip on null.
class ExerciseDBExercise {
  const ExerciseDBExercise({
    required this.id,
    required this.name,
    this.imageUrl,
    this.videoUrl,
    this.equipments = const [],
    this.bodyParts = const [],
    this.targetMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.tips = const [],
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> equipments;
  final List<String> bodyParts;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<String> tips;

  /// All muscles touched by this exercise (target + secondary), deduplicated.
  /// Useful for the muscle highlight widget.
  List<String> get allMuscles {
    final set = <String>{...targetMuscles, ...secondaryMuscles};
    return set.toList();
  }

  /// API may return either `imageUrl` (v2 hosted) or a bare filename
  /// (`Barbell-Bench-Press_Chest.png`). Build the canonical static-CDN URL
  /// when the field doesn't already include a scheme.
  String? get fullImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return 'https://static.exercisedb.dev/images/$raw';
  }

  String? get fullVideoUrl {
    final raw = videoUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return 'https://static.exercisedb.dev/videos/$raw';
  }

  factory ExerciseDBExercise.fromJson(Map<String, dynamic> json) {
    List<String> listFrom(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return ExerciseDBExercise(
      id: (json['exerciseId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      // v2 returns `imageUrl`; legacy v1 returned `gifUrl`.
      imageUrl: (json['imageUrl'] ?? json['gifUrl']) as String?,
      videoUrl: json['videoUrl'] as String?,
      equipments: listFrom(json['equipments'] ?? json['equipment']),
      bodyParts: listFrom(json['bodyParts'] ?? json['bodyPart']),
      targetMuscles: listFrom(json['targetMuscles'] ?? json['target']),
      secondaryMuscles: listFrom(json['secondaryMuscles']),
      instructions: listFrom(json['instructions']),
      tips: listFrom(json['exerciseTips'] ?? json['tips']),
    );
  }

  /// Inverse of [fromJson] used by the on-disk cache.
  Map<String, dynamic> toJson() => {
        'exerciseId': id,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        'equipments': equipments,
        'bodyParts': bodyParts,
        'targetMuscles': targetMuscles,
        'secondaryMuscles': secondaryMuscles,
        'instructions': instructions,
        'exerciseTips': tips,
      };
}
