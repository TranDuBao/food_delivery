import 'package:flutter/material.dart';
import 'package:food_delivery/main.dart';
import 'package:food_delivery/view/shared/login/welcome_view.dart';

import '../../../common/globs.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StarupViewState();
}

class _StarupViewState extends State<StartupView> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goNextPage();
    });
  }

  Future<void> _goNextPage() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _navigated) {
      return;
    }
    _navigateByLoginState();
  }

  void _navigateByLoginState() {
    _navigated = true;
    if (Globs.udValueBool(Globs.userLogin)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => resolveHomeByRole()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/img/splash_bg.png",
            width: media.width,
            height: media.height,
            fit: BoxFit.cover,
          ),
            Image.asset(
              "assets/img/app_logo.png",
              width: media.width * 0.55,
              height: media.width * 0.55,
            fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}
