import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/service_call.dart';
import '../shared/login/welcome_view.dart';
import 'staff_qr_view.dart';
import 'staff_store_view.dart';
import 'staff_voucher_view.dart';

class StaffMoreView extends StatelessWidget {
  const StaffMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Staff Utilities & More',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: TColor.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Settings card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.storefront_outlined,
                  title: 'Store Information',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffStoreView()));
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Settings',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Preferences',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.local_offer_rounded,
                  title: 'Quản lý Voucher',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StaffVoucherView()));
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.qr_code_rounded,
                  title: 'Mã QR Quán',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StaffQrView()));
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsRow(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailing: 'English',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const Spacer(),

          // Logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await ServiceCall.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomeView()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3ED),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TColor.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trailing!,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBBBBBB)),
              ],
            )
          : const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFBBBBBB)),
    );
  }
}
