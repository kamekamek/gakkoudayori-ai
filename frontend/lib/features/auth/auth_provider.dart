import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FirebaseAuthのインスタンスを提供するプロバイダ
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// 認証状態の変更を監視するStreamProvider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// GoogleSignInのインスタンスを提供するプロバイダ
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // 必要に応じてスコープを追加
    // scopes: [
    //   'email',
    //   'https://www.googleapis.com/auth/classroom.coursework.students',
    // ],
  );
});