import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  throw UnimplementedError('FirebaseAuth must be overridden in ProviderScope');
});

final authServiceProvider = Provider<AuthService>((ref) {
  // Endpoint of the deployed `deleteAccount` Cloud Function. Read from
  // assets/.env the same way AI_PROXY_URL is — null when unset, which disables
  // account deletion gracefully (the method throws a user-safe message).
  final deleteUrl = dotenv.env['DELETE_ACCOUNT_URL'];
  return AuthService(
    ref.watch(firebaseAuthProvider),
    deleteAccountEndpoint: (deleteUrl == null || deleteUrl.isEmpty)
        ? null
        : Uri.parse(deleteUrl),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Current Firebase UID, or null if not authenticated.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Whether Firebase reported a signed-in user during app bootstrap. Overridden
/// in `main()` with the value resolved before the real app mounts, so the
/// router can choose its initial route synchronously — a signed-in user starts
/// on /dashboard and never sees the welcome screen. Defaults to false (the
/// pre-bootstrap-resolution behaviour) when not overridden.
final bootSignedInProvider = Provider<bool>((ref) => false);
