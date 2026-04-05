import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/user_profile.dart';
import 'isar_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final isar = ref.watch(isarProvider);
  final results = await isar.userProfiles.where().anyId().build().findFirst();
  return results;
});
