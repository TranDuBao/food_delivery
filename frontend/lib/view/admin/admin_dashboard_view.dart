// lib/view/admin/admin_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import 'admin_main_view.dart';
import 'manage_stores_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});
  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _byStore = [];
  bool _loading = true;
  // 0=bar, 1=area, 2=pie
  int _chartType = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ServiceCall.fetchGet(SVKey.svAdminDashboard, isToken: true),
        ServiceCall.fetchGet(SVKey.svAdminMonthlyStats, isToken: true),
        ServiceCall.fetchGet(SVKey.svAdminRevenueByStore, isToken: true),
      ]);
      final d = results[0];
      if (d is Map && d['success'] == true) {
        final data = d['data'];
        if (data is Map) {
          final s = data['stats'];
          _stats = s is Map ? Map<String, dynamic>.from(s) : {};
        }
      }
      final m = results[1];
      if (m is Map && m['success'] == true) {
        _monthly = (m['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      final r = results[2];
      if (r is Map && r['success'] == true) {
        _byStore = (r['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
  String _fmt(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  void _navigateTo(int tab) {
    final main = context.findAncestorStateOfType<AdminMainViewState>();
    main?.navigateToTab(tab);
  }

  void _showOrdersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OrdersSheet(),
    );
  }

  void _showRevenueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RevenueSheet(byStore: _byStore, total: _d(_stats['tongDoanhThu'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('📊 Dashboard Admin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A2E))),
        backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final ok = await showDialog<bool>(context: context,
                builder: (_) => AlertDialog(title: const Text('Đăng xuất?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)))],
                ));
              if (ok == true && context.mounted) ServiceCall.logout();
            }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
                const Text('Tổng quan hệ thống', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                // Stat grid
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
                  children: [
                    _StatCard('Tài khoản', '${_stats['tongTaiKhoan'] ?? 0}',
                        Icons.people_rounded, const Color(0xFF6C63FF), onTap: () => _navigateTo(2)),
                    _StatCard('Gian hàng', '${_stats['tongGianHang'] ?? 0}',
                        Icons.store_rounded, const Color(0xFF2ECC71), onTap: () => _navigateTo(1)),
                    _StatCard('Đơn hàng', '${_stats['tongDonHang'] ?? 0}',
                        Icons.receipt_long_rounded, const Color(0xFFFF6B35), onTap: _showOrdersSheet),
                    _StatCard('Doanh thu', '${_fmt(_d(_stats['tongDoanhThu']))}đ',
                        Icons.attach_money_rounded, const Color(0xFFE74C3C), onTap: _showRevenueSheet),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart header + type selector
                if (_monthly.isNotEmpty) ...[
                  Row(children: [
                    const Expanded(child: Text('📈 Doanh thu 6 tháng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                    _chartBtn(Icons.bar_chart_rounded, 0),
                    _chartBtn(Icons.area_chart_rounded, 1),
                    _chartBtn(Icons.pie_chart_rounded, 2),
                  ]),
                  const SizedBox(height: 10),
                  _buildChart(),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
    );
  }

  Widget _chartBtn(IconData icon, int type) => IconButton(
    icon: Icon(icon, size: 20, color: _chartType == type ? const Color(0xFF6C63FF) : Colors.grey),
    onPressed: () => setState(() => _chartType = type),
    padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
  );

  Widget _buildChart() {
    if (_chartType == 2) return _PieChartWidget(data: _monthly);
    if (_chartType == 1) return _AreaChartWidget(data: _monthly);
    return _BarChartWidget(data: _monthly);
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard(this.label, this.value, this.icon, this.color, {this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (onTap != null) Text('Xem ›', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          ])),
        ]),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _BarChartWidget({required this.data});
  double _d(dynamic v) { if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  String _fmt(double v) { if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M'; if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}K'; return v.toStringAsFixed(0); }
  @override
  Widget build(BuildContext context) {
    final max = data.fold<double>(0, (p, e) { final v = _d(e['doanhThu']); return v > p ? v : p; });
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))]),
      height: 160,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((e) {
          final v = _d(e['doanhThu']);
          final ratio = max > 0 ? v / max : 0.0;
          final month = (e['thang']?.toString() ?? '').length >= 7 ? e['thang'].toString().substring(5) : e['thang']?.toString() ?? '';
          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(_fmt(v), style: const TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 4),
            AnimatedContainer(duration: const Duration(milliseconds: 600), width: 28, height: 90 * ratio.toDouble(),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)], begin: Alignment.bottomCenter, end: Alignment.topCenter), borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Text('T$month', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
          ]);
        }).toList()),
    );
  }
}

// ── Area Chart ────────────────────────────────────────────────────────────────
class _AreaChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _AreaChartWidget({required this.data});
  double _d(dynamic v) { if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _d(e.value['doanhThu']))).toList();
    return Container(
      height: 160, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))]),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final i = v.toInt(); if (i < 0 || i >= data.length) return const SizedBox();
            final s = data[i]['thang']?.toString() ?? '';
            return Text(s.length >= 7 ? 'T${s.substring(5)}' : s, style: const TextStyle(fontSize: 9));
          }, reservedSize: 22)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: const Color(0xFF6C63FF), barWidth: 3,
          belowBarData: BarAreaData(show: true, color: const Color(0xFF6C63FF).withValues(alpha: 0.15)),
          dotData: FlDotData(show: false))],
      )),
    );
  }
}

// ── Pie Chart ─────────────────────────────────────────────────────────────────
class _PieChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _PieChartWidget({required this.data});
  double _d(dynamic v) { if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (p, e) => p + _d(e['doanhThu']));
    final colors = [const Color(0xFF6C63FF), const Color(0xFF2ECC71), Colors.orange, Colors.red, Colors.teal, Colors.pink];
    return Container(
      height: 200, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))]),
      child: Row(children: [
        Expanded(child: PieChart(PieChartData(
          sections: data.asMap().entries.map((e) {
            final v = _d(e.value['doanhThu']);
            final pct = total > 0 ? v / total * 100 : 0.0;
            final month = (e.value['thang']?.toString() ?? '').length >= 7 ? 'T${e.value['thang'].toString().substring(5)}' : '';
            return PieChartSectionData(value: v, title: '${pct.toStringAsFixed(0)}%\n$month',
              color: colors[e.key % colors.length], radius: 70, titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700));
          }).toList(),
          sectionsSpace: 2, centerSpaceRadius: 20,
        ))),
      ]),
    );
  }
}

// ── Orders Bottom Sheet ───────────────────────────────────────────────────────
class _OrdersSheet extends StatefulWidget {
  const _OrdersSheet();
  @override
  State<_OrdersSheet> createState() => _OrdersSheetState();
}

class _OrdersSheetState extends State<_OrdersSheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filter = '';

  static const _statuses = ['', 'dangChuanBi', 'choGiaoHang', 'dangGiao', 'daGiao', 'daHuy'];
  static const _labels = ['Tất cả', 'Chuẩn bị', 'Chờ giao', 'Đang giao', 'Đã giao', 'Đã hủy'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final url = _filter.isEmpty ? SVKey.svAdminOrders : '${SVKey.svAdminOrders}?status=$_filter';
      final res = await ServiceCall.fetchGet(url, isToken: true);
      if (res is Map && res['success'] == true) {
        _orders = (res['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _d(dynamic v) { if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  String _fmt(double v) { if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}K'; return v.toStringAsFixed(0); }

  Color _color(String s) {
    switch (s) {
      case 'daGiao': return Colors.green;
      case 'dangChuanBi': return Colors.orange;
      case 'daHuy': return Colors.red;
      case 'choGiaoHang': return Colors.blue;
      case 'dangGiao': return const Color(0xFF6C63FF);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Tất cả đơn hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ])),
          // Filter chips
          SizedBox(height: 40, child: ListView.separated(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statuses.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => FilterChip(
              label: Text(_labels[i], style: const TextStyle(fontSize: 11)),
              selected: _filter == _statuses[i],
              onSelected: (_) { setState(() => _filter = _statuses[i]); _load(); },
              selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF6C63FF),
            ),
          )),
          const SizedBox(height: 8),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
              ? const Center(child: Text('Không có đơn hàng nào.'))
              : ListView.separated(
                  controller: ctrl, padding: const EdgeInsets.fromLTRB(16,0,16,16),
                  itemCount: _orders.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    final status = o['trangThaiDonHang']?.toString() ?? '';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#${o['maDonHang']} — ${o['tenKhach'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${o['tenToaNha'] ?? ''} · ${_fmt(_d(o['tongTien']))}đ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (o['danhSachMon'] != null) Text(o['danhSachMon'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _color(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: TextStyle(fontSize: 10, color: _color(status), fontWeight: FontWeight.w700))),
                      ]),
                    );
                  })),
        ]),
      ),
    );
  }
}

// ── Revenue By Store Sheet ────────────────────────────────────────────────────
class _RevenueSheet extends StatefulWidget {
  final List<Map<String, dynamic>> byStore;
  final double total;
  const _RevenueSheet({required this.byStore, required this.total});

  @override
  State<_RevenueSheet> createState() => _RevenueSheetState();
}

class _RevenueSheetState extends State<_RevenueSheet> {
  late List<Map<String, dynamic>> _list;
  late double _total;
  bool _loading = false;
  String _filter = 'all'; // all, day, month, year

  @override
  void initState() {
    super.initState();
    _list = widget.byStore;
    _total = widget.total;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet('${SVKey.svAdminRevenueByStore}?filter=$_filter', isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as List? ?? [];
        _list = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _total = _list.fold(0.0, (sum, item) => sum + _d(item['doanhThu']));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _d(dynamic v) { if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0; return 0; }
  String _fmt(double v) { if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M'; if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}K'; return v.toStringAsFixed(0); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB), 
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle bar
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          
          // Header
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE74C3C).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE74C3C), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Báo cáo doanh thu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A2E)))),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
                icon: const Icon(Icons.close_rounded, size: 20), 
                onPressed: () => Navigator.pop(context)
              ),
            ])),
          
          const SizedBox(height: 16),

          // Total Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TỔNG DOANH THU', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('${_fmt(_total)}đ', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('ĐƠN HÀNG', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${_list.fold(0, (sum, item) => sum + _d(item['tongDon']).toInt())}', 
                  style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('Lọc theo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _filterChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Hôm nay', 'day'),
                    const SizedBox(width: 8),
                    _filterChip('Tháng này', 'month'),
                    const SizedBox(width: 8),
                    _filterChip('Năm nay', 'year'),
                  ]),
                ),
              ),
            ]),
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // List
          Expanded(child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty 
              ? const Center(child: Text('Không có dữ liệu trong kỳ này'))
              : ListView.separated(
                  controller: ctrl, padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: _list.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = _list[i];
                    final dt = _d(s['doanhThu']);
                    final ratio = _total > 0 ? (dt / _total).clamp(0.0, 1.0) : 0.0;
                    final bannerUrl = s['banner']?.toString() ?? '';
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => StoreStatsSheet(storeId: s['maGianHang'], storeName: s['tenGianHang'] ?? ''),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Row(children: [
                            // Store image
                            Hero(
                              tag: 'store_${s['maGianHang']}',
                              child: Container(width: 52, height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
                                image: bannerUrl.isNotEmpty ? DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover) : null),
                                child: bannerUrl.isEmpty ? const Icon(Icons.store_rounded, color: Color(0xFF6C63FF), size: 26) : null),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s['tenGianHang']?.toString() ?? 'Gian hàng', 
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 6),
                              Stack(children: [
                                Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(3))),
                                FractionallySizedBox(
                                  widthFactor: ratio,
                                  child: Container(height: 6, decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4834D4)]),
                                    borderRadius: BorderRadius.circular(3))),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('${_d(s["tongDon"]).toInt()} đơn', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const Spacer(),
                                Text('${_fmt(dt)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2ECC71))),
                                Text(' (${(ratio*100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ]),
                            ])),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                          ]),
                        ),
                      ),
                    );
                  },
                )),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _load();
        }
      },
      selectedColor: const Color(0xFF1A1A2E),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF1A1A2E) : Colors.grey[300]!),
      showCheckmark: false,
      elevation: isSelected ? 4 : 0,
    );
  }
}
