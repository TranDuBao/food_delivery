// lib/view/customer/voucher/home_voucher_section.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'voucher_model.dart';
import 'voucher_service.dart';
import 'my_vouchers_view.dart';

class HomeVoucherSection extends StatefulWidget {
  const HomeVoucherSection({super.key});

  @override
  State<HomeVoucherSection> createState() => _HomeVoucherSectionState();
}

class _HomeVoucherSectionState extends State<HomeVoucherSection> {
  // Một khi đã load xong (kể cả thất bại), đánh dấu để không ẩn hoàn toàn
  bool _doneFirstLoad = false;

  @override
  void initState() {
    super.initState();
    VoucherService.instance.addListener(_onServiceChange);
    // Dùng postFrameCallback để tránh setState trong build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (VoucherService.instance.availableVouchers.isEmpty) {
        VoucherService.instance.loadAvailable();
      }
      // Luôn load lại để đảm bảo trạng thái "đã thu thập" từ server là chính xác
      VoucherService.instance.loadMyVouchers();
    });
  }

  @override
  void dispose() {
    VoucherService.instance.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() {
    if (!mounted) return;
    // Khi load xong lần đầu (loading kết thúc), đánh dấu
    if (!VoucherService.instance.isLoading) {
      _doneFirstLoad = true;
    }
    setState(() {});
  }

  List<Voucher> get _vouchers {
    // Chỉ hiện voucher chưa thu thập, ẩn voucher đã lưu
    return VoucherService.instance.availableVouchers
        .where((v) => !VoucherService.instance.hasCollected(v.id))
        .toList();
  }

  Future<void> _collect(Voucher v) async {
    if (VoucherService.instance.hasCollected(v.id)) {
      AppNotification.show(context,
          message: 'Bạn đã thu thập voucher này rồi!', type: NotifType.warning);
      return;
    }
    final ok = await VoucherService.instance.collectVoucher(v);
    if (!mounted) return;
    if (ok) {
      AppNotification.show(context,
          title: 'Thu thập thành công! 🎉',
          message: 'Voucher "${v.title}" đã được lưu vào túi của bạn.',
          type: NotifType.success);
    } else {
      AppNotification.show(context,
          message: 'Không thể lưu voucher. Vui lòng thử lại.',
          type: NotifType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc       = VoucherService.instance;
    final isLoading = svc.isLoading;
    final errorMsg  = svc.error;
    final vouchers  = _vouchers;

    // Đang tải lần đầu → hiện shimmer
    if (isLoading && vouchers.isEmpty) {
      return _buildShimmer();
    }

    // DEBUG: hiện lỗi trực tiếp trên màn hình khi chưa có data
    if (kDebugMode && errorMsg != null && vouchers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('⚠️ Voucher load error (debug only):',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
          const SizedBox(height: 4),
          Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 11)),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => svc.loadAvailable(force: true),
            child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
          ),
        ]),
      );
    }

    // Không có data (và không phải debug) → ẩn section
    if (vouchers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Expanded(
              child: Text('🎟️ Voucher hôm nay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyVouchersView()))
                  .then((_) => setState(() {})),
              child: Text('Xem tất cả',
                  style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vouchers.length,
            itemBuilder: (_, i) => _VoucherCard(
              voucher: vouchers[i],
              collected: VoucherService.instance.hasCollected(vouchers[i].id),
              onCollect: () => _collect(vouchers[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('🎟️ Voucher hôm nay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              width: 230,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}


// ─── Voucher Card (horizontal) ────────────────────────────────────────────────
class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final bool collected;
  final VoidCallback onCollect;

  const _VoucherCard({
    required this.voucher,
    required this.collected,
    required this.onCollect,
  });

  Color get _bgColor {
    if (voucher.discountPercent >= 25) return const Color(0xFFFF6B35);
    if (voucher.discountPercent >= 15) return const Color(0xFF6C63FF);
    return const Color(0xFF2ECC71);
  }

  @override
  Widget build(BuildContext context) {
    final color = _bgColor;
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        // Decorative circle
        Positioned(right: -20, top: -20,
          child: Container(width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1)))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('-${voucher.discountPercent.toInt()}%',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(height: 6),
              Text(voucher.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(voucher.restaurantName, maxLines: 1,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        voucher.isUnlimited
                            ? 'Không giới hạn lượt'
                            : 'Còn ${voucher.remainingQuantity} lượt',
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('HSD: ${voucher.daysLeft} ngày',
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                )),
                GestureDetector(
                  onTap: onCollect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: collected ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(collected ? 'Đã lưu' : 'Thu thập',
                        style: TextStyle(
                          color: collected ? Colors.white : color,
                          fontWeight: FontWeight.w700, fontSize: 11,
                        )),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
