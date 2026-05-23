import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_notification.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';

// ─── Staff Voucher Management View ───────────────────────────────────────────
class StaffVoucherView extends StatefulWidget {
  const StaffVoucherView({super.key});

  @override
  State<StaffVoucherView> createState() => _StaffVoucherViewState();
}

class _StaffVoucherViewState extends State<StaffVoucherView> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ServiceCall.fetchGet(SVKey.svStaffPromotions, isToken: true);
      if (data is List) {
        setState(() {
          _vouchers = data.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context,
            message: 'Không tải được danh sách voucher.', type: NotifType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForm({Map<String, dynamic>? edit}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherFormSheet(existing: edit),
    );
    if (result == null) return;

    try {
      if (edit != null) {
        await ServiceCall.fetchPut(
          SVKey.svStaffUpdatePromotion(edit['id']),
          body: result,
          isToken: true,
        );
        if (mounted) {
          AppNotification.show(context,
              message: 'Cập nhật voucher thành công!', type: NotifType.success);
        }
      } else {
        await ServiceCall.fetchPost(
          SVKey.svStaffCreatePromotion,
          body: result,
          isToken: true,
        );
        if (mounted) {
          AppNotification.show(context,
              title: 'Đã tạo voucher! 🎉',
              message: 'Voucher "${result['title']}" đã được thêm.',
              type: NotifType.success);
        }
      }
      await _load();
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, message: e.toString(), type: NotifType.error);
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> v) async {
    final ok = await AppNotification.confirm(context,
        title: 'Xoá voucher',
        message: 'Xoá voucher "${v['title']}"?',
        confirmText: 'Xoá',
        cancelText: 'Huỷ');
    if (ok != true) return;
    try {
      await ServiceCall.fetchDelete(
          SVKey.svStaffDeletePromotion(v['id']), isToken: true);
      await _load();
      if (mounted) {
        AppNotification.show(context,
            message: 'Đã xoá voucher.', type: NotifType.info);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, message: e.toString(), type: NotifType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Quản lý Voucher',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: TColor.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo mới'),
              style: TextButton.styleFrom(foregroundColor: TColor.primary),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _vouchers.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.local_offer_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Chưa có voucher nào',
                            style: TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tạo voucher đầu tiên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vouchers.length,
                      itemBuilder: (_, i) => _StaffVoucherCard(
                        voucher: _vouchers[i],
                        onEdit: () => _openForm(edit: _vouchers[i]),
                        onDelete: () => _delete(_vouchers[i]),
                      ),
                    ),
            ),
      floatingActionButton: _vouchers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo voucher',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ─── Voucher Card (Staff side) ────────────────────────────────────────────────
class _StaffVoucherCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffVoucherCard({
    required this.voucher,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isExpired {
    final raw = voucher['endsAt'] ?? voucher['ends_at'];
    if (raw == null) return false;
    final dt = DateTime.tryParse(raw.toString());
    return dt != null && dt.isBefore(DateTime.now());
  }

  int get _daysLeft {
    final raw = voucher['endsAt'] ?? voucher['ends_at'];
    if (raw == null) return 0;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return 0;
    return dt.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _isExpired;
    final color = isExpired ? Colors.grey : TColor.primary;
    final discount = double.tryParse(
            voucher['discountPercent']?.toString() ?? '0')?.toInt() ?? 0;
    final title   = voucher['title']?.toString() ?? '';
    final code    = voucher['code']?.toString() ?? '-';
    final isActive = voucher['isActive'] == true || voucher['isActive'] == 1;
    final dishName = voucher['dishName']?.toString();
    final maxUses  = voucher['maxUses'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: discount chip + title + status
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('-$discount%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            if (isExpired || !isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(isExpired ? 'Hết hạn' : 'Đã tắt',
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 10),

          // Info chips row 1: code + expiry
          Wrap(spacing: 16, runSpacing: 6, children: [
            _InfoChip(Icons.confirmation_number_outlined, 'Mã: $code', color),
            _InfoChip(Icons.timer_outlined,
                isExpired ? 'Đã hết hạn' : 'Còn $_daysLeft ngày',
                isExpired ? Colors.red : Colors.orange),
          ]),
          const SizedBox(height: 6),

          // Info chips row 2: dish scope + max uses
          Wrap(spacing: 16, runSpacing: 6, children: [
            _InfoChip(
              Icons.restaurant_menu_rounded,
              dishName != null ? '🍽 $dishName' : '🍽 Tất cả món',
              Colors.teal,
            ),
            _InfoChip(
              Icons.people_alt_outlined,
              maxUses != null ? '$maxUses lượt' : 'Không giới hạn',
              Colors.indigo,
            ),
          ]),

          const SizedBox(height: 12),
          // Action buttons
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Sửa',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.primary,
                side: BorderSide(color: TColor.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Xoá',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);
}

// ─── Create / Edit Form ───────────────────────────────────────────────────────
class _VoucherFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _VoucherFormSheet({this.existing});

  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _maxUsesCtrl;
  DateTime? _endsAt;

  // Dish picker
  List<Map<String, dynamic>> _dishes = [];
  int? _selectedDishId;     // null = áp dụng tất cả
  bool _loadingDishes = true;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _titleCtrl   = TextEditingController(text: v?['title']?.toString() ?? '');
    _codeCtrl    = TextEditingController(
        text: v?['code']?.toString() ?? _genCode());
    _discountCtrl = TextEditingController(
        text: v?['discountPercent']?.toString() ?? '');
    _maxUsesCtrl  = TextEditingController(
        text: v?['maxUses']?.toString() ?? '');

    // Pre-select dish if editing
    final rawDishId = v?['dishId'];
    if (rawDishId != null) {
      _selectedDishId = int.tryParse(rawDishId.toString());
    }

    // Parse ngày hết hạn
    final rawEnd = v?['endsAt'] ?? v?['ends_at'];
    if (rawEnd != null) _endsAt = DateTime.tryParse(rawEnd.toString());

    _loadDishes();
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    final now = DateTime.now();
    return List.generate(8,
        (i) => chars[(now.microsecond + i * 7) % chars.length]).join();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  /// Load danh sách món ăn của gian hàng để chọn phạm vi áp dụng
  Future<void> _loadDishes() async {
    try {
      final data = await ServiceCall.fetchGet(
          SVKey.svStaffStoreMenu, isToken: true);
      // Response có thể là List hoặc {data: List}
      final raw = data is Map ? (data['data'] ?? data) : data;
      if (raw is List && mounted) {
        setState(() {
          _dishes = raw.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loadingDishes = false;
        });
      } else {
        if (mounted) setState(() => _loadingDishes = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDishes = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: TColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endsAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt == null) {
      AppNotification.show(context,
          message: 'Vui lòng chọn ngày hết hạn!', type: NotifType.warning);
      return;
    }
    final maxUsesText = _maxUsesCtrl.text.trim();
    final payload = <String, dynamic>{
      'title'           : _titleCtrl.text.trim(),
      'code'            : _codeCtrl.text.trim().toUpperCase(),
      'discountPercent' : double.tryParse(_discountCtrl.text.trim()) ?? 0,
      'endsAt'          : _endsAt!.toIso8601String(),
      'isActive'        : true,
      'maMonAn'         : _selectedDishId,  // null = tất cả
      'maxUses'         : maxUsesText.isNotEmpty
                            ? int.tryParse(maxUsesText)
                            : null,
    };
    Navigator.pop(context, payload);
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Text(isEdit ? 'Sửa voucher' : 'Tạo voucher mới',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1),

          // Form body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Tiêu đề ──────────────────────────────────────────
                  TextFormField(
                    controller: _titleCtrl,
                    decoration:
                        _dec('Tiêu đề voucher', hint: 'VD: Giảm 20% cơm gà'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Mã voucher ───────────────────────────────────────
                  TextFormField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _dec('Mã voucher', hint: 'VD: COMGA20'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── % Giảm giá ───────────────────────────────────────
                  TextFormField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('% Giảm giá', hint: '1–100'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0 || n > 100) return 'Nhập 1–100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Giới hạn số lượng ────────────────────────────────
                  TextFormField(
                    controller: _maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Giới hạn số lượng (lượt)',
                        hint: 'Để trống = không giới hạn'),
                  ),
                  const SizedBox(height: 14),

                  // ── Áp dụng cho món ─────────────────────────────────
                  _buildDishPicker(),
                  const SizedBox(height: 14),

                  // ── Ngày hết hạn ─────────────────────────────────────
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            color: _endsAt != null
                                ? TColor.primary
                                : Colors.grey,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _endsAt != null
                              ? 'Hết hạn: ${_endsAt!.day}/${_endsAt!.month}/${_endsAt!.year}'
                              : 'Chọn ngày hết hạn *',
                          style: TextStyle(
                            color: _endsAt != null
                                ? TColor.primaryText
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? 'Cập nhật' : 'Tạo voucher',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDishPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Áp dụng cho món',
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: _loadingDishes
            ? const SizedBox(
                height: 44,
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
            : DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedDishId,
                  isExpanded: true,
                  hint: const Text('Tất cả món trong gian hàng'),
                  items: [
                    // Option "Tất cả"
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Row(children: [
                        Icon(Icons.restaurant_menu_rounded,
                            size: 16, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Tất cả món trong gian hàng',
                            style: TextStyle(fontSize: 13)),
                      ]),
                    ),
                    // Danh sách món cụ thể
                    ..._dishes.map((d) {
                      final id = int.tryParse(
                              d['maMonAn']?.toString() ?? '');
                      final name = d['tenMonAn']?.toString() ??
                          d['name']?.toString() ?? '?';
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Row(children: [
                          const Icon(Icons.fastfood_rounded,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedDishId = v),
                ),
              ),
      ),
      if (!_loadingDishes && _dishes.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text('Chưa có món nào trong thực đơn.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ),
    ]);
  }
}
