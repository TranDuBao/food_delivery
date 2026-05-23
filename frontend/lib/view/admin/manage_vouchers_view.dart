// lib/view/admin/manage_vouchers_view.dart
import 'package:flutter/material.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ManageVouchersView extends StatefulWidget {
  const ManageVouchersView({super.key});
  @override
  State<ManageVouchersView> createState() => _ManageVouchersViewState();
}

class _ManageVouchersViewState extends State<ManageVouchersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _allVouchers = [];
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String _searchQuery = '';

  static int _safeInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _safeDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  List<Map<String, dynamic>> get _filteredVouchers {
    if (_searchQuery.isEmpty) return _allVouchers;
    return _allVouchers.where((v) {
      final code = v['code']?.toString().toLowerCase() ?? '';
      final title = v['title']?.toString().toLowerCase() ?? '';
      return code.contains(_searchQuery.toLowerCase()) || title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _adminVouchers =>
      _filteredVouchers.where((v) => v['nguonVoucher'] == 'admin').toList();
  List<Map<String, dynamic>> get _storeVouchers =>
      _filteredVouchers.where((v) => v['nguonVoucher'] == 'store' || v['nguonVoucher'] == null).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ServiceCall.fetchGet(SVKey.svAdminVouchers, isToken: true),
        ServiceCall.fetchGet(SVKey.svAdminStoresList, isToken: true),
      ]);
      final vRes = results[0];
      final sRes = results[1];
      if (vRes is Map && vRes['success'] == true) {
        _allVouchers = (vRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (sRes is Map && sRes['success'] == true) {
        _stores = (sRes['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteVoucher(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🚫 Vô hiệu hóa voucher'),
        content: const Text('Voucher sẽ bị vô hiệu hóa và ẩn khỏi khách hàng.\nBạn có thể kích hoạt lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vô hiệu hóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ServiceCall.fetchDelete(SVKey.svAdminDeleteVoucher(id), isToken: true);
      _load();
    } catch (_) {}
  }

  Future<void> _toggleActive(Map<String, dynamic> v) async {
    final current = v['isActive'];
    final newVal = (current is bool) ? !current : current == 1 ? 0 : 1;
    try {
      await ServiceCall.fetchPut(SVKey.svAdminUpdateVoucher(v['id']),
          isToken: true,
          body: {'isActive': newVal is bool ? (newVal ? 1 : 0) : newVal});
      _load();
    } catch (_) {}
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final maxUseCtrl = TextEditingController();
    DateTime? selectedEndDate;
    bool applyAll = true;
    final Set<int> selectedStoreIds = {};
    String storeSearch = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final filteredStores = _stores.where((s) => (s['tenGianHang']?.toString() ?? '').toLowerCase().contains(storeSearch.toLowerCase())).toList();
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🎟️ Tạo Voucher Admin', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field(codeCtrl, 'Mã voucher (VD: KM50)'),
                  _field(titleCtrl, 'Tiêu đề'),
                  _field(descCtrl, 'Mô tả ngắn'),
                  Row(children: [
                    Expanded(child: _field(percentCtrl, 'Giảm (%)', type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(maxUseCtrl, 'Lượt dùng', type: TextInputType.number)),
                  ]),
                  
                  ListTile(
                    title: Text(selectedEndDate == null ? 'Chọn ngày kết thúc' : 'Hết hạn: ${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}'),
                    leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6C63FF)),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) setD(() => selectedEndDate = picked);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                    dense: true,
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const Align(alignment: Alignment.centerLeft, child: Text('Phạm vi áp dụng:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                  RadioListTile<bool>(
                    title: const Text('Tất cả quán (Toàn sàn)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: true, groupValue: applyAll,
                    onChanged: (v) => setD(() => applyAll = v!),
                    activeColor: const Color(0xFF6C63FF),
                    contentPadding: EdgeInsets.zero, dense: true,
                    secondary: const Icon(Icons.public_rounded, color: Colors.blue, size: 20),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Chọn quán cụ thể', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: false, groupValue: applyAll,
                    onChanged: (v) => setD(() => applyAll = v!),
                    activeColor: const Color(0xFF6C63FF),
                    contentPadding: EdgeInsets.zero, dense: true,
                    secondary: const Icon(Icons.store_rounded, color: Colors.orange, size: 20),
                  ),
                  if (!applyAll) ...[
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setD(() => storeSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Tìm tên quán...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true, fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: EdgeInsets.zero, isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (filteredStores.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Không tìm thấy quán phù hợp.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredStores.length,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 40),
                          itemBuilder: (_, i) {
                            final s = filteredStores[i];
                            final id = _safeInt(s['maGianHang']);
                            final isSel = selectedStoreIds.contains(id);
                            return InkWell(
                              onTap: () => setD(() => isSel ? selectedStoreIds.remove(id) : selectedStoreIds.add(id)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(children: [
                                  Icon(isSel ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isSel ? const Color(0xFF6C63FF) : Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(s['tenGianHang'] ?? '', style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500))),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (codeCtrl.text.isEmpty || titleCtrl.text.isEmpty || percentCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin.')));
                    return;
                  }
                  if (!applyAll && selectedStoreIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất một quán.')));
                    return;
                  }
                  try {
                    await ServiceCall.fetchPost(SVKey.svAdminVouchers, isToken: true, body: {
                      'code': codeCtrl.text.trim().toUpperCase(),
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'discountPercent': double.tryParse(percentCtrl.text) ?? 0,
                      'maxUses': int.tryParse(maxUseCtrl.text),
                      'endsAt': selectedEndDate?.toIso8601String(),
                      'maGianHangList': applyAll ? [] : selectedStoreIds.toList(),
                    });
                    Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: const Text('Tạo ngay', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> voucher) {
    final titleCtrl = TextEditingController(text: voucher['title']?.toString());
    final descCtrl = TextEditingController(text: voucher['description']?.toString());
    final percentCtrl = TextEditingController(text: _safeDouble(voucher['discountPercent']).toString());
    final maxUseCtrl = TextEditingController(text: voucher['maxUses']?.toString());
    DateTime? selectedEndDate = voucher['endsAt'] != null ? DateTime.tryParse(voucher['endsAt'].toString()) : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('✏️ Sửa voucher: ${voucher['code']}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(titleCtrl, 'Tiêu đề'),
              _field(descCtrl, 'Mô tả'),
              Row(children: [
                Expanded(child: _field(percentCtrl, 'Giảm (%)', type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(maxUseCtrl, 'Lượt dùng', type: TextInputType.number)),
              ]),
              ListTile(
                title: Text(selectedEndDate == null ? 'Chọn ngày kết thúc' : 'Hết hạn: ${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}'),
                leading: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedEndDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setD(() => selectedEndDate = picked);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ServiceCall.fetchPut(SVKey.svAdminUpdateVoucher(voucher['id']), isToken: true, body: {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'discountPercent': double.tryParse(percentCtrl.text) ?? 0,
                    'maxUses': int.tryParse(maxUseCtrl.text),
                    'endsAt': selectedEndDate?.toIso8601String(),
                  });
                  Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? type}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c, keyboardType: type,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    ),
  );

  Widget _buildVoucherList(List<Map<String, dynamic>> vouchers, {bool isAdminTab = false}) {
    if (vouchers.isEmpty) return const Center(child: Text('Không tìm thấy voucher nào.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final v = vouchers[i];
        final isActive = v['isActive'] == true || v['isActive'] == 1;
        final isAdmin = v['nguonVoucher'] == 'admin';
        final color = isAdmin ? const Color(0xFF6C63FF) : const Color(0xFF2ECC71);
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(v['code'] ?? '', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
              ),
              const Spacer(),
              Switch(value: isActive, onChanged: (_) => _toggleActive(v), activeColor: color),
            ]),
            const SizedBox(height: 8),
            Text(v['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(v['moTa'] ?? v['description'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 10),
            Row(children: [
              _infoTag(Icons.storefront_rounded, v['maGianHang'] == null ? 'Toàn sàn' : (v['canteenName'] ?? 'Cửa hàng')),
              const SizedBox(width: 8),
              _infoTag(Icons.percent_rounded, '${_safeDouble(v['discountPercent']).toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _infoTag(Icons.event_available_rounded, _fmtDate(v['endsAt'])),
            ]),
            const Divider(height: 24),
            Row(children: [
              Text('Đã dùng: ${_safeInt(v['soLuotLuu'])} / ${v['maxUses'] ?? '∞'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () => _showEditDialog(v)),
              IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red), onPressed: () => _deleteVoucher(v['id'])),
            ]),
          ]),
        );
      },
    );
  }

  Widget _infoTag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.grey[700]),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[800], fontWeight: FontWeight.w600)),
    ]),
  );

  String _fmtDate(dynamic d) {
    if (d == null) return 'Không hết hạn';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return d.toString();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Quản lý Voucher', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm voucher...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF6C63FF), unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6C63FF),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Admin (${_adminVouchers.length})'),
                Tab(text: 'Gian hàng (${_storeVouchers.length})'),
              ],
            ),
          ]),
        ),
        actions: [
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add_box_rounded, color: Color(0xFF6C63FF), size: 28)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabCtrl,
        children: [
          _buildVoucherList(_adminVouchers, isAdminTab: true),
          _buildVoucherList(_storeVouchers),
        ],
      ),
    );
  }
}
