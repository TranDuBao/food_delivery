// lib/view/customer/more/invite_join_group_section.dart
// Widget cho phép người dùng nhập mã nhóm và gửi yêu cầu tham gia

import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/service_call.dart';
import '../group/group_service.dart';
import 'invite_widgets.dart';

class JoinGroupSection extends StatefulWidget {
  const JoinGroupSection({super.key});

  @override
  State<JoinGroupSection> createState() => _JoinGroupSectionState();
}

class _JoinGroupSectionState extends State<JoinGroupSection> {
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
    try {
      final payload = ServiceCall.userPayload;
      final userId = payload['id']?.toString() ??
          payload['_id']?.toString() ??
          payload['maTaiKhoan']?.toString() ?? '';
      final userName = payload['hoTen']?.toString() ??
          payload['name']?.toString() ??
          payload['fullName']?.toString() ?? 'Người dùng';

      final result = await GroupService.instance.requestToJoin(
        groupCode: code,
        userId: userId,
        userName: userName,
      );

      if (!mounted) return;
      _ctrl.clear();

      switch (result) {
        case 'ok':
          AppNotification.show(context,
              title: 'Đã gửi yêu cầu! 🎉',
              message: 'Chờ chủ nhóm duyệt yêu cầu của bạn.',
              type: NotifType.success);
        case 'not_found':
          AppNotification.show(context,
              message: 'Không tìm thấy nhóm với mã "$code".',
              type: NotifType.error);
        case 'already_member':
          AppNotification.show(context,
              message: 'Bạn đã là thành viên của nhóm này rồi!',
              type: NotifType.warning);
        case 'already_requested':
          AppNotification.show(context,
              message: 'Bạn đã gửi yêu cầu rồi, đang chờ duyệt.',
              type: NotifType.warning);
        default:
          AppNotification.show(context,
              message: 'Đã xảy ra lỗi. Thử lại sau.',
              type: NotifType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InviteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group_add_rounded,
                color: Color(0xFF6C63FF), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tham gia nhóm',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('Nhập mã nhóm để gửi yêu cầu tham gia',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'VD: ABC123',
                hintStyle:
                    const TextStyle(letterSpacing: 2, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: const Color(0xFF6C63FF), width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
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
                backgroundColor: const Color(0xFF6C63FF),
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
                  : const Text('Tham gia',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}
