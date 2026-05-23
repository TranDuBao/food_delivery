import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:share_plus/share_plus.dart';
import 'invite_join_group_section.dart';
import 'invite_referral_section.dart';
import 'invite_widgets.dart';

class InviteView extends StatefulWidget {
  const InviteView({super.key});
  @override
  State<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends State<InviteView> {
  String _referralCode = '';
  bool _isLoading = true;
  final int _totalInvited = 0;
  final double _totalBudget = 0;
  final GlobalKey<MyGroupsCardState> _groupsCardKey = GlobalKey<MyGroupsCardState>();

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    try {
      final userId = ServiceCall.userPayload['id']?.toString() ??
          ServiceCall.userPayload['_id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        final rng = Random(userId.hashCode.abs());
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        _referralCode = List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
      } else {
        _referralCode = 'FOOD${DateTime.now().millisecondsSinceEpoch % 100000}';
      }
    } catch (_) {
      _referralCode = 'FOOD0000';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    AppNotification.show(context,
        message: 'Đã sao chép mã giới thiệu!', type: NotifType.success);
  }

  void _shareVia({required IconData icon, required Color color,
      required String title, required String hint,
      required TextInputType keyboard,
      required String Function(String) uriOf}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InviteSheet(
        icon: icon, color: color, title: title, hint: hint,
        keyboardType: keyboard, controller: ctrl,
        onSend: (v) async {
          Navigator.pop(ctx);
          await Share.share(
              'Dùng mã $_referralCode để đăng ký Food Delivery!\n${uriOf(v)}');
          if (mounted) {
            AppNotification.show(context,
                message: 'Đã mở $title đến $v!', type: NotifType.success);
          }
        },
      ),
    );
  }

  void _shareViaEmail() => _shareVia(
        icon: Icons.mail_rounded, color: const Color(0xFFEA4335),
        title: 'Gửi qua Gmail', hint: 'Nhập địa chỉ email...',
        keyboard: TextInputType.emailAddress,
        uriOf: (v) => 'mailto:$v',
      );

  void _shareViaSms() => _shareVia(
        icon: Icons.phone_rounded, color: const Color(0xFF34A853),
        title: 'Gửi qua SMS', hint: 'Nhập số điện thoại...',
        keyboard: TextInputType.phone,
        uriOf: (v) => 'sms:$v',
      );

  void _shareViaOther() => Share.share(
      'Bạn ơi, dùng mã giới thiệu của mình: $_referralCode\nhttps://example.com/download');

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: TColor.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColor.primary, TColor.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(top: -30, right: -30,
                  child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🎉 Mời bạn bè',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Mời bạn bè cùng đặt đồ ăn & tích lũy ngân sách!',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  ]),
                ),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Stats
              Row(children: [
                InviteStatCard(icon: Icons.group_rounded, label: 'Đã mời',
                    value: '$_totalInvited', color: const Color(0xFF6C63FF)),
                const Spacer(),
              ]),
              const SizedBox(height: 16),



              // Tham gia nhóm
              const JoinGroupSection(),
              const SizedBox(height: 16),

              // Nhóm của tôi
              GroupNotificationsCard(
                parentContext: context,
                groupsCardKey: _groupsCardKey,
              ),
              MyGroupsCard(key: _groupsCardKey, parentContext: context),
              const SizedBox(height: 16),

              // Cách hoạt động
              InviteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cách hoạt động',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                InviteStep(step: '1', title: 'Chia sẻ mã',
                    desc: 'Gửi mã giới thiệu qua Gmail, SMS hoặc link.',
                    color: TColor.primary),
                InviteStep(step: '2', title: 'Bạn bè đăng ký',
                    desc: 'Họ nhập mã và tạo tài khoản.',
                    color: const Color(0xFF6C63FF)),
                InviteStep(step: '3', title: 'Lập nhóm & chia ngân sách',
                    desc: 'Tạo nhóm, nạp tiền vào ví chung, cùng đặt đồ ăn!',
                    color: const Color(0xFF2ECC71), isLast: true),
              ])),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }
}
