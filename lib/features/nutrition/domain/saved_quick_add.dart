import 'dart:convert';

/// A reusable Quick Add preset. Persisted as JSON inside SharedPreferences
/// so we don't have to add a new Isar collection (which would require running
/// build_runner against the legacy isar_generator).
class SavedQuickAdd {
  SavedQuickAdd({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.lastUsedAt,
    this.useCount = 0,
    this.emoji,
  });

  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime lastUsedAt;
  final int useCount;
  final String? emoji;

  SavedQuickAdd copyWith({
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? lastUsedAt,
    int? useCount,
    String? emoji,
    bool clearEmoji = false,
  }) {
    return SavedQuickAdd(
      id: id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'lastUsedAt': lastUsedAt.millisecondsSinceEpoch,
        'useCount': useCount,
        if (emoji != null) 'emoji': emoji,
      };

  factory SavedQuickAdd.fromJson(Map<String, dynamic> json) {
    return SavedQuickAdd(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['lastUsedAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      emoji: json['emoji'] as String?,
    );
  }

  static String encodeAll(List<SavedQuickAdd> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<SavedQuickAdd> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedQuickAdd.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
