import 'package:flutter/material.dart';
import '../../common/app_alert.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class CanteenOrderManagementView extends StatefulWidget {
  const CanteenOrderManagementView({super.key});

  @override
  State<CanteenOrderManagementView> createState() => _CanteenOrderManagementViewState();
}

class _CanteenOrderManagementViewState extends State<CanteenOrderManagementView> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  Set<int> markingIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderStaffPending,
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        setState(() {
          orders = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đơn: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markDone(int maDonHang) async {
    if (markingIds.contains(maDonHang)) return;
    setState(() => markingIds.add(maDonHang));

    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderMarkReady(maDonHang),
        isToken: true,
      );

      if (!mounted) return;

      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã báo xong! Hệ thống sẽ kiểm tra nhóm giao hàng.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message']?.toString() ?? 'Có lỗi xảy ra.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => markingIds.remove(maDonHang));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: Text(
          'Đơn cần chuẩn bị',
          style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'Không có đơn nào cần chuẩn bị.',
                        style: TextStyle(color: TColor.secondaryText, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kéo xuống để làm mới.',
                        style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final order = orders[index];
                      final maDonHang = order['maDonHang'] as int? ?? 0;
                      final isMarking = markingIds.contains(maDonHang);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TColor.textfield,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TColor.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Địa chỉ giao
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, color: TColor.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Tòa ${order['toaNha']} · ${order['tang']} · Phòng ${order['phong']}',
                                  style: TextStyle(
                                    color: TColor.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Khách hàng
                            Row(
                              children: [
                                Icon(Icons.person_outline, color: TColor.secondaryText, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  order['tenKhach']?.toString() ?? 'Khách hàng',
                                  style: TextStyle(color: TColor.primaryText, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Danh sách món
                            Text(
                              order['danhSachMon']?.toString() ?? '',
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Nút done
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMarking ? Colors.grey : Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: isMarking ? null : () => _markDone(maDonHang),
                                icon: isMarking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: Text(
                                  isMarking ? 'Đang xử lý...' : 'Đã làm xong',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
