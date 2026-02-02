import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moiza/config/constants.dart';
import 'package:moiza/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 아이디를 내부 이메일 형식으로 변환 (Firebase Auth는 이메일 기반)
  String _usernameToEmail(String username) => '${username.toLowerCase()}@moiza.app';

  // 아이디 중복 확인
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<UserModel?> signUp({
    required String username,
    required String password,
    required String displayName,
  }) async {
    try {
      // 아이디 중복 확인
      if (!await isUsernameAvailable(username)) {
        throw '이미 사용 중인 아이디입니다.';
      }

      final internalEmail = _usernameToEmail(username);
      final credential = await _auth.createUserWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          username: username.toLowerCase(),
          displayName: displayName,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e.code);
    } catch (e) {
      if (e is String) rethrow;
      throw '회원가입 중 오류가 발생했습니다: $e';
    }
  }

  Future<UserModel?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final internalEmail = _usernameToEmail(username);
      final credential = await _auth.signInWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );

      if (credential.user != null) {
        return await getUserById(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e.code);
    } catch (e) {
      throw '로그인 중 오류가 발생했습니다: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .update(user.toFirestore());
  }

  String _handleAuthException(String code) {
    switch (code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다. (6자 이상)';
      case 'email-already-in-use':
        return '이미 사용 중인 아이디입니다.';
      case 'invalid-email':
        return '유효하지 않은 아이디 형식입니다.';
      case 'user-not-found':
        return '존재하지 않는 아이디입니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      case 'invalid-credential':
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '인증 오류가 발생했습니다. ($code)';
    }
  }
}
