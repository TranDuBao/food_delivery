import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

// ─── Helper parse tên||SĐT ───────────────────────────────────────────────────
Map<String, String> _parseKhach(String? raw) {
  if (raw == null || raw.isEmpty) return {'name': 'Khách', 'phone': ''};
  final parts = raw.split('||');
  return {'name': parts[0].trim(), 'phone': parts.length > 1 ? parts[1].trim() : ''};
}

String _fmtMoney(dynamic v) {
  final n = double.tryParse(v?.toString() ?? '0') ?? 0;
  return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

// ─── Main View ───────────────────────────────────────────────────────────────
class StaffDineInView extends StatefulWidget {
  const StaffDineInView({super.key});
  @override
  State<StaffDineInView> createState() => _StaffDineInViewState();
}

class _StaffDineInViewState extends State<StaffDineInView> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  Timer? _timer;
  int _lastPending = 0;

  @override
  void initState() {
    super.initState();
    _load(first: true);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false, bool first = false}) async {
    if (!silent) {
      if (mounted) setState(() => _loading = true);
    }
    try {
      final res = await ServiceCall.fetchGet(SVKey.svDineInTableOrders, isToken: true);
      if (res is Map && res['success'] == true) {
        final data = (res['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final np = data.where((o) => o['trangThaiDonHang'] == 'choXacNhan').length;
        if (!first && np > _lastPending && mounted) {
          SystemSound.play(SystemSoundType.click);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🔔 Có đơn tại bàn mới!'),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 4),
          ));
        }
        _lastPending = np;
        if (mounted) setState(() => _orders = data);
      }
    } catch (_) {} finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _pending =>
      _orders.where((o) => o['trangThaiDonHang'] == 'choXacNhan').toList();
  List<Map<String, dynamic>> get _preparing =>
      _orders.where((o) => o['trangThaiDonHang'] == 'dangChuanBi').toList();
  List<Map<String, dynamic>> get _done =>
      _orders.where((o) => ['choGiaoHang','delivered','daGiao'].contains(o['trangThaiDonHang'])).toList();

  void _openDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        onChanged: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Quản lý Bàn Ăn',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1A1A1A))),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: TColor.primary),
              onPressed: _load,
            )
          ],
          bottom: TabBar(
            indicatorColor: TColor.primary,
            labelColor: TColor.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: [
              Tab(text: 'Chờ (${_pending.length})'),
              Tab(text: 'Đang làm (${_preparing.length})'),
              Tab(text: 'Xong (${_done.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(_pending),
                  _buildList(_preparing),
                  _buildList(_done),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.table_restaurant_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Không có đơn nào', style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> order) {
    final ban = (order['soBanAn']?.toString() ?? '?').padLeft(2, '0');
    final khach = _parseKhach(order['tenKhach']?.toString());
    final trangThai = order['trangThaiDonHang']?.toString() ?? '';
    final danhSach = order['danhSachMon']?.toString() ?? '';
    final tongTien = order['tongTien'];
    final trangThaiTT = order['trangThaiThanhToan']?.toString() ?? 'pending';
    final thoiGian = order['thoiGianDat']?.toString() ?? '';

    Color stColor;
    String stLabel;
    switch (trangThai) {
      case 'choXacNhan': stColor = Colors.orange; stLabel = 'Chờ xác nhận'; break;
      case 'dangChuanBi': stColor = Colors.blue; stLabel = 'Đang làm'; break;
      default: stColor = Colors.green; stLabel = 'Hoàn thành';
    }

    return GestureDetector(
      onTap: () => _openDetail(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: TColor.primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(7)),
                child: Row(children: [
                  const Icon(Icons.table_restaurant, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text('BÀN $ban', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(khach['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
                if (khach['phone']!.isNotEmpty)
                  Row(children: [
                    Icon(Icons.phone, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(khach['phone']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: stColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(stLabel, style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (danhSach.isNotEmpty)
                Text(danhSach, style: const TextStyle(fontSize: 12, color: Color(0xFF555555)), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Text(_fmtMoney(tongTien), style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: trangThaiTT == 'paid' ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trangThaiTT == 'paid' ? 'Đã TT' : 'Chưa TT',
                      style: TextStyle(color: trangThaiTT == 'paid' ? Colors.green.shade700 : Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                Row(children: [
                  if (thoiGian.isNotEmpty) Text(_fmtTime(thoiGian), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmtTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

// ─── Order Detail Bottom Sheet ────────────────────────────────────────────────
class _OrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Future<void> Function() onChanged;
  const _OrderDetailSheet({required this.order, required this.onChanged});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final Set<int> _deleting = {};

  int get _orderId => int.tryParse(widget.order['maDonHang']?.toString() ?? '') ?? 0;
  String get _trangThai => widget.order['trangThaiDonHang']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svDineInTableOrderDetail(_orderId), isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map;
        final rawItems = data['items'] as List? ?? [];
        setState(() => _items = rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeItem(int chiTietId) async {
    setState(() => _deleting.add(chiTietId));
    try {
      final res = await ServiceCall.fetchDelete(
        SVKey.svDineInRemoveItem(_orderId, chiTietId), isToken: true);
      if (res is Map && res['success'] == true) {
        await _loadDetail();
        await widget.onChanged();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _deleting.remove(chiTietId));
    }
  }

  Future<void> _startOrder() async {
    final res = await ServiceCall.fetchPut(SVKey.svDineInStartOrder(_orderId), isToken: true);
    if (res is Map && res['success'] == true) {
      await widget.onChanged();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _doneOrder() async {
    final res = await ServiceCall.fetchPut(SVKey.svDineInDoneOrder(_orderId), isToken: true);
    if (res is Map && res['success'] == true) {
      await widget.onChanged();
      if (mounted) Navigator.pop(context);
    }
  }

  void _openAddDish() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DishPickerSheet(
        orderId: _orderId,
        onAdded: () async { await _loadDetail(); await widget.onChanged(); },
      ),
    );
  }

  double get _total => _items.fold(0, (s, i) => s + (double.tryParse(i['soLuong']?.toString() ?? '0') ?? 0) * (double.tryParse(i['giaTien']?.toString() ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    final khach = _parseKhach(widget.order['tenKhach']?.toString());
    final ban = (widget.order['soBanAn']?.toString() ?? '?').padLeft(2, '0');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(8)),
                child: Text('BÀN $ban', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(khach['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (khach['phone']!.isNotEmpty)
                  Row(children: [
                    Icon(Icons.phone, size: 12, color: TColor.primary),
                    const SizedBox(width: 4),
                    Text(khach['phone']!, style: TextStyle(fontSize: 12, color: TColor.primary, fontWeight: FontWeight.w600)),
                  ]),
              ])),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1),
          // Items list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text('Chưa có món nào', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        controller: ctrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final chiTietId = int.tryParse(item['maChiTietDonHang']?.toString() ?? '') ?? 0;
                          final qty = int.tryParse(item['soLuong']?.toString() ?? '1') ?? 1;
                          final price = double.tryParse(item['giaTien']?.toString() ?? '0') ?? 0;
                          final isDel = _deleting.contains(chiTietId);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            title: Text(item['tenMonAn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('x$qty • ${_fmtMoney(price)}/món', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_fmtMoney(qty * price), style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(width: 8),
                              isDel
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : GestureDetector(
                                      onTap: () => _removeItem(chiTietId),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                      ),
                                    ),
                            ]),
                          );
                        },
                      ),
          ),
          // Total + buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(_fmtMoney(_total), style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w800, fontSize: 17)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAddDish,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm món'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColor.primary,
                      side: BorderSide(color: TColor.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_trangThai == 'choXacNhan')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startOrder,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Bắt đầu làm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (_trangThai == 'dangChuanBi')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _doneOrder,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Dish Picker Sheet ────────────────────────────────────────────────────────
class _DishPickerSheet extends StatefulWidget {
  final int orderId;
  final Future<void> Function() onAdded;
  const _DishPickerSheet({required this.orderId, required this.onAdded});
  @override
  State<_DishPickerSheet> createState() => _DishPickerSheetState();
}

class _DishPickerSheetState extends State<_DishPickerSheet> {
  List<Map<String, dynamic>> _dishes = [];
  bool _loading = true;
  String _search = '';
  final Set<int> _adding = {};

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svDineInStaffMenu, isToken: true);
      if (res is Map && res['success'] == true) {
        setState(() => _dishes = (res['data'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDish(int maMonAn) async {
    setState(() => _adding.add(maMonAn));
    try {
      final res = await ServiceCall.fetchPost(
        SVKey.svDineInAddItem(widget.orderId),
        body: {'maMonAn': maMonAn, 'soLuong': 1},
        isToken: true,
      );
      if (res is Map && res['success'] == true) {
        await widget.onAdded();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Đã thêm món!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _adding.remove(maMonAn));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _dishes.where((d) {
      if (_search.isEmpty) return true;
      return d['tenMonAn']?.toString().toLowerCase().contains(_search.toLowerCase()) == true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              const Text('Chọn món thêm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Tìm món...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final id = int.tryParse(d['maMonAn']?.toString() ?? '') ?? 0;
                      final isAdding = _adding.contains(id);
                      return Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: d['hinhAnh'] != null && d['hinhAnh'].toString().isNotEmpty
                                ? Image.network(d['hinhAnh'], width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200,
                                        child: const Icon(Icons.restaurant, color: Colors.grey)))
                                : Container(width: 50, height: 50, color: Colors.grey.shade200,
                                    child: const Icon(Icons.restaurant, color: Colors.grey)),
                          ),
                          title: Text(d['tenMonAn']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(_fmtMoney(d['giaTien']), style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          trailing: isAdding
                              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
                              : GestureDetector(
                                  onTap: () => _addDish(id),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
