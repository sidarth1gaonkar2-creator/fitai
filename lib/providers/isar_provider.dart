import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Isar instance provider — overridden in main.dart with the real instance.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be overridden in ProviderScope');
});
