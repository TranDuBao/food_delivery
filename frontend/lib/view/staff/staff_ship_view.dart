// lib/view/staff/staff_ship_view.dart
// Tab Ship — Màn hình Giao hàng (Delivery Pool)
// Option B: Mỗi tòa nhà = 1 chuyến giao riêng biệt
import 'dart:async';
import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class StaffShipView extends StatefulWidget {
  const StaffShipView({super.key});

  @override
  State<StaffShipView> createState() => _StaffShipViewState();
}

class _StaffShipViewState extends State<StaffShipView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _readyItems = [];
  Map<String, dynamic>? _activeTrip;   // chuyến đang giao (null = không có)
  bool _loading = true;
  // key = maToaNha (String), value = đang gọi API
  final Map<String, bool> _startingMap = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final [readyRes, tripRes] = await Future.wait([
        ServiceCall.fetchGet(SVKey.svStaffReadyItems, isToken: true),
        ServiceCall.fetchGet(SVKey.svStaffActiveTrip, isToken: true),
      ]);
      if (!mounted) return;
      setState(() {
        if (readyRes is Map && readyRes['success'] == true)
          _readyItems = (readyRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (tripRes is Map && tripRes['success'] == true)
          _activeTrip = tripRes['data'] != null ? Map<String, dynamic>.from(tripRes['data'] as Map) : null;
      });
    } catch (_) {}
    if (mounted && !silent) setState(() => _loading = false);
  }

  /// Bắt đầu giao cho 1 tòa nhà cụ thể
  Future<void> _startTripForBuilding(int maToaNha, String tenToaNha) async {
    final key = maToaNha.toString();
    setState(() => _startingMap[key] = true);
    try {
      final res = await ServiceCall.fetchPost(
        SVKey.svStaffStartTrip,
        body: {'maToaNha': maToaNha},
        isToken: true,
      );
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🚀 ${res['message'] ?? 'Đã bắt đầu chuyến giao!'}'),
          backgroundColor: Colors.green,
        ));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _startingMap.remove(key));
    }
  }

  Future<void> _completeTrip(int tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✅ Hoàn tất chuyến giao', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn đã giao tất cả món trong chuyến này cho khách chưa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Chưa xong')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn tất!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      Globs.showHUD(status: 'Đang cập nhật...');
      final res = await ServiceCall.fetchPut(SVKey.svStaffCompleteTrip(tripId), isToken: true);
      Globs.hideHUD();
      if (res is Map && res['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Hoàn tất! Khách đã nhận hàng.'), backgroundColor: Colors.green),
        );
        await _load();
      }
    } catch (e) {
      Globs.hideHUD();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🚚 Giao hàng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh_rounded, color: TColor.primary), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _buildReadyPoolView(),
            ),
    );
  }

  Future<void> _swipeDeliveryItem(int maChiTietDonHang, Map<String, dynamic> item) async {
    // Optimistic UI update
    setState(() {
      _readyItems.removeWhere((element) => element['maChiTiet'] == maChiTietDonHang);
    });

    try {
      final res = await ServiceCall.fetchPut(
        SVKey.svStaffCompleteItem(maChiTietDonHang), // Need to add this to globs.dart
        isToken: true,
      );
      if (res is Map && res['success'] == true) {
        // Success
      } else {
        // Revert
        _load(silent: true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')));
      }
    } catch (e) {
      _load(silent: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // ── View 2: Quầy chờ giao (nhóm theo từng tòa nhà) ───────────────────────────
  Widget _buildReadyPoolView() {
    if (_readyItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(children: [
              Icon(Icons.delivery_dining_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Chưa có món nào sẵn sàng', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Khi bếp hoàn thành món, chúng sẽ xuất hiện ở đây', style: TextStyle(color: Colors.grey.shade400, fontSize: 13), textAlign: TextAlign.center),
            ]),
          ),
        ],
      );
    }

    // Nhóm theo tòa nhà (key = maToaNha, value = danh sách món)
    // Mỗi nhóm sẽ có nút "Giao tòa này" riêng
    final Map<String, List<Map<String, dynamic>>> groupedByBuilding = {};
    for (final item in _readyItems) {
      final maToaNha = item['maToaNha']?.toString() ?? '0';
      groupedByBuilding.putIfAbsent(maToaNha, () => []).add(item);
    }

    final totalItems = _readyItems.length;
    final totalBuildings = groupedByBuilding.length;

    return Column(children: [
      // Banner tóm tắt
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.green.shade50,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.kitchen_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Quầy chờ giao', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green)),
            Text('$totalItems phần ăn · $totalBuildings tòa nhà đang chờ', style: const TextStyle(fontSize: 12, color: Colors.green)),
          ])),
        ]),
      ),

      // Danh sách từng tòa — mỗi tòa có nút "Giao tòa này"
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...groupedByBuilding.entries.map((e) => _buildBuildingGroup(e.key, e.value)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ]);
  }

  Widget _buildBuildingGroup(String maToaNhaStr, List<Map<String, dynamic>> items) {
    final maToaNha = int.tryParse(maToaNhaStr) ?? 0;
    // Lấy tên tòa từ món đầu tiên
    final tenToaNha = items.first['tenToaNha']?.toString() ?? 'Tòa ?';
    final isStarting = _startingMap[maToaNhaStr] == true;

    // Nhóm tiếp theo phòng
    final Map<String, List<Map<String, dynamic>>> byRoom = {};
    for (final item in items) {
      final room = item['tenPhong']?.toString() ?? '';
      byRoom.putIfAbsent(room, () => []).add(item);
    }

    final allDelivering = items.every((item) => item['trangThaiMon'] == 'delivering');
    final isButtonDisabled = isStarting || allDelivering;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.07), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header tòa nhà
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.apartment_rounded, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tenToaNha,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.green)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
              child: Text('${items.length} món', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        // Danh sách phòng + món
        ...byRoom.entries.map((roomEntry) => _buildRoomSection(roomEntry.key, roomEntry.value)),

        // Nút "Giao tòa này"
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isButtonDisabled ? Colors.grey : TColor.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: isButtonDisabled ? 0 : 2,
              ),
              onPressed: isButtonDisabled ? null : () => _startTripForBuilding(maToaNha, tenToaNha),
              icon: isStarting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
              label: Text(
                isStarting ? 'Đang tạo chuyến...' : (allDelivering ? 'Đang giao $tenToaNha' : 'Giao $tenToaNha (${items.length} món)'),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRoomSection(String tenPhong, List<Map<String, dynamic>> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(tenPhong, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        ]),
      ),
      ...items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        final imgUrl = item['hinhAnh']?.toString() ?? '';
        final isDelivering = item['trangThaiMon'] == 'delivering';
        final maChiTiet = int.tryParse(item['maChiTiet']?.toString() ?? '') ?? 0;

        Widget content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDelivering ? Colors.orange.shade50 : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: isLast ? Colors.transparent : Colors.grey.shade100),
            ),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl.startsWith('http') ? imgUrl : '${SVKey.nodeUrl}${imgUrl.startsWith('/') ? '' : '/'}$imgUrl', 
                      width: 42, height: 42, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['tenMonAn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(item['tenKhach']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if ((item['soDienThoai']?.toString() ?? '').isNotEmpty)
                Row(children: [
                  Icon(Icons.phone_outlined, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(item['soDienThoai']!.toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ]),
              const SizedBox(height: 2),
              () {
                final daPay = item['trangThaiThanhToan']?.toString() == 'paid';
                final tongTien = item['tongTien'];
                final phuongThuc = item['phuongThucThanhToan']?.toString() ?? 'COD';
                if (daPay) {
                  return Row(children: [
                    Icon(Icons.check_circle, size: 11, color: Colors.green.shade600),
                    const SizedBox(width: 3),
                    Text('Đã thanh toán ($phuongThuc)', style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                  ]);
                } else {
                  final amount = tongTien is num ? tongTien.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') : '0';
                  return Row(children: [
                    Icon(Icons.payments_outlined, size: 11, color: Colors.orange.shade700),
                    const SizedBox(width: 3),
                    Text('Thu: ${amount}đ', style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                  ]);
                }
              }(),
              if (isDelivering)
                 Text('Vuốt để đánh dấu đã giao', style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontStyle: FontStyle.italic)),
            ])),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: isDelivering ? Colors.orange.shade100 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(isDelivering ? Icons.delivery_dining_rounded : Icons.check_circle_rounded, color: isDelivering ? Colors.orange : Colors.green, size: 18),
            ),
          ]),
        );

        if (isDelivering) {
          return Dismissible(
            key: ValueKey('ship_item_$maChiTiet'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _swipeDeliveryItem(maChiTiet, item),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.blue.shade400,
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
            ),
            child: content,
          );
        }
        return content;
      }),
    ]);
  }

  Widget _imgPlaceholder() => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
    child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 20),
  );
}
