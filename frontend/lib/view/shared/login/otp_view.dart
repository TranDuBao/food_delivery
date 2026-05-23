import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:food_delivery/common_widget/round_textfield.dart';
import 'package:food_delivery/view/shared/login/new_password_view.dart';

import '../../../common/globs.dart';
import '../../../common/service_call.dart';

class OTPView extends StatefulWidget {
  final String tenDangNhap;
  final String? resetToken;

  const OTPView({super.key, required this.tenDangNhap, this.resetToken});

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final TextEditingController txtResetToken = TextEditingController();

  @override
  void initState() {
    super.initState();
    txtResetToken.text = widget.resetToken ?? "";
  }

  @override
  void dispose() {
    txtResetToken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Text(
                "We have generated a reset token",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Please use the reset token for ${widget.tenDangNhap}\ncontinue to reset your password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              RoundTextfield(
                hintText: "Paste reset token here",
                controller: txtResetToken,
              ),
              const SizedBox(height: 30),
              RoundButton(
                title: "Next",
                onPressed: btnSubmit,
              ),
              TextButton(
                onPressed: () {
                  serviceCallForgotRequest({"tenDangNhap": widget.tenDangNhap});
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Didn't Received? ",
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Click Here",
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void btnSubmit() {
    if (txtResetToken.text.trim().isEmpty) {
      mdShowAlert(Globs.appName, MSG.enterCode, () {});
      return;
    }

    endEditing();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordView(
          nObj: {
            "tenDangNhap": widget.tenDangNhap,
            KKey.resetToken: txtResetToken.text.trim(),
          },
        ),
      ),
    );
  }

  void serviceCallForgotRequest(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(
      parameter,
      SVKey.svForgotPasswordRequest,
      withSuccess: (responseObj) async {
        Globs.hideHUD();
        final resetToken = responseObj[KKey.resetToken] as String? ??
            responseObj["resetToken"] as String? ??
            "";

        if (resetToken.isNotEmpty) {
          txtResetToken.text = resetToken;
          mdShowAlert(Globs.appName, "Reset token refreshed.", () {});
        } else {
          mdShowAlert(Globs.appName, responseObj[KKey.message] as String? ?? MSG.fail, () {});
        }
      },
      failure: (err) async {
        Globs.hideHUD();
        mdShowAlert(Globs.appName, err.toString(), () {});
      },
    );
  }
}
