// lib/view/customer/more/invite_referral_section.dart
// Widget nhập mã giới thiệu từ bạn bè

import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'invite_widgets.dart';

class EnterReferralSection extends StatefulWidget {
  const EnterReferralSection({super.key});

  @override
  State<EnterReferralSection> createState() => _EnterReferralSectionState();
}

class _EnterReferralSectionState extends State<EnterReferralSection> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _ctrl.clear();
    setState(() => _loading = false);
    AppNotification.show(context,
        title: 'Thành công! 🎉',
        message: 'Đã áp dụng mã "$code"',
        type: NotifType.success);
  }

  @override
  Widget build(BuildContext context) => InviteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nhập mã giới thiệu',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Có mã từ bạn bè? Nhập vào đây!',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'VD: ABCD1234',
                  hintStyle:
                      const TextStyle(letterSpacing: 2, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: TColor.primary, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200)),
                ),
                style: const TextStyle(
                    letterSpacing: 3, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Áp dụng',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      );
}
