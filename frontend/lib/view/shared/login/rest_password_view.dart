import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:food_delivery/view/shared/login/otp_view.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/round_textfield.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  TextEditingController txtTenDangNhap = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 64,
              ),
              Text(
                "Reset Password",
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),

               const SizedBox(
                height: 15,
              ),

              Text(
                "Please enter your username to receive a\n reset token to create a new password",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                height: 60,
              ),
              RoundTextfield(
                hintText: "Tên đăng nhập",
                controller: txtTenDangNhap,
              ),
              const SizedBox(
                height: 30,
              ),
             
              RoundButton(title: "Send", onPressed: () {
                btnSubmit();
                
              }),
              
            ],
          ),
        ),
      ),
    );
  }

  //TODO: Action
  void btnSubmit() {
    if (txtTenDangNhap.text.isEmpty) {
      mdShowAlert(Globs.appName, "Vui lòng nhập tên đăng nhập.", () {});
      return;
    }

    endEditing();

    serviceCallForgotRequest({
      "tenDangNhap": txtTenDangNhap.text
    });
  }

  //TODO: ServiceCall

  void serviceCallForgotRequest(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordRequest, withSuccess: (responseObj) async {
      Globs.hideHUD();
      final resetToken = responseObj[KKey.resetToken] as String? ?? responseObj["resetToken"] as String? ?? "";

      if (resetToken.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPView(tenDangNhap: txtTenDangNhap.text, resetToken: resetToken),
          ),
        );
      } else {
        mdShowAlert(Globs.appName, responseObj[KKey.message] as String? ?? MSG.fail, () {});
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    });
  }
}
