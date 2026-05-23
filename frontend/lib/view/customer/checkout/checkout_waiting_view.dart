import 'dart:async';
import 'package:flutter/material.dart';
import '../../../common/app_alert.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/services/order_service.dart';

class CheckoutWaitingView extends StatefulWidget {
  final Map<String, dynamic> checkoutData;
  const CheckoutWaitingView({Key? key, required this.checkoutData}) : super(key: key);

  @override
  State<CheckoutWaitingView> createState() => _CheckoutWaitingViewState();
}

class _CheckoutWaitingViewState extends State<CheckoutWaitingView> {
  int _waitingCount = 0;
  Timer? _timer;
  bool _isOrdered = false;

  @override
  void initState() {
    super.initState();
    _placeOrder();
  }

  void _placeOrder() async {
    try {
      final res = await OrderService.checkout(
        toaNha: widget.checkoutData['toaNha'] ?? 'A1',
        tang: widget.checkoutData['tang'] ?? '1',
        phong: widget.checkoutData['phong'] ?? '101',
        items: widget.checkoutData['items'] ?? [],
        tongTien: widget.checkoutData['tongTien'] ?? 0,
      );

      if (res['success'] == true) {
        setState(() {
          _isOrdered = true;
        });
        _startPollingRadar();
      } else {
        _showError(res['message']);
      }
    } catch (e) {
      _showError("Lỗi hệ thống khi đặt hàng");
    }
  }

  void _startPollingRadar() {
    _fetchRadar();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchRadar();
    });
  }

  void _fetchRadar() async {
    final count = await OrderService.getRadar(
      widget.checkoutData['toaNha'] ?? 'A1',
      widget.checkoutData['tang'] ?? '1',
    );
    if (mounted) {
      setState(() {
        _waitingCount = count;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: const Text("Trạng thái đơn hàng"),
        backgroundColor: TColor.white,
      ),
      body: Center(
        child: _isOrdered
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "Đơn hàng đã được ghi nhận!",
                    style: TextStyle(fontSize: 20, color: TColor.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Trạng thái: Cho phép hệ thống gom 15 phút.",
                    style: TextStyle(fontSize: 16, color: TColor.secondaryText),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.radar, size: 50, color: Colors.blue),
                        const SizedBox(height: 10),
                        Text(
                          "Radar khu vực ${widget.checkoutData['toaNha']} - Tầng ${widget.checkoutData['tang']}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Hiện đang có $_waitingCount người cùng chờ ghép đơn giống bạn",
                          style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
