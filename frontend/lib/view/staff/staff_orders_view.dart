import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/app_alert.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

enum _OrderTab { pending, completed }

class StaffOrdersView extends StatefulWidget {
  final VoidCallback? onNavigateToPrepare;

  const StaffOrdersView({super.key, this.onNavigateToPrepare});

  @override
  State<StaffOrdersView> createState() => _StaffOrdersViewState();
}

class _StaffOrdersViewState extends State<StaffOrdersView> {
  _OrderTab _selectedTab = _OrderTab.pending;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final Set<int> _processingIds = {};
  DateTimeRange? _filterDateRange;
  
  Timer? _pollingTimer;
  int _lastOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders(isFirst: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadOrders(silent: true);
    });
  }

  Future<void> _loadOrders({bool silent = false, bool isFirst = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderStaffPending,
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        final newOrders = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Đếm số đơn đang ở trạng thái pending/choXacNhan
        final newPendingCount = newOrders.where((o) {
          final status = o['trangThaiDonHang']?.toString().toLowerCase() ?? '';
          return ['pending', 'choxacnhan'].contains(status);
        }).length;

        // Phát thông báo âm thanh nếu có đơn mới xuất hiện
        if (!isFirst && newPendingCount > _lastOrderCount) {
          SystemSound.play(SystemSoundType.click);
          Future.delayed(const Duration(milliseconds: 250), () {
            SystemSound.play(SystemSoundType.click);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white),
                    SizedBox(width: 10),
                    Text('🔔 CÓ ĐƠN HÀNG MỚI ĐẶT TRÊN APP!'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        _lastOrderCount = newPendingCount;

        setState(() {
          _orders = newOrders;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đơn: $e')),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markReady(int maDonHang) async {
    if (_processingIds.contains(maDonHang)) return;
    setState(() => _processingIds.add(maDonHang));
    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderMarkReady(maDonHang),
        isToken: true,
      );
      if (!mounted) return;
      if (response is Map && response['success'] == true) {
        AppAlert.show(context, message: 'Đã báo xong! Hệ thống sẽ kiểm tra nhóm giao hàng.');
        await _loadOrders();
      } else {
        AppAlert.show(context, message: response?['message']?.toString() ?? 'Có lỗi xảy ra.', type: 'error');
      }
    } catch (e) {
      if (mounted) {
        AppAlert.show(context, message: e.toString(), type: 'error');
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(maDonHang));
    }
  }

  Future<void> _startPreparing(int maDonHang) async {
    if (_processingIds.contains(maDonHang)) return;
    setState(() => _processingIds.add(maDonHang));
    try {
      final response = await ServiceCall.fetchPut(
        SVKey.svOrderStartPreparing(maDonHang),
        isToken: true,
      );
      if (!mounted) return;
      if (response is Map && response['success'] == true) {
        setState(() {
          _orders.removeWhere((o) => o['maDonHang'] == maDonHang);
          _processingIds.remove(maDonHang);
        });
        widget.onNavigateToPrepare?.call();
      } else {
        AppAlert.show(context, message: response?['message']?.toString() ?? 'Có lỗi xảy ra.', type: 'error');
      }
    } catch (e) {
      if (mounted) {
        AppAlert.show(context, message: e.toString(), type: 'error');
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(maDonHang));
    }
  }

  Future<void> _startPreparingGroup(List<int> orderIds, int maNhom) async {
    if (_processingIds.contains(-maNhom)) return;
    setState(() => _processingIds.add(-maNhom));
    try {
      for (int maDonHang in orderIds) {
        await ServiceCall.fetchPut(
          SVKey.svOrderStartPreparing(maDonHang),
          isToken: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _orders.removeWhere(
          (o) => o['maNhomGiaoHang'] == maNhom || orderIds.contains(o['maDonHang']),
        );
        _processingIds.remove(-maNhom);
      });
      widget.onNavigateToPrepare?.call();
    } catch (e) {
      if (mounted) {
        AppAlert.show(context, message: e.toString(), type: 'error');
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(-maNhom));
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final filtered = _orders.where((o) {
      final status = o['trangThaiDonHang']?.toString().toLowerCase() ?? '';
      switch (_selectedTab) {
        case _OrderTab.pending:
          return ['pending', 'choxacnhan'].contains(status);
        case _OrderTab.completed:
          if (!['delivered', 'dagiao', 'chogiao', 'chogiaohang'].contains(status)) return false;
          if (_filterDateRange != null) {
            final raw = o['thoiGianDat']?.toString() ?? '';
            try {
              final dt = DateTime.parse(raw).toLocal();
              // End date is inclusive up to 23:59:59
              final endWithTime = DateTime(_filterDateRange!.end.year, _filterDateRange!.end.month, _filterDateRange!.end.day, 23, 59, 59);
              if (dt.isBefore(_filterDateRange!.start) || dt.isAfter(endWithTime)) {
                return false;
              }
            } catch (_) {}
          }
          return true;
      }
    }).toList();

    if (_selectedTab == _OrderTab.pending) {
      final Map<int, Map<String, dynamic>> groups = {};
      final List<Map<String, dynamic>> result = [];

      for (var o in filtered) {
        if (o['trangThaiDonHang'] == 'choXacNhan' && o['maNhomGiaoHang'] != null) {
          final maNhom = int.tryParse(o['maNhomGiaoHang'].toString()) ?? 0;
          if (!groups.containsKey(maNhom)) {
            groups[maNhom] = {
              'isGroup': true,
              'maNhomGiaoHang': maNhom,
              'toaNha': o['tenToaNha'] ?? o['toaNha'],
              'orderIds': <int>[],
              'dishes': <String>[],
              'tongTien': 0.0,
              'trangThaiDonHang': 'choXacNhan',
            };
          }
          
          groups[maNhom]!['orderIds'].add(o['maDonHang']);
          
          final num total = _parseNum(o['tongTien'] ?? o['total'] ?? 0);
          groups[maNhom]!['tongTien'] += total;
          
          final rawDishes = o['danhSachMon']?.toString() ?? '';
          if (rawDishes.isNotEmpty) {
            groups[maNhom]!['dishes'].addAll(rawDishes.split(',').map((s) => s.trim()));
          }
        } else {
          result.add(o);
        }
      }
      
      for (var group in groups.values) {
        final dishes = group['dishes'] as List<String>;
        final Map<String, int> dishCounts = {};
        for (var d in dishes) {
           final match = RegExp(r'(.*?)(?:\s+x(\d+))?$').firstMatch(d);
           if (match != null) {
             final name = match.group(1)?.trim() ?? d;
             final qty = int.tryParse(match.group(2) ?? '1') ?? 1;
             dishCounts[name] = (dishCounts[name] ?? 0) + qty;
           } else {
             dishCounts[d] = (dishCounts[d] ?? 0) + 1;
           }
        }
        final combinedDishes = dishCounts.entries.map((e) => '${e.key} x${e.value}').join(', ');
        group['danhSachMon'] = combinedDishes;
        result.add(group);
      }
      return result;
    }

    return filtered;
  }

  String _tabLabel(_OrderTab tab) {
    switch (tab) {
      case _OrderTab.pending:
        return 'Đang xử lý';
      case _OrderTab.completed:
        return 'Đã giao';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Staff Orders Management',
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
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: _OrderTab.values.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? TColor.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: TColor.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          _tabLabel(tab),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF888888),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (_selectedTab == _OrderTab.completed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Text('Lọc theo thời gian:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                  const Spacer(),
                  TextButton.icon(
                    icon: Icon(Icons.date_range_rounded, size: 18, color: TColor.primary),
                    label: Text(_filterDateRange == null 
                      ? 'Tất cả ngày' 
                      : '${_filterDateRange!.start.day}/${_filterDateRange!.start.month} - ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}',
                      style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _filterDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: TColor.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (range != null) {
                        setState(() => _filterDateRange = range);
                      }
                    },
                  ),
                  if (_filterDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () => setState(() => _filterDateRange = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                ],
              ),
            ),

          // Order list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: _selectedTab == _OrderTab.completed
                            ? _buildGroupedCompletedList(filtered)
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) =>
                                    _buildOrderCard(filtered[index]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Không có đơn nào',
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

  // ── Group completed orders by date+hour ──────────────────────────
  Widget _buildGroupedCompletedList(List<Map<String, dynamic>> orders) {
    // Group by "dd/MM HH:00"
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final o in orders) {
      final raw = o['thoiGianDat']?.toString() ?? '';
      String label = 'Không rõ thời gian';
      try {
        final dt = DateTime.parse(raw).toLocal();
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final hour = dt.hour.toString().padLeft(2, '0');
        label = '$day/$month — $hour:00 – $hour:59';
      } catch (_) {}
      groups.putIfAbsent(label, () => []).add(o);
    }

    final keys = groups.keys.toList(); // already sorted desc from backend
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTimeGroupCard(keys[i], groups[keys[i]]!),
    );
  }

  Widget _buildTimeGroupCard(String label, List<Map<String, dynamic>> orders) {
    final totalRevenue = orders.fold<double>(
        0, (sum, o) => sum + _parseNum(o['tongTien'] ?? o['total'] ?? 0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.access_time_rounded, color: TColor.primary, size: 20),
          ),
          title: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${orders.length} đơn',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatCurrency(totalRevenue)}đ',
                  style: TextStyle(
                      fontSize: 12, color: TColor.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          children: orders
              .map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildCompactOrderCard(o),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(Map<String, dynamic> order) {
    final tenKhach = order['tenKhach']?.toString() ?? 'Khách hàng';
    final tenToaNha = order['tenToaNha']?.toString() ?? '';
    final tenPhong = order['tenPhong']?.toString() ?? '';
    final dishes = order['danhSachMon']?.toString() ?? '';
    final total = _parseNum(order['tongTien'] ?? order['total'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenKhach,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A)),
                ),
                if (tenToaNha.isNotEmpty || tenPhong.isNotEmpty)
                  Text(
                    'Tòa $tenToaNha · Phòng $tenPhong',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                Text(
                  dishes,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${_formatCurrency(total)}đ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TColor.primary),
          ),
        ],
      ),
    );
  }

  double _parseNum(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? 0;
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isGroup = order['isGroup'] == true;
    final maDonHang = int.tryParse(order['maDonHang']?.toString() ?? '') ?? 0;
    final maNhom = int.tryParse(order['maNhomGiaoHang']?.toString() ?? '') ?? 0;
    final loaiDonHang = order['loaiDonHang']?.toString() ?? '';
    final isDineIn = loaiDonHang == 'dineIn';
    final soBanAn = order['soBanAn'];
    final tenKhachDineIn = order['tenKhachDineIn']?.toString();

    final tenKhach = isDineIn 
        ? (tenKhachDineIn ?? order['tenKhach']?.toString() ?? 'Khách ăn tại bàn')
        : (order['tenKhach']?.toString() ?? 'Khách hàng');
        
    final isProcessing = _processingIds.contains(isGroup ? -maNhom : maDonHang);
    final isNew = _selectedTab == _OrderTab.pending;

    final phuongThuc = order['phuongThucThanhToan']?.toString() ?? 'COD';
    final trangThaiTT = order['trangThaiThanhToan']?.toString() ?? 'pending';
    final daPay = trangThaiTT == 'paid';

    // Build header: tên khách · tòa · phòng
    final locationPart = isDineIn
        ? ' (Ăn tại bàn)'
        : ((order['tenToaNha']?.toString() ?? '').isNotEmpty || (order['tenPhong']?.toString() ?? '').isNotEmpty)
            ? ' · ${order['tenToaNha']} - Phòng ${order['tenPhong']}'
            : '';
    final headerText = isGroup 
        ? 'Đơn ghép nhóm #$maNhom - ${order['toaNha']}' 
        : '$tenKhach$locationPart';

    // Parse dish list
    final rawDishes = order['danhSachMon']?.toString() ?? '';
    final dishes = rawDishes.isNotEmpty
        ? rawDishes.split(',').map((s) => s.trim()).toList()
        : <String>[];

    // Tổng số phần ăn (parse số lượng từ chuỗi "Tên món x{sl}")
    int tongPhan = 0;
    for (final d in dishes) {
      final match = RegExp(r'x(\d+)$').firstMatch(d.trim());
      tongPhan += match != null ? (int.tryParse(match.group(1) ?? '1') ?? 1) : 1;
    }
    if (tongPhan == 0) tongPhan = 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        headerText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Mới',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isDineIn)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BÀN ${soBanAn?.toString().padLeft(2, '0') ?? '??'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: daPay ? Colors.green.shade800 : Colors.red.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daPay ? 'ĐÃ THANH TOÁN ($phuongThuc)' : 'CHƯA THANH TOÁN ($phuongThuc)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          // Dish list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: dishes.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dishes
                        .map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                d,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF333333)),
                              ),
                            ))
                        .toList(),
                  )
                : Text(rawDishes,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333))),
          ),


          // Total + Payment + Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng $tongPhan phần ăn',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (_selectedTab == _OrderTab.pending)
                  if (order['trangThaiDonHang'] == 'choXacNhan')
                    _buildActionButton(
                      label: isProcessing ? 'Đang xử lý...' : 'Xác nhận đơn',
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : () {
                        if (isGroup) {
                          _startPreparingGroup(order['orderIds'] as List<int>, maNhom);
                        } else {
                          _startPreparing(maDonHang);
                        }
                      },
                      color: Colors.blue,
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isLoading,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey : (color ?? TColor.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  String _formatCurrency(dynamic val) {
    final num v = _parseNum(val);
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
