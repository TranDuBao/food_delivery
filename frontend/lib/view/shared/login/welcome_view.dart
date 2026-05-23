import 'package:flutter/material.dart';
import 'package:food_delivery/view/shared/login/login_view.dart';
import 'package:food_delivery/view/shared/login/sing_up_view.dart';

import '../../../common/color_extension.dart';
import '../../../common_widget/round_button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Logo được khai báo TRƯỚC -> sẽ nằm ở LỚP DƯỚI (Send to Back)
                Image.asset(
                  "assets/img/app_logo.png",
                  width: media.width * 0.6,
                  height: media.width * 0.6,
                  fit: BoxFit.contain,
                ),
                // 2. Hình màu cam khai báo SAU -> sẽ NẰM ĐÈ LÊN TRÊN (Bring to Front)
                Image.asset(
                  "assets/img/welcome_top_shape.png",
                  width: media.width,
                ),
              ],
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Text(
              "",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: "Login",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: "Create an Account",
                type: RoundButtonType.textPrimary,
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}