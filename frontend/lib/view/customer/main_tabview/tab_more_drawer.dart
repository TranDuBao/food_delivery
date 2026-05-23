import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/service_call.dart';
import '../more/more_view.dart';
import '../more/notification_view.dart';
import '../more/inbox_view.dart';
import '../more/about_us_view.dart';
import '../voucher/my_vouchers_view.dart';
import '../voucher/voucher_service.dart';

/// Mở drawer dưới lên khi long-press Invite tab.
class TabMoreDrawer extends StatelessWidget {
  const TabMoreDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Title ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.menu_rounded, color: TColor.primaryText, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ── Menu items ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    DrawerMenuItem(
                      icon: Icons.credit_card_rounded,
                      label: 'Payment Details',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MoreView()));
                      },
                    ),
                    DrawerMenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      color: const Color(0xFFFF6B6B),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NotificationsView()));
                      },
                    ),
                    DrawerMenuItem(
                      icon: Icons.inbox_rounded,
                      label: 'Inbox',
                      color: const Color(0xFF2ECC71),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const InboxView()));
                      },
                    ),
                    DrawerMenuItem(
                      icon: Icons.info_rounded,
                      label: 'About Us',
                      color: const Color(0xFF3498DB),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AboutUsView()));
                      },
                    ),
                    // Voucher
                    StatefulBuilder(
                      builder: (ctx, _) {
                        final count = VoucherService.instance.myVouchers.length;
                        return DrawerMenuItem(
                          icon: Icons.local_offer_rounded,
                          label: 'Voucher của tôi',
                          color: const Color(0xFFFF6B35),
                          badge: count > 0 ? '$count' : null,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const MyVouchersView()));
                          },
                        );
                      },
                    ),
                    const Divider(),
                    DrawerMenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Đăng xuất',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        ServiceCall.logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Drawer menu item tile ─────────────────────────────────────────────────────
class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge; // số đếm hiển thị dạng badge

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: badge != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ])
          : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
