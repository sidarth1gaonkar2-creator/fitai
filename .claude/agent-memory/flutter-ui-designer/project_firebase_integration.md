---
name: Firebase Integration
description: Firebase Auth, Firestore, Storage services and providers — core infrastructure for auth and community features
type: project
---

## Firebase Services

### AuthService (lib/services/auth_service.dart)
- FirebaseAuth dependency
- signInWithEmail(), signUpWithEmail(), signInWithGoogle()
- sendPasswordResetEmail(), signOut()

### StorageService (lib/services/storage_service.dart)
- Firebase Storage for file uploads
- pickImage() — ImagePicker with compression (512x512, 80% JPEG quality), gallery or camera
- uploadProfilePicture(userId, file) → URL string
- deleteProfilePicture(userId)

### FirestoreService (lib/services/firestore_service.dart)
- Cloud Firestore wrapper
- collection(), getDoc(), setDoc(), updateDoc(), deleteDoc()
- query(), paginatedQuery() with QueryFilter
- batch(), runTransaction()

## Providers

### Auth (lib/providers/auth_provider.dart)
- `firebaseAuthProvider` — FirebaseAuth instance
- `authServiceProvider` — AuthService
- `authStateProvider` — Stream of auth state changes
- `currentUserIdProvider` — Computed current user ID

### Firestore (lib/providers/firestore_provider.dart)
- `firestoreProvider` — FirebaseFirestore instance
- `storageProvider` — FirebaseStorage instance
- `firestoreServiceProvider` — FirestoreService
- `storageServiceProvider` — StorageService

## Initialization (lib/main.dart)
1. Firebase.initializeApp()
2. Isar local database init
3. SharedPreferences init
4. NotificationService init
5. ProviderScope overrides with Firebase instances
6. One-time PR migration service

## Auth Screens (lib/features/auth/presentation/)
- WelcomeScreen — app entry with sign in / sign up options
- SignInScreen — email/password + Google sign-in
- SignUpScreen — email/password registration

## Packages
- firebase_core: ^3.0.0
- firebase_auth: ^5.0.0
- cloud_firestore: ^5.0.0
- firebase_storage: ^12.0.0
- google_sign_in: ^6.2.0
- image_picker: ^1.1.0
- cached_network_image: ^3.3.0
