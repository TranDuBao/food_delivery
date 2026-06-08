import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/app_alert.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../main_tabview/main_tabview.dart';

/// Màn hình thanh toán SePay — hiển thị QR VietQR để chuyển khoản.
/// Tự động polling trạng thái mỗi 5 giây, điều hướng khi thanh toán xong.
class SepayPaymentView extends StatefulWidget {
  final int maDonHang;
  final double amount;
  final String paymentCode;   // Nội dung chuyển khoản, ví dụ: SF12
  final String qrUrl;
  final String accountNumber;
  final String accountName;
  final String bankCode;

  const SepayPaymentView({
    super.key,
    required this.maDonHang,
    required this.amount,
    required this.paymentCode,
    required this.qrUrl,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
  });

  @override
  State<SepayPaymentView> createState() => _SepayPaymentViewState();
}

class _SepayPaymentViewState extends State<SepayPaymentView>
    with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;
  bool _isPaid = false;
  bool _isCancelled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Thời gian chờ thanh toán tối đa (phút)
  static const int _maxWaitMinutes = 15;
  int _elapsedSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bắt đầu polling sau 3 giây
    Future.delayed(const Duration(seconds: 3), _startPolling);
    _startCountdown();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaymentStatus());
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _maxWaitMinutes * 60) {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isPaid || _isCancelled || !mounted) return;
    try {
      final res = await ServiceCall.fetchGet(
        '${SVKey.svPaymentStatus(widget.maDonHang)}',
        isToken: true,
      );
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map? ?? {};
        final trangThai = data['trangThai']?.toString() ?? '';
        if (trangThai == 'success' || data['trangThaiThanhToan'] == 'paid') {
          _onPaymentSuccess();
        }
      }
    } catch (_) {}
  }

  void _onPaymentSuccess() {
    if (_isPaid) return;
    _isPaid = true;
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted) return;
    AppAlert.show(context, message: 'Thanh toán thành công! 🎉', type: 'success');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainTabView(initialTab: 1)),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _remainingTime {
    final remaining = _maxWaitMinutes * 60 - _elapsedSeconds;
    if (remaining <= 0) return '00:00';
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: _confirmCancel,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D7EFF), Color(0xFF00C6FF)],
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'SePay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Quét mã thanh toán',
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${widget.maDonHang}',
                  style: TextStyle(
                    color: TColor.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Countdown ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _elapsedSeconds < _maxWaitMinutes * 60
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _elapsedSeconds < _maxWaitMinutes * 60
                      ? Colors.orange.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 18,
                      color: _elapsedSeconds < _maxWaitMinutes * 60
                          ? Colors.orange.shade700
                          : Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    'Thời gian còn lại: $_remainingTime',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _elapsedSeconds < _maxWaitMinutes * 60
                          ? Colors.orange.shade800
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── QR Card ────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header QR
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D7EFF), Color(0xFF00C6FF)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'Quét QR để thanh toán',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.amount.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // QR Image
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.qrUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF0D7EFF),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Không tải được QR',
                                    style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Thông tin tài khoản
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFF)),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Ngân hàng', widget.bankCode),
                        const SizedBox(height: 8),
                        _infoRow('Số tài khoản', widget.accountNumber,
                            canCopy: true),
                        const SizedBox(height: 8),
                        _infoRow('Chủ tài khoản', widget.accountName),
                        const SizedBox(height: 8),
                        _infoRow('Số tiền',
                            '${widget.amount.toStringAsFixed(0)} VND'),
                        const SizedBox(height: 8),
                        _infoRow('Nội dung CK', widget.paymentCode,
                            canCopy: true, highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hướng dẫn ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade800, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Lưu ý quan trọng',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _noteItem('Quét QR bằng app ngân hàng hoặc nhập tay thông tin.'),
                  _noteItem(
                      'Nhập đúng nội dung "${widget.paymentCode}" để hệ thống tự xác nhận.'),
                  _noteItem('Đơn sẽ tự động cập nhật trong vài giây sau khi chuyển thành công.'),
                  _noteItem('Không tắt màn hình này khi đang chờ xác nhận.'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Trạng thái polling ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TColor.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang chờ xác nhận thanh toán...',
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Nút xác nhận thủ công ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isPaid ? null : () async {
                  // Thử check DB trước
                  await _checkPaymentStatus();
                  if (_isPaid) return;

                  // Nếu vẫn chưa → gọi manual-confirm (cho môi trường dev/localhost)
                  try {
                    final res = await ServiceCall.fetchPost(
                      SVKey.svPaymentManualConfirm,
                      isToken: true,
                      body: {'maDonHang': widget.maDonHang},
                    );
                    if (res is Map && res['success'] == true) {
                      _onPaymentSuccess();
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message']?.toString() ??
                              'Chưa ghi nhận. Vui lòng chờ...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lỗi kết nối. Thử lại sau...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Tôi đã chuyển khoản — Xác nhận'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: TColor.primary),
                  foregroundColor: TColor.primary,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool canCopy = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlight ? TColor.primary : TColor.primaryText,
                fontSize: highlight ? 14 : 13,
                fontWeight:
                    highlight ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 14, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _noteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.amber.shade900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thoát thanh toán?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Đơn hàng đã được tạo. Bạn có thể thanh toán lại sau trong mục "Đơn hàng của tôi".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ở lại',
                style: TextStyle(
                    color: TColor.primary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _isCancelled = true;
      Navigator.of(context).pop();
    }
  }
}
