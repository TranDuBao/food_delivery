import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../common/color_extension.dart';
import '../../common/service_call.dart';
import '../../common/globs.dart';

class StaffStatisticView extends StatefulWidget {
  const StaffStatisticView({super.key});
  @override
  State<StaffStatisticView> createState() => _StaffStatisticViewState();
}

class _StaffStatisticViewState extends State<StaffStatisticView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'day';
  String _selectedChart = 'bar';
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final url = '${SVKey.apiBaseUrl}orders/staff-statistics?period=$_selectedPeriod';
      debugPrint('[Statistics] Fetching: $url');
      final res = await ServiceCall.fetchGet(url, isToken: true);
      debugPrint('[Statistics] Response type: ${res.runtimeType}');
      if (res is Map && res['success'] == true) {
        setState(() { _data = res['data']; });
      } else {
        setState(() => _error = (res is Map ? res['message'] : '$res') ?? 'Lỗi server');
      }
    } catch (e, st) {
      debugPrint('[Statistics] Error: $e\n$st');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _fmt(num v) => NumberFormat.decimalPattern('vi_VN').format(v);

  double _parseNum(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? 0;
  }

  Future<void> _exportPdf() async {
    if (_data == null) return;
    final pdf = pw.Document();
    final rev = _data!['current']['totalRevenue'] ?? 0;
    final ord = _data!['current']['totalOrders'] ?? 0;
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('BAO CAO THONG KE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text('Ky: $_selectedPeriod'),
        pw.SizedBox(height: 8),
        pw.Text('Tong Doanh Thu: ${_fmt(rev)} VND'),
        pw.Text('Tong Don Hang: $ord don'),
        pw.SizedBox(height: 16),
        pw.Text('Chi tiet:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...(_data!['current']['chartData'] as List? ?? []).map((item) =>
          pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${item['label']}: ${_fmt(item['revenue'] ?? 0)} VND - ${item['orders']} don'),
          )
        ),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'ThongKe_$_selectedPeriod.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text('Thống kê', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: TColor.primary)),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent), onPressed: _exportPdf),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TColor.primary,
          labelColor: TColor.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Đơn hàng'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildRevenueTab(), _buildOrdersTab()],
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Lỗi tải dữ liệu', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
    ]),
  );

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Row(children: ['day', 'month', 'year'].map((p) {
        final labels = {'day': 'Ngày', 'month': 'Tháng', 'year': 'Năm'};
        final selected = _selectedPeriod == p;
        return Expanded(child: GestureDetector(
          onTap: () { setState(() => _selectedPeriod = p); _loadData(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? TColor.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(labels[p]!, style: TextStyle(fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade600)),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildRevenueTab() {
    final current = _data!['current'] as Map;
    final perf = _data!['performance'] as Map;
    final rev = (current['totalRevenue'] ?? 0).toDouble();
    final growth = (perf['revenueGrowth'] ?? 0).toDouble();
    final prevRev = (_data!['previous']['totalRevenue'] ?? 0).toDouble();
    final chartData = (current['chartData'] as List?)?.cast<Map>() ?? [];

    return RefreshIndicator(onRefresh: _loadData, child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildPeriodSelector(),
        // Revenue cards
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _statCard('Doanh thu', '${_fmt(rev)}đ',
              Icons.monetization_on_rounded, const Color(0xFF4CAF50),
              growth, 'so kì trước', const Color(0xFFE8F5E9))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Kì trước', '${_fmt(prevRev)}đ',
              Icons.history_rounded, Colors.blueGrey,
              null, null, const Color(0xFFECEFF1))),
          ]),
        ),
        const SizedBox(height: 16),
        // Chart selector
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Biểu đồ tăng trưởng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _selectedChart, isDense: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'bar', child: Text('Cột')),
                  DropdownMenuItem(value: 'line', child: Text('Miền')),
                  DropdownMenuItem(value: 'pie', child: Text('Tròn')),
                ],
                onChanged: (v) { if (v != null) setState(() => _selectedChart = v); },
              )),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Chart
        Container(
          height: 240, margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: _buildChart(chartData),
        ),
        const SizedBox(height: 20),
        // Top dishes
        if ((_data!['topDishes'] as List?)?.isNotEmpty == true) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Món bán chạy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Top ${(_data!['topDishes'] as List).length}',
                style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 8),
          ...(_data!['topDishes'] as List).map((d) => _topDishRow(d)),
        ],
        // Table
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Chi tiết theo thời gian', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
        _buildTable(chartData),
        const SizedBox(height: 40),
      ]),
    ));
  }

  Widget _buildOrdersTab() {
    final current = _data!['current'] as Map;
    final breakdown = _data!['orderBreakdown'] as Map? ?? {};
    final perf = _data!['performance'] as Map;
    final growth = (perf['revenueGrowth'] ?? 0).toDouble();
    final total = _parseNum(breakdown['total'] ?? current['totalOrders'] ?? 0);
    final success = _parseNum(breakdown['success'] ?? 0);
    final cancelled = _parseNum(breakdown['cancelled'] ?? 0);
    final rate = total > 0 ? (success / total * 100) : 0.0;
    final chartData = (current['chartData'] as List?)?.cast<Map>() ?? [];

    return RefreshIndicator(onRefresh: _loadData, child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildPeriodSelector(),
        // 4 stat cards
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child: _statCard('Tổng đơn hàng', '$total',
                Icons.receipt_long_rounded, const Color(0xFF2196F3), growth, 'so kì trước', const Color(0xFFE3F2FD))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Thành công', '$success',
                Icons.check_circle_rounded, const Color(0xFF4CAF50),
                rate.toDouble(), '% tỉ lệ hoàn tất', const Color(0xFFE8F5E9))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('Đã hủy', '$cancelled',
                Icons.cancel_rounded, const Color(0xFFF44336), null, null, const Color(0xFFFFEBEE))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Còn lại', '${total - success - cancelled}',
                Icons.pending_rounded, Colors.orange, null, null, const Color(0xFFFFF3E0))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // Orders chart
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Biểu đồ đơn hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: TColor.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_selectedPeriod == 'day' ? 'Theo giờ' : _selectedPeriod == 'month' ? 'Theo ngày' : 'Theo tháng',
                style: TextStyle(fontSize: 11, color: TColor.primary, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200, margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: _buildOrdersChart(chartData),
        ),
        const SizedBox(height: 40),
      ]),
    ));
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      double? growth, String? growthLabel, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        if (growth != null && growthLabel != null)
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(growth >= 0 ? Icons.trending_up : Icons.trending_down, size: 14,
                color: growth >= 0 ? Colors.green : Colors.red),
              const SizedBox(width: 3),
              Expanded(child: Text('${growth.abs().toStringAsFixed(1)}% $growthLabel',
                style: TextStyle(fontSize: 10, color: growth >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }

  Widget _topDishRow(Map d) {
    final svUrl = SVKey.mainUrl;
    final imgUrl = (d['image'] ?? '').toString();
    final fullUrl = imgUrl.startsWith('http') ? imgUrl : '$svUrl$imgUrl';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: imgUrl.isEmpty
              ? Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey))
              : Image.network(fullUrl, width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, color: Colors.grey)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${d['totalSold']} phần đã bán', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ])),
        Text('${_fmt(d['totalRevenue'] ?? 0)}đ',
          style: TextStyle(fontWeight: FontWeight.w700, color: TColor.primary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildChart(List<Map> chartData) {
    if (chartData.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
    if (_selectedChart == 'pie') return _buildPieChart(chartData);
    final maxY = chartData.map((e) => _parseNum(e['revenue'])).fold(0.0, (a, b) => a > b ? a : b) * 1.3;
    if (_selectedChart == 'line') {
      final spots = chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _parseNum(e.value['revenue']))).toList();
      return LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        titlesData: _titles(chartData), borderData: FlBorderData(show: false),
        minX: 0, maxX: (chartData.length - 1).toDouble(), minY: 0, maxY: maxY == 0 ? 100 : maxY,
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: TColor.primary, barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: TColor.primary.withValues(alpha: 0.15)))],
      ));
    }
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround, maxY: maxY == 0 ? 100 : maxY,
      barTouchData: BarTouchData(enabled: true),
      titlesData: _titles(chartData), borderData: FlBorderData(show: false),
      barGroups: chartData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: _parseNum(e.value['revenue']),
          gradient: LinearGradient(colors: [TColor.primary, TColor.primary.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ])).toList(),
    ));
  }

  Widget _buildPieChart(List<Map> chartData) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    final total = chartData.fold(0.0, (a, b) => a + _parseNum(b['revenue']));
    return PieChart(PieChartData(
      sectionsSpace: 3, centerSpaceRadius: 35,
      sections: chartData.asMap().entries.map((e) {
        final val = _parseNum(e.value['revenue']);
        final pct = total > 0 ? val / total * 100 : 0.0;
        return PieChartSectionData(color: colors[e.key % colors.length],
          value: val,
          title: '${pct.toStringAsFixed(0)}%', radius: 55,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white));
      }).toList(),
    ));
  }

  Widget _buildOrdersChart(List<Map> chartData) {
    if (chartData.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
    final maxY = chartData.map((e) => _parseNum(e['orders'])).fold(0.0, (a, b) => a > b ? a : b) * 1.3;
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround, maxY: maxY == 0 ? 10 : maxY,
      barTouchData: BarTouchData(enabled: true),
      titlesData: _titles(chartData), borderData: FlBorderData(show: false),
      barGroups: chartData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: _parseNum(e.value['orders']),
          color: const Color(0xFF2196F3), width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ])).toList(),
    ));
  }

  FlTitlesData _titles(List<Map> data) => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
      getTitlesWidget: (v, _) {
        final i = v.toInt();
        if (i < 0 || i >= data.length) return const SizedBox();
        return Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(data[i]['label'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)));
      })),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  Widget _buildTable(List<Map> chartData) {
    if (chartData.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: const Row(children: [
            Expanded(flex: 2, child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            Expanded(child: Text('Đơn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('Doanh thu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.end)),
          ])),
        ...chartData.asMap().entries.map((entry) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
            color: entry.key.isEven ? Colors.white : Colors.grey.shade50,
          ),
          child: Row(children: [
            Expanded(flex: 2, child: Text(entry.value['label'].toString(), style: const TextStyle(fontSize: 13))),
            Expanded(child: Text('${entry.value['orders']}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('${_fmt(entry.value['revenue'] ?? 0)}đ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primary), textAlign: TextAlign.end)),
          ]),
        )),
        const SizedBox(height: 4),
      ]),
    );
  }
}
