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

  /// The ExerciseDB ecosystem has shipped images from a few CDNs over the
  /// years; the public v1 API now returns full URLs in `gifUrl` on
  /// `v2.exercisedb.io`. We handle three cases:
  ///
  ///   1. Already a full URL → return as-is
  ///   2. Filename that includes `.gif`/`.png` → prepend v2 CDN
  ///   3. Bare exerciseId-shaped string → use v2 CDN by id
  ///
  /// The previously-hardcoded `static.exercisedb.dev` host was the bug:
  /// it 404s on most assets in 2025. v2.exercisedb.io is the canonical
  /// CDN that the upstream project documents.
  String? get fullImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) {
      // Fall back to ID-based lookup if the JSON has an exercise id but
      // no explicit image URL — the v2 CDN serves images keyed by id.
      if (id.isNotEmpty) return 'https://v2.exercisedb.io/image/$id';
      return null;
    }
    if (raw.startsWith('http')) return raw;
    return 'https://v2.exercisedb.io/image/$raw';
  }

  String? get fullVideoUrl {
    final raw = videoUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return 'https://v2.exercisedb.io/video/$raw';
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
