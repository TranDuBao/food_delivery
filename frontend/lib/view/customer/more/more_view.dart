import 'package:flutter/material.dart';
import 'package:food_delivery/view/customer/more/about_us_view.dart';
import 'package:food_delivery/view/customer/more/inbox_view.dart';
import 'package:food_delivery/view/customer/more/payment_details_view.dart';
import 'package:food_delivery/view/customer/voucher/my_vouchers_view.dart';

import '../../../common/color_extension.dart';
import '../../../common/service_call.dart';
import 'my_order_view.dart';
import 'notification_view.dart';

class MoreView extends StatefulWidget {
  const MoreView({super.key});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'index': '1',
      'name': 'Payment Details',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF6C63FF),
      'subtitle': 'Quản lý phương thức thanh toán',
    },
    {
      'index': '2',
      'name': 'My Cart',
      'icon': Icons.shopping_cart_rounded,
      'color': const Color(0xFFFF6B35),
      'subtitle': 'Xem giỏ hàng của bạn',
    },
    {
      'index': '3',
      'name': 'Notifications',
      'icon': Icons.notifications_rounded,
      'color': const Color(0xFFFF6B6B),
      'subtitle': 'Thông báo & cập nhật đơn hàng',
      'badge': 15,
    },
    {
      'index': '4',
      'name': 'Inbox',
      'icon': Icons.inbox_rounded,
      'color': const Color(0xFF2ECC71),
      'subtitle': 'Tin nhắn hỗ trợ',
    },
    {
      'index': '5',
      'name': 'About Us',
      'icon': Icons.info_rounded,
      'color': const Color(0xFF3498DB),
      'subtitle': 'Thông tin ứng dụng',
    },
    {
      'index': '7',
      'name': 'Voucher của tôi',
      'icon': Icons.local_offer_rounded,
      'color': const Color(0xFFFF6B35),
      'subtitle': 'Voucher & khuyến mãi đã thu thập',
    },
    {
      'index': '6',
      'name': 'Đăng xuất',
      'icon': Icons.logout_rounded,
      'color': Colors.red,
      'subtitle': 'Thoát khỏi tài khoản',
    },
  ];

  void _onItemTap(String index) {
    switch (index) {
      case '1':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PaymentDetailsView()));
        break;
      case '2':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyOrderView()));
        break;
      case '3':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsView()));
        break;
      case '4':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const InboxView()));
        break;
      case '5':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AboutUsView()));
        break;
      case '7':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyVouchersView()));
        break;
      case '6':
        ServiceCall.logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ServiceCall.userPayload['name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // ── Top Navbar (ẩn khi scroll xuống, hiện khi scroll lên) ──────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black12,
            toolbarHeight: 64,
            iconTheme: IconThemeData(color: TColor.primaryText),
            title: Row(
              children: [
                Icon(Icons.menu_rounded, color: TColor.primaryText, size: 26),
                const SizedBox(width: 12),
                Text(
                  'Menu',
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                // Avatar / initial
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: TColor.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade100),
            ),
          ),

          // ── User greeting card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColor.primary, TColor.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TColor.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ServiceCall.userPayload['email']?.toString() ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section title ───────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Tính năng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // ── Menu list ───────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Dấu ngăn cách trước Đăng xuất
                if (index == _menuItems.length - 1) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Colors.grey.shade200),
                      ),
                      const SizedBox(height: 8),
                      _MenuTile(item: _menuItems[index], onTap: _onItemTap),
                    ],
                  );
                }
                return _MenuTile(item: _menuItems[index], onTap: _onItemTap);
              },
              childCount: _menuItems.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── Menu Item Tile ──────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(String) onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color  = item['color'] as Color;
    final badge  = item['badge'] as int?;
    final isLogout = item['index'] == '6';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onTap(item['index'].toString()),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'].toString(),
                        style: TextStyle(
                          color: isLogout ? Colors.red : TColor.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (item['subtitle'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'].toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge nếu có
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  )
                else if (!isLogout)
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
