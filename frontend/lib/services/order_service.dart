import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';

class OrderService {
  static String get basePath => "${SVKey.apiBaseUrl}orders";

  // 1. Checkout (Bấm đặt hàng)
  // Payload items: [{ "maMonAn": 1, "soLuong": 2, "giaTien": 20000 }]
  static Future<Map<String, dynamic>> checkout({
    required String toaNha,
    required String tang,
    required String phong,
    double? kinhDo,
    double? viDo,
    required List<Map<String, dynamic>> items,
    required double tongTien,
  }) async {
    final payload = {
      'toaNha': toaNha,
      'tang': tang,
      'phong': phong,
      'kinhDo': kinhDo,
      'viDo': viDo,
      'items': items,
      'tongTien': tongTien,
    };
    final res = await ServiceCall.fetchPost("$basePath/checkout", isToken: true, body: payload);
    return res;
  }

  // 2. Lấy thông tin radar chờ ghép đơn
  static Future<int> getRadar(String toaNha, String tang) async {
    try {
      final res = await ServiceCall.fetchGet(
        "$basePath/radar", 
        isToken: true, 
        queryParameters: {'toaNha': toaNha, 'tang': tang}
      );
      if (res['success'] == true) {
        return res['data']['soNguoiCho'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
