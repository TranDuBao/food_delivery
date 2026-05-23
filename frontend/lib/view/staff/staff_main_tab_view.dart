// lib/view/staff/staff_main_tab_view.dart
// Thanh điều hướng nhân viên — đồng bộ kiểu Customer:
//   BottomAppBar + nút FAB tròn cam ở giữa (→ Tab Home/Menu)
//   4 tab còn lại: Orders | Prepare | [FAB] | Static | Ship

import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'staff_dine_in_view.dart';
import 'staff_kds_view.dart';
import 'staff_menu_view.dart';
import 'staff_orders_view.dart';
import 'staff_ship_view.dart';
import 'staff_statistic_view.dart';

class StaffMainTabView extends StatefulWidget {
  const StaffMainTabView({super.key});

  @override
  State<StaffMainTabView> createState() => _StaffMainTabViewState();
}

class _StaffMainTabViewState extends State<StaffMainTabView> {
  // index mapping:
  //  0 = Orders   1 = Prepare   2 = Menu (Home/FAB)   3 = Static   4 = Ship
  int _selectedTab = 2; // mặc định vào trang Home/Menu

  void _goToPrepare() => setState(() => _selectedTab = 1);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          StaffOrdersView(onNavigateToPrepare: _goToPrepare),
          const StaffKDSView(),
          const StaffMenuView(),
          const StaffStatisticView(),
          const StaffShipView(),
          const StaffDineInView(),
        ],
      ),

      // ── Nút FAB tròn cam ở giữa (giống Customer) ──────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: _MenuFab(
        isSelected: _selectedTab == 2,
        onTap: () => setState(() => _selectedTab = 2),
      ),

      // ── Bottom bar ────────────────────────────────────────────────────────
      bottomNavigationBar: _StaffBottomBar(
        selectedTab: _selectedTab,
        onTabTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

// ─── FAB nút Home/Menu ──────────────────────────────────────────────────────
class _MenuFab extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _MenuFab({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        onPressed: onTap,
        shape: const CircleBorder(),
        elevation: isSelected ? 6 : 3,
        backgroundColor: isSelected ? TColor.primary : TColor.placeholder,
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ──────────────────────────────────────────────────
class _StaffBottomBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabTap;

  const _StaffBottomBar({
    required this.selectedTab,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      surfaceTintColor: Colors.white,
      color: Colors.white,
      shadowColor: Colors.black,
      elevation: 1,
      notchMargin: 12,
      shape: const CircularNotchedRectangle(),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ── Orders ──────────────────────────────────────────────────────
            _StaffTabButton(
              icon: selectedTab == 0 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
              label: 'Orders',
              isSelected: selectedTab == 0,
              onTap: () => onTabTap(0),
            ),

            // ── Prepare ─────────────────────────────────────────────────────
            _StaffTabButton(
              icon: selectedTab == 1 ? Icons.kitchen : Icons.kitchen_outlined,
              label: 'Prepare',
              isSelected: selectedTab == 1,
              onTap: () => onTabTap(1),
            ),

            // ── Khoảng trống cho FAB ─────────────────────────────────────────
            const SizedBox(width: 48, height: 48),

            // ── Static ──────────────────────────────────────────────────────
            _StaffTabButton(
              icon: selectedTab == 3 ? Icons.bar_chart_rounded : Icons.bar_chart_outlined,
              label: 'Static',
              isSelected: selectedTab == 3,
              onTap: () => onTabTap(3),
            ),

            // ── Ship ────────────────────────────────────────────────────────
            _StaffTabButton(
              icon: selectedTab == 4 ? Icons.delivery_dining_rounded : Icons.delivery_dining_outlined,
              label: 'Ship',
              isSelected: selectedTab == 4,
              onTap: () => onTabTap(4),
            ),

            // ── Bàn (Dine-in) ────────────────────────────────────────────────
            _StaffTabButton(
              icon: selectedTab == 5 ? Icons.table_restaurant : Icons.table_restaurant_outlined,
              label: 'Bàn',
              isSelected: selectedTab == 5,
              onTap: () => onTabTap(5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget tab button nhỏ (icon + label) ───────────────────────────────────
class _StaffTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _StaffTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? TColor.primary : const Color(0xFFAAAAAA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
