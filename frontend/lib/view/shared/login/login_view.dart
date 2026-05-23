import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/social_auth_service.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:food_delivery/view/customer/group/group_service.dart';
import 'package:food_delivery/view/shared/login/rest_password_view.dart';
import 'package:food_delivery/view/shared/login/sing_up_view.dart';
import 'package:food_delivery/view/shared/on_boarding/on_boarding_view.dart';

import '../../../common/service_call.dart';
import '../../../common_widget/round_textfield.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController txtTenDangNhap = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _isSocialLoading = false;

  // ─── Xử lý response login chung ───────────────────────────────
  Future<void> _handleLoginResponse(Map<dynamic, dynamic> responseObj) async {
    final userObj = Map<String, dynamic>.from(
        responseObj["user"] as Map? ??
            responseObj[KKey.payload] as Map? ??
            {});
    final sessionObj = responseObj["session"] as Map? ?? {};
    final authToken = responseObj["token"] as String? ??
        sessionObj["token"] as String? ??
        responseObj[KKey.authToken] as String? ??
        "";

    if (userObj.isNotEmpty) {
      final normalizedUser = Map<String, dynamic>.from(userObj);
      normalizedUser.putIfAbsent(
          KKey.name,
          () =>
              normalizedUser["hoTen"] ??
              normalizedUser["fullName"] ??
              "");

      Globs.udSet(normalizedUser, Globs.userPayload);
      ServiceCall.userPayload = normalizedUser;
      Globs.udBoolSet(true, Globs.userLogin);
      if (authToken.isNotEmpty) {
        Globs.udStringSet(authToken, KKey.authToken);
      }

      // Load nhóm riêng theo user này
      final userId = normalizedUser['id']?.toString() ??
          normalizedUser['_id']?.toString() ??
          normalizedUser['maTaiKhoan']?.toString() ?? '';
      await GroupService.instance.initForUser(userId);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnBoardingView()),
        (route) => false,
      );
    } else {
      mdShowAlert(
          Globs.appName,
          responseObj[KKey.message] as String? ?? MSG.fail,
          () {});
    }
  }

  // ─── Đăng nhập thường ─────────────────────────────────────────
  void _btnLogin() {
    if (txtTenDangNhap.text.isEmpty) {
      mdShowAlert(Globs.appName, "Vui lòng nhập tên đăng nhập.", () {});
      return;
    }
    if (txtPassword.text.isEmpty) {
      mdShowAlert(Globs.appName, "Vui lòng nhập mật khẩu.", () {});
      return;
    }
    endEditing();

    Globs.showHUD();
    ServiceCall.post(
      {"tenDangNhap": txtTenDangNhap.text, "matKhau": txtPassword.text},
      SVKey.svLogin,
      withSuccess: (res) async {
        Globs.hideHUD();
        _handleLoginResponse(res);
      },
      failure: (err) async {
        Globs.hideHUD();
        mdShowAlert(Globs.appName, err.toString(), () {});
      },
    );
  }

  // ─── Đăng nhập mạng xã hội ────────────────────────────────────
  Future<void> _socialLogin(String provider) async {
    if (_isSocialLoading) return;
    setState(() => _isSocialLoading = true);

    try {
      Map<String, dynamic>? socialData;

      if (provider == 'google') {
        socialData = await SocialAuthService.signInWithGoogle();
      } else {
        socialData = await SocialAuthService.signInWithFacebook();
      }

      if (socialData == null) {
        // Người dùng hủy
        setState(() => _isSocialLoading = false);
        return;
      }

      Globs.showHUD(status: 'Đang đăng nhập...');

      ServiceCall.post(
        socialData,
        SVKey.svSocialLogin,
        withSuccess: (res) async {
          Globs.hideHUD();
          _handleLoginResponse(res);
        },
        failure: (err) async {
          Globs.hideHUD();
          mdShowAlert(Globs.appName, err.toString(), () {});
        },
      );
    } catch (e) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, e.toString(), () {});
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Banner ──────────────────────────────────
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColor.primary, const Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // Vòng trang trí background
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Nội dung
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: TColor.primary,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Food Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đặt món ngon, giao tận nơi',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Form đăng nhập ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chào mừng trở lại! Vui lòng đăng nhập.',
                    style: TextStyle(
                      color: TColor.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tên đăng nhập
                  RoundTextfield(
                    hintText: 'Tên đăng nhập',
                    controller: txtTenDangNhap,
                    left: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.person_outline_rounded,
                          color: TColor.secondaryText, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mật khẩu
                  RoundTextfield(
                    hintText: 'Mật khẩu',
                    controller: txtPassword,
                    obscureText: _obscurePassword,
                    left: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.lock_outline_rounded,
                          color: TColor.secondaryText, size: 20),
                    ),
                    right: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: TColor.secondaryText,
                        size: 20,
                      ),
                    ),
                  ),

                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ResetPasswordView()),
                      ),
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                            color: TColor.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  // Nút Login
                  RoundButton(title: 'Đăng nhập', onPressed: _btnLogin),

                  const SizedBox(height: 28),

                  // ── Divider "hoặc đăng nhập với" ────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'hoặc đăng nhập với',
                          style: TextStyle(
                              color: TColor.secondaryText, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Nút Google ───────────────────────────────
                  _SocialLoginButton(
                    label: 'Tiếp tục với Google',
                    iconWidget: _GoogleIcon(),
                    color: Colors.white,
                    textColor: const Color(0xFF3C4043),
                    borderColor: const Color(0xFFDADCE0),
                    isLoading: _isSocialLoading,
                    onTap: () => _socialLogin('google'),
                  ),

                  const SizedBox(height: 12),

                  // ── Nút Facebook ─────────────────────────────
                  _SocialLoginButton(
                    label: 'Tiếp tục với Facebook',
                    iconWidget: const Icon(Icons.facebook_rounded,
                        color: Colors.white, size: 22),
                    color: const Color(0xFF1877F2),
                    textColor: Colors.white,
                    borderColor: Colors.transparent,
                    isLoading: _isSocialLoading,
                    onTap: () => _socialLogin('facebook'),
                  ),

                  const SizedBox(height: 28),

                  // ── Đăng ký ──────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpView()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: 'Chưa có tài khoản? ',
                          style: TextStyle(
                              color: TColor.secondaryText, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Đăng ký ngay',
                              style: TextStyle(
                                color: TColor.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget nút mạng xã hội ─────────────────────────────────────────────────
class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.label,
    required this.iconWidget,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: textColor,
                  ),
                )
              else ...[
                iconWidget,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Icon Google tự vẽ bằng màu chuẩn ──────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Vẽ 4 mảnh màu theo logo Google
    final segments = [
      // [startAngle, sweepAngle, color]
      [-0.1, 1.6, const Color(0xFF4285F4)], // Xanh dương (phải + trên)
      [1.5, 1.6, const Color(0xFF34A853)],  // Xanh lá (dưới phải)
      [3.1, 0.8, const Color(0xFFFBBC05)],  // Vàng (dưới trái)
      [3.9, 1.5, const Color(0xFFEA4335)],  // Đỏ (trên trái)
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg[2] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.72),
        seg[0] as double,
        seg[1] as double,
        false,
        paint,
      );
    }

    // Thanh ngang (phần G đặc trưng của Google)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(r * 0.95, r * 0.75, r * 1.0, r * 0.27),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
