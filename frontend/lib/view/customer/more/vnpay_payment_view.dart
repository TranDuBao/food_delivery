import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../common/app_alert.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import 'area_orders_view.dart';
import '../main_tabview/main_tabview.dart';

/// Màn hình WebView hiển thị cổng thanh toán VNPay
/// Tự động phát hiện URL return và điều hướng về app
class VNPayPaymentView extends StatefulWidget {
  final String payUrl;         // URL thanh toán từ VNPay
  final int maDonHang;
  final String tenToaNha;
  final int maToaNha;

  const VNPayPaymentView({
    super.key,
    required this.payUrl,
    required this.maDonHang,
    required this.tenToaNha,
    required this.maToaNha,
  });

  @override
  State<VNPayPaymentView> createState() => _VNPayPaymentViewState();
}

class _VNPayPaymentViewState extends State<VNPayPaymentView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _handled = false; // tránh xử lý 2 lần

  // URL return backend sẽ redirect về
  static const String _returnUrlPattern = '/api/payment/vnpay-return';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            // Bắt URL /vnpay-return ngay khi bắt đầu load (trước cả trang ngrok warning)
            if (url.contains(_returnUrlPattern)) {
              _handleVnpayReturnUrl(url);
            }
          },
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            // Bắt deep link của app
            if (url.startsWith('shipfood://')) {
              _handleReturnUrl(url);
              return NavigationDecision.prevent;
            }
            // Bắt URL /vnpay-return (trường hợp không dùng deep link)
            if (url.contains(_returnUrlPattern)) {
              _handleVnpayReturnUrl(url);
            }
            return NavigationDecision.navigate;
          },
          onHttpError: (error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  /// Xử lý trực tiếp từ URL /vnpay-return (phân tích query param mà không cần deep link)
  void _handleVnpayReturnUrl(String url) {
    if (_handled) return;
    _handled = true;

    final uri = Uri.tryParse(url);
    final responseCode = uri?.queryParameters['vnp_ResponseCode'] ?? '';
    final isSuccess = responseCode == '00';
    final message = isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại (mã: $responseCode)';

    if (!mounted) return;

    if (isSuccess) {
      AppAlert.show(context, message: message, type: 'success');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainTabView(initialTab: 0)),
          (route) => false,
        );
      });
    } else {
      AppAlert.show(context, message: message, type: 'error');
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }


  /// Phân tích URL return và điều hướng theo kết quả
  void _handleReturnUrl(String url) {
    if (_handled) return;
    _handled = true;

    final uri = Uri.tryParse(url);
    final isSuccess = url.contains('/payment/success');
    final message = uri?.queryParameters['message'] ?? (isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại');

    if (!mounted) return;

    if (isSuccess) {
      AppAlert.show(context, message: message);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainTabView(initialTab: 0),
          ),
          (route) => false,
        );
      });
    } else {
      AppAlert.show(context, message: message, type: 'error');
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  String _getErrorMessage(String code) {
    const msgs = {
      '24': 'Bạn đã hủy giao dịch',
      '51': 'Số dư không đủ',
      '11': 'Hết hạn chờ thanh toán',
      '09': 'Thẻ chưa đăng ký InternetBanking',
      '65': 'Vượt hạn mức giao dịch trong ngày',
    };
    return msgs[code] ?? 'Vui lòng thử lại (mã: $code)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => _confirmCancel(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF005BAC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'VNPay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cổng thanh toán',
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
          // Indicator đơn hàng
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.1),
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF005BAC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'VNPay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF005BAC)),
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Đang kết nối cổng thanh toán...',
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
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
        title: const Text('Hủy thanh toán?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Đơn hàng đã được tạo. Nếu bạn thoát, có thể thanh toán lại sau trong mục "Đơn hàng của tôi".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ở lại', style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}
