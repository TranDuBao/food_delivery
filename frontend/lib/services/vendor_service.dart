import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';

class VendorService {
  static String get basePath => "${SVKey.apiBaseUrl}canteens";

  // 1. Xem danh sách đơn (món ăn) cần chuẩn bị
  static Future<List<dynamic>> getPendingOrders() async {
    final res = await ServiceCall.fetchGet("$basePath/me/orders", isToken: true);
    if (res['success'] == true) {
       return res['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  // 2. Báo đã làm xong một món
  static Future<bool> markDishDone(int itemId) async {
    try {
      final res = await ServiceCall.fetchPut("$basePath/me/orders/$itemId/status", isToken: true);
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
