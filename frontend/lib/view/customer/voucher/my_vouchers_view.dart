// lib/view/customer/voucher/my_vouchers_view.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/view/customer/menu/menu_items_view.dart';
import 'voucher_model.dart';
import 'voucher_service.dart';

class MyVouchersView extends StatefulWidget {
  const MyVouchersView({super.key});

  @override
  State<MyVouchersView> createState() => _MyVouchersViewState();
}

class _MyVouchersViewState extends State<MyVouchersView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    VoucherService.instance.addListener(_onChange);
    // Reload khi vào màn hình này
    VoucherService.instance.loadAvailable();
    VoucherService.instance.loadMyVouchers();
  }

  @override
  void dispose() {
    VoucherService.instance.removeListener(_onChange);
    _tab.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<Voucher> get _mine => VoucherService.instance.myVouchers;
  List<Voucher> get _available => VoucherService.instance.availableVouchers;

  Future<void> _collect(Voucher v) async {
    if (VoucherService.instance.hasCollected(v.id)) {
      AppNotification.show(context,
          message: 'Bạn đã thu thập voucher này!', type: NotifType.warning);
      return;
    }
    final ok = await VoucherService.instance.collectVoucher(v);
    if (!mounted) return;
    if (ok) {
      AppNotification.show(context,
          title: 'Thu thập thành công! 🎉',
          message: 'Voucher đã được lưu vào túi.',
          type: NotifType.success);
    } else {
      AppNotification.show(context,
          message: 'Không thể lưu voucher. Vui lòng thử lại.',
          type: NotifType.error);
    }
  }

  /// Navigate tới menu gian hàng khi bấm "Dùng ngay"
  void _navigateToMenu(BuildContext ctx, Voucher v) {
    final canteenObj = <String, dynamic>{
      'canteenId'  : v.restaurantId,
      'id'         : v.restaurantId,
      'name'       : v.restaurantName,
      // Thông tin voucher để MenuItemsView hiển thị banner
      'activeVoucherCode'    : v.code,
      'activeVoucherDiscount': v.discountPercent,
      'activeVoucherTitle'   : v.title,
    };
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => MenuItemsView(mObj: canteenObj)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('🎟️ Voucher của tôi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: TColor.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: TColor.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '💼 Đã thu thập'),
            Tab(text: '🏷️ Khuyến mãi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // Tab 1: Voucher đã thu thập
          _mine.isEmpty
              ? _EmptyState(
                  icon: Icons.local_offer_outlined,
                  msg: 'Bạn chưa thu thập voucher nào.\nQuay lại trang chủ để tìm voucher!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mine.length,
                  itemBuilder: (_, i) => _VoucherTile(
                    voucher: _mine[i],
                    showCollectBtn: false,
                    onUse: () => _navigateToMenu(context, _mine[i]),
                  ),
                ),

          // Tab 2: Voucher khuyến mãi có sẵn
          _available.isEmpty
              ? _EmptyState(
                  icon: Icons.discount_outlined,
                  msg: 'Hiện không có voucher nào.\nQuay lại sau nhé!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _available.length,
                  itemBuilder: (_, i) => _VoucherTile(
                    voucher: _available[i],
                    showCollectBtn: true,
                    collected: VoucherService.instance.hasCollected(_available[i].id),
                    onCollect: () => _collect(_available[i]),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _EmptyState({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
          ]),
        ),
      );
}

// ─── Voucher Tile ─────────────────────────────────────────────────────────────
class _VoucherTile extends StatelessWidget {
  final Voucher voucher;
  final bool showCollectBtn;
  final bool collected;
  final VoidCallback? onCollect;
  final VoidCallback? onUse;

  const _VoucherTile({
    required this.voucher,
    required this.showCollectBtn,
    this.collected = false,
    this.onCollect,
    this.onUse,
  });

  Color get _accent {
    if (voucher.discountPercent >= 25) return const Color(0xFFFF6B35);
    if (voucher.discountPercent >= 15) return const Color(0xFF6C63FF);
    return const Color(0xFF2ECC71);
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        // Left colored strip with discount
        Container(
          width: 72,
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('-${voucher.discountPercent.toInt()}%',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 2),
            Text(voucher.categoryName ?? 'Tất cả',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70,
                    fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 2),
          ]),
        ),

        // Dashed separator
        CustomPaint(painter: _DashedDivider(), size: const Size(14, 110)),

        // Right content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(voucher.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(voucher.restaurantName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              // Code chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.3), style: BorderStyle.solid),
                ),
                child: Text(voucher.code,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800,
                        fontSize: 12, letterSpacing: 1)),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(
                    'Còn ${voucher.daysLeft} ngày · '
                    '${voucher.isUnlimited ? 'Không giới hạn' : '${voucher.remainingQuantity} lượt'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ]),
              const SizedBox(height: 8),
              // Action button
              if (showCollectBtn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: collected ? null : onCollect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: collected ? Colors.grey.shade200 : color,
                      foregroundColor: collected ? Colors.grey : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(collected ? 'Đã thu thập' : 'Thu thập',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onUse,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Dùng ngay',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Dashed Divider Painter ───────────────────────────────────────────────────
class _DashedDivider extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashH = 5.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashH), paint);
      y += dashH + gap;
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
