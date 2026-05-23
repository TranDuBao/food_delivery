// lib/common/social_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialAuthService {
  // ─── Google Sign-In ────────────────────────────────────────────
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Trả về Map chứa thông tin Google hoặc null nếu hủy / lỗi
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Đăng xuất session cũ để cho phép chọn lại tài khoản
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // Người dùng hủy

      return {
        'provider'   : 'google',
        'providerId' : account.id,
        'email'      : account.email,
        'hoTen'      : account.displayName ?? account.email,
        'anhDaiDien' : account.photoUrl,
      };
    } catch (e) {
      throw Exception('Google Sign-In thất bại: $e');
    }
  }

  /// Đăng xuất khỏi Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ─── Facebook Sign-In ──────────────────────────────────────────
  /// Trả về Map chứa thông tin Facebook hoặc null nếu hủy / lỗi
  static Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return null;
      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Facebook đăng nhập thất bại');
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: 'id,name,email,picture.width(200)',
      );

      final email = userData['email']?.toString() ??
          '${userData['id']}@facebook.com'; // Fallback nếu không có email
      final photoUrl = (userData['picture'] as Map?)?['data']?['url']?.toString();

      return {
        'provider'   : 'facebook',
        'providerId' : userData['id']?.toString() ?? '',
        'email'      : email,
        'hoTen'      : userData['name']?.toString() ?? '',
        'anhDaiDien' : photoUrl,
      };
    } catch (e) {
      throw Exception('Facebook Sign-In thất bại: $e');
    }
  }

  /// Đăng xuất khỏi Facebook
  static Future<void> signOutFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  /// Đăng xuất tất cả
  static Future<void> signOutAll() async {
    await signOutGoogle();
    await signOutFacebook();
  }
}
