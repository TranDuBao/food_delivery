// lib/view/admin/manage_stores_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageStoresView extends StatefulWidget {
  const ManageStoresView({super.key});
  @override
  State<ManageStoresView> createState() => _ManageStoresViewState();
}

class _ManageStoresViewState extends State<ManageStoresView> {
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAdminStores, isToken: true);
      if (res is Map && res['success'] == true) {
        setState(() => _stores = (res['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _safeDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _safeInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  // ── Toggle khóa/mở gian hàng ─────────────────────────────────────
  Future<void> _toggleStatus(Map<String, dynamic> store) async {
    final current = _safeInt(store['trangThai']);
    final newStatus = current == 1 ? 0 : 1;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(newStatus == 0 ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: newStatus == 0 ? Colors.orange : Colors.green, size: 22),
          const SizedBox(width: 8),
          Text(newStatus == 0 ? 'Khóa gian hàng' : 'Mở gian hàng',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (newStatus == 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gian hàng sẽ bị ẩn khỏi danh sách và tất cả món ăn sẽ không hiển thị.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          Text('Bạn có chắc muốn ${newStatus == 0 ? "khóa" : "mở"} gian hàng "${store['tenGianHang']}"?'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 0 ? Colors.orange : Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus == 0 ? 'Khóa' : 'Mở',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ServiceCall.fetchPut(SVKey.svAdminUpdateStore(store['maGianHang']),
          isToken: true, body: {'trangThai': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(newStatus == 0
                ? '🔒 Đã khóa gian hàng!'
                : '✅ Đã mở gian hàng!')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // ── Upload ảnh banner ────────────────────────────────────────────
  Future<void> _uploadBanner(Map<String, dynamic> store) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    try {
      final url = await ServiceCall.uploadImageFile(
          SVKey.svAdminStoreBanner(store['maGianHang']),
          File(img.path),
          isToken: true);
      if (url != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cập nhật ảnh thành công!')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
      }
    }
  }

  // ── Bottom sheet thống kê gian hàng ──────────────────────────────
  Future<void> _showStats(Map<String, dynamic> store) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreStatsSheet(
        storeId: store['maGianHang'],
        storeName: store['tenGianHang']?.toString() ?? '',
      ),
    );
  }

  // ── Dialog tạo gian hàng mới ─────────────────────────────────────
  void _showCreateDialog() {
    final tenGHCtrl = TextEditingController();
    final moTaCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final hoTenCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🏪 Tạo Gian hàng mới',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(tenGHCtrl, 'Tên gian hàng *'),
            _field(moTaCtrl, 'Mô tả'),
            const Divider(height: 20),
            const Text('Tài khoản Nhân viên',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            _field(usernameCtrl, 'Tên đăng nhập *'),
            _field(passCtrl, 'Mật khẩu *', obscure: true),
            _field(hoTenCtrl, 'Họ tên nhân viên'),
            _field(emailCtrl, 'Email'),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              if (tenGHCtrl.text.isEmpty ||
                  usernameCtrl.text.isEmpty ||
                  passCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Vui lòng điền đầy đủ thông tin bắt buộc (*).')));
                return;
              }
              try {
                final res = await ServiceCall.fetchPost(SVKey.svAdminStores,
                    isToken: true,
                    body: {
                      'tenGianHang': tenGHCtrl.text.trim(),
                      'moTa': moTaCtrl.text.trim(),
                      'tenDangNhap': usernameCtrl.text.trim(),
                      'matKhau': passCtrl.text,
                      'hoTen': hoTenCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                    });
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res is Map && res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Tạo gian hàng thành công!')));
                  _load();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          res is Map ? (res['message'] ?? 'Lỗi') : 'Lỗi')));
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
          {bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      );

  // ── Card gian hàng ───────────────────────────────────────────────
  Widget _buildStoreCard(Map<String, dynamic> s) {
    final isActive = _safeInt(s['trangThai']) == 1;
    final tongDon = _safeInt(s['tongDon']);
    final doanhThu = _safeDouble(s['doanhThu']);
    final bannerUrl = s['hinhAnh']?.toString() ?? '';
    final Color themeColor =
        isActive ? const Color(0xFF2ECC71) : Colors.orange;

    return GestureDetector(
      onTap: () => _showStats(s),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.orange.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.black : Colors.orange)
                  .withValues(alpha: isActive ? 0.05 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: [
          // Banner bị khóa
          if (!isActive)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded, color: Colors.orange, size: 13),
                SizedBox(width: 6),
                Text('Gian hàng đang bị khóa - Ẩn khỏi danh sách',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Ảnh gian hàng + nút upload
              Stack(children: [
                GestureDetector(
                  onTap: () => _uploadBanner(s),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: bannerUrl.isNotEmpty
                        ? Image.network(bannerUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60, height: 60,
                              color: themeColor.withValues(alpha: 0.1),
                              child: Icon(Icons.store_rounded, color: themeColor, size: 28)))
                        : Container(
                            width: 60, height: 60,
                            color: themeColor.withValues(alpha: 0.1),
                            child: Icon(Icons.store_rounded, color: themeColor, size: 28)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _uploadBanner(s),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 11),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 12),
              // Thông tin
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['tenGianHang']?.toString() ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isActive
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '👤 ${s['tenChuQuan'] ?? 'Chưa có'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '📦 $tongDon đơn  •  💰 ${_fmtMoney(doanhThu)}đ',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ]),
              ),
              // Switch + tap for stats
              Column(children: [
                Switch(
                  value: isActive,
                  activeColor: const Color(0xFF2ECC71),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => _toggleStatus(s),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.bar_chart_rounded,
                    size: 18, color: Color(0xFF6C63FF)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('🏪 Quản lý Gian hàng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          IconButton(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _stores.isEmpty
                  ? const Center(child: Text('Chưa có gian hàng nào.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _stores.length,
                      itemBuilder: (_, i) => _buildStoreCard(_stores[i]),
                    ),
            ),
    );
  }
}

// ── Bottom Sheet Thống kê ────────────────────────────────────────────
class StoreStatsSheet extends StatefulWidget {
  final dynamic storeId;
  final String storeName;
  const StoreStatsSheet({required this.storeId, required this.storeName});

  @override
  State<StoreStatsSheet> createState() => _StoreStatsSheetState();
}

class _StoreStatsSheetState extends State<StoreStatsSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _filter = 'month'; // 'day', 'month', 'year'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(
          '${SVKey.svAdminStoreStats(widget.storeId)}?filter=$_filter',
          isToken: true);
      if (res is Map && res['success'] == true) {
        setState(() => _data = Map<String, dynamic>.from(res['data'] as Map));
      } else {
        setState(() => _error = 'Không tải được dữ liệu.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  double _safeDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _safeInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Row(children: [
          const Icon(Icons.bar_chart_rounded,
              color: Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.storeName,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
        const Divider(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          )
        else if (_data != null)
          _buildContent(),
      ]),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final tongDon = _safeInt(d['tongDon']);
    final tongDoanhThu = _safeDouble(d['tongDoanhThu']);
    final soMonAn = _safeInt(d['soMonAn']);
    final diem = _safeDouble(d['diemTrungBinh']);
    final tongDG = _safeInt(d['tongDanhGia']);
    final bannerUrl = d['banner']?.toString() ?? '';
    final chartData = (d['chartData'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Filter Chips
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('Theo Ngày', 'day'),
          const SizedBox(width: 8),
          _filterChip('Theo Tháng', 'month'),
          const SizedBox(width: 8),
          _filterChip('Theo Năm', 'year'),
        ],
      ),
      const SizedBox(height: 16),
      
      // Chart
      if (chartData.isNotEmpty) ...[
        Container(
          height: 180,
          padding: const EdgeInsets.only(right: 16, top: 10),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= chartData.length) return const SizedBox();
                      // Chỉ hiện 1 vài label nếu quá nhiều (vd theo ngày)
                      if (chartData.length > 7 && index % (chartData.length ~/ 4) != 0) return const SizedBox();
                      return Text(chartData[index]['label'].toString(), style: const TextStyle(fontSize: 9, color: Colors.grey));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(_fmtMoney(value), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _safeDouble(e.value['doanhThu']))).toList(),
                  isCurved: true,
                  color: const Color(0xFF6C63FF),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: const Color(0xFF6C63FF).withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Stat cards
      Row(children: [
        _statCard('📦', 'Đơn hàng', tongDon.toString(), const Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        _statCard('💰', 'Doanh thu', '${_fmtMoney(tongDoanhThu)}đ', const Color(0xFF2ECC71)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statCard('🍽️', 'Món ăn', soMonAn.toString(), Colors.orange),
        const SizedBox(width: 10),
        _statCard('⭐', 'Đánh giá', '$diem ($tongDG)', Colors.amber),
      ]),
      const SizedBox(height: 10),
    ]);
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _load();
        }
      },
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.grey[200],
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _statCard(String emoji, String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      );
}
