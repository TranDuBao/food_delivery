import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/tab_button.dart';

import '../home/home_view.dart';
import '../more/my_order_view.dart';

import '../more/invite_view.dart';
import '../profile/profile_view.dart';
import 'tab_cart_button.dart';
import 'tab_invite_button.dart';
import 'tab_more_drawer.dart';

class MainTabView extends StatefulWidget {
  final int initialTab;
  const MainTabView({super.key, this.initialTab = 2});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  late int selctTab;
  final PageStorageBucket storageBucket = PageStorageBucket();
  late Widget selectPageView;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    selctTab = widget.initialTab;
    selectPageView = _pageFor(selctTab);
    _loadCartCount();
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 0: return const OrderHistoryView();
      case 1: return const MyOrderView();
      case 2: return const HomeView();
      case 3: return const ProfileView();
      case 4: return const InviteView();
      default: return const HomeView();
    }
  }

  void _switchTab(int index) {
    if (selctTab != index) {
      setState(() {
        selctTab = index;
        selectPageView = _pageFor(index);
      });
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (res is Map && res['success'] == true) {
        final items = res['data'] as List? ?? [];
        final count = items.fold<int>(0, (sum, item) {
          return sum + ((item['soLuong'] as num?)?.toInt() ?? 0);
        });
        if (mounted) setState(() => _cartCount = count);
      }
    } catch (_) {}
  }

  void _openMoreDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TabMoreDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: _HomeFab(
        isSelected: selctTab == 2,
        onTap: () => _switchTab(2),
      ),
      bottomNavigationBar: _BottomBar(
        selectedTab: selctTab,
        cartCount: _cartCount,
        onTabTap: _switchTab,
        onCartTap: () async {
          _switchTab(1);
          await Future.delayed(const Duration(milliseconds: 500));
          _loadCartCount();
        },
        onMoreTap: _openMoreDrawer,
        onInviteTap: () => _switchTab(4),
      ),
    );
  }
}

// ─── Home FAB ────────────────────────────────────────────────────────────────
class _HomeFab extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _HomeFab({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        onPressed: onTap,
        shape: const CircleBorder(),
        backgroundColor: isSelected ? TColor.primary : TColor.placeholder,
        child: Image.asset('assets/img/tab_home.png', width: 30, height: 30),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int selectedTab;
  final int cartCount;
  final ValueChanged<int> onTabTap;
  final VoidCallback onCartTap;
  final VoidCallback onMoreTap;
  final VoidCallback onInviteTap;

  const _BottomBar({
    required this.selectedTab,
    required this.cartCount,
    required this.onTabTap,
    required this.onCartTap,
    required this.onMoreTap,
    required this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      surfaceTintColor: TColor.white,
      shadowColor: Colors.black,
      elevation: 1,
      notchMargin: 12,
      shape: const CircularNotchedRectangle(),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Đơn hàng
            TabButton(
              title: 'Orders',
              icon: 'assets/img/tab_menu.png',
              isSelected: selectedTab == 0,
              onTap: () => onTabTap(0),
            ),

            // Giỏ hàng
            TabCartButton(
              isSelected: selectedTab == 1,
              cartCount: cartCount,
              onTap: onCartTap,
            ),

            // Khoảng trống cho FAB
            const SizedBox(width: 40, height: 40),

            // Profile
            TabButton(
              title: 'Profile',
              icon: 'assets/img/tab_profile.png',
              isSelected: selectedTab == 3,
              onTap: () => onTabTap(3),
            ),

            // Invite (long press → More drawer)
            TabInviteButton(
              isSelected: selectedTab == 4,
              onTap: onInviteTap,
              onMoreTap: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }
}
