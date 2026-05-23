import 'package:flutter/material.dart';
import '../../common/app_alert.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common/event_bus.dart';
import 'dart:async';

class StaffKDSView extends StatefulWidget {
  const StaffKDSView({super.key});

  @override
  State<StaffKDSView> createState() => _StaffKDSViewState();
}

class _StaffKDSViewState extends State<StaffKDSView> {
  List<Map<String, dynamic>> _kdsItems = [];
  final Set<String> _expandedKeys = {};
  bool _isLoading = true;
  Timer? _timer;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadKDSData();
    
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadKDSData(silent: true);
    });

    _sub = eventBus.stream.listen((event) {
      if (event == 'order_status_changed') {
        _loadKDSData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadKDSData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderStaffKDS,
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        setState(() {
          _kdsItems = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu KDS: $e')),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _swipeChild(String groupKey, int maChiTietDonHang, int childIndex) async {
    final gIdx = _kdsItems.indexWhere((g) => g['key'] == groupKey);
    if (gIdx < 0) return;

    final group = _kdsItems[gIdx];
    final children = List<Map<String, dynamic>>.from(group['children'] ?? []);
    
    // Optimistic UI Update
    setState(() {
      children[childIndex]['trangThaiMon'] = 'ready';
      group['readyCount'] = (group['readyCount'] as int? ?? 0) + (children[childIndex]['soLuong'] as int? ?? 1);
      group['children'] = children;

      // Nếu tất cả các con đã ready thì ẩn luôn group cha
      final tong = group['tongSoLuong'] as int? ?? 0;
      if (group['readyCount'] >= tong) {
        _kdsItems.removeAt(gIdx);
      }
    });

    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderStaffKDSSwipe(maChiTietDonHang),
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        // Thành công, không cần làm gì thêm, đợi timer load lại cũng được
      } else {
        // Lỗi, revert bằng cách load lại
        _loadKDSData(silent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response is Map ? (response['message']?.toString() ?? 'Lỗi') : 'Lỗi')),
          );
        }
      }
    } catch (e) {
      _loadKDSData(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Chuẩn bị món ăn',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _loadKDSData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kdsItems.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadKDSData,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _kdsItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = _kdsItems[index];
                      return _buildGroupCard(group);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Chưa có món cần nấu',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Kéo xuống để làm mới',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final tenMonAn = group['tenMonAn']?.toString() ?? 'Tên món';
    
    final loaiDonHang = group['loaiDonHang']?.toString() ?? '';
    final isDineIn = loaiDonHang == 'dineIn';
    final soBanAn = group['soBanAn'];
    final tenKhachDineIn = group['tenKhachDineIn']?.toString();

    final tenKhach = isDineIn 
        ? '${tenKhachDineIn ?? 'Khách'} (Bàn ${soBanAn?.toString().padLeft(2, '0') ?? '??'})'
        : (group['tenKhach']?.toString() ?? 'Khách');

    final maDonHang = group['maDonHang']?.toString() ?? '?';
    final hinhAnh = group['hinhAnh']?.toString();
    final tongSoLuong = group['tongSoLuong']?.toString() ?? '0';
    final readyCount = group['readyCount']?.toString() ?? '0';
    final key = group['key']?.toString() ?? '';
    
    final isExpanded = _expandedKeys.contains(key);
    final children = (group['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    // Chỉ lấy các món chưa hoàn thành để hiển thị ở lớp con
    final pendingChildren = children.asMap().entries.where((e) => e.value['trangThaiMon'] != 'ready').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TColor.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lớp Cha (Tóm tắt)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedKeys.remove(key);
                } else {
                  _expandedKeys.add(key);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hinhAnh != null && hinhAnh.isNotEmpty
                        ? Image.network(
                            hinhAnh.startsWith('http') 
                                ? hinhAnh 
                                : '${SVKey.nodeUrl}${hinhAnh.startsWith('/') ? '' : '/'}$hinhAnh',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenMonAn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tenKhach,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.fastfood_rounded, size: 14, color: TColor.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Tiến độ: $readyCount/$tongSoLuong',
                              style: TextStyle(
                                fontSize: 13,
                                color: TColor.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown icon
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Lớp Con (Danh sách chi tiết)
          if (isExpanded && pendingChildren.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: pendingChildren.map((entry) {
                  final idx = entry.key; // index thực trong mảng children ban đầu
                  final child = entry.value;
                  final maChiTiet = child['maChiTietDonHang'] as int? ?? 0;
                  final note = child['ghiChu']?.toString();
                  final qty = child['soLuong']?.toString() ?? '1';

                  return Dismissible(
                    key: ValueKey('child_$maChiTiet'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _swipeChild(key, maChiTiet, idx),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.green.shade400,
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x$qty',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hoàn thành phần này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                if (note != null && note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ghi chú: $note',
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.grey, size: 20),
                          const Text('Vuốt', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 30),
    );
  }
}
