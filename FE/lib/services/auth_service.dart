import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Lắng nghe trạng thái đăng nhập/đăng xuất (Stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================
  // ĐĂNG KÝ (Register)
  // ============================
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    String phoneNumber = '',
    String address = '',
  }) async {
    try {
      // 1. Tạo tài khoản trên Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Cập nhật tên hiển thị
      await credential.user!.updateDisplayName(fullName);

      // 3. Tạo đối tượng AppUser
      AppUser appUser = AppUser(
        id: credential.user!.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        role: UserRole.traveler,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // 4. Lưu thông tin chi tiết lên Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(appUser.toJson());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ============================
  // ĐĂNG NHẬP (Login)
  // ============================
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Đăng nhập bằng Firebase Auth
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Lấy thông tin chi tiết từ Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (doc.exists) {
        return AppUser.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        // Nếu chưa có document trên Firestore (user cũ), tạo mới
        AppUser appUser = AppUser(
          id: credential.user!.uid,
          fullName: credential.user!.displayName ?? '',
          email: email,
          role: UserRole.traveler,
        );
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toJson());
        return appUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ============================
  // ĐĂNG XUẤT (Logout)
  // ============================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============================
  // QUÊN MẬT KHẨU (Forgot Password)
  // ============================
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ============================
  // LẤY THÔNG TIN USER HIỆN TẠI
  // ============================
  Future<AppUser?> getCurrentUserData() async {
    if (currentUser == null) return null;

    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      return AppUser.fromJson(doc.data() as Map<String, dynamic>);
    }

    final appUser = AppUser(
      id: currentUser!.uid,
      fullName: currentUser!.displayName ?? '',
      email: currentUser!.email ?? '',
      role: UserRole.traveler,
    );
    await docRef.set(appUser.toJson());
    return appUser;
  }

  Future<void> ensureCurrentUserDocument() async {
    if (currentUser == null) return;

    final docRef = _firestore.collection('users').doc(currentUser!.uid);
    final doc = await docRef.get();

    if (doc.exists) return;

    final appUser = AppUser(
      id: currentUser!.uid,
      fullName: currentUser!.displayName ?? '',
      email: currentUser!.email ?? '',
      role: UserRole.traveler,
    );

    await docRef.set(appUser.toJson());
  }

  // ============================
  // XỬ LÝ LỖI (Error Handling)
  // ============================
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }
}
