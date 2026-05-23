// lib/view/customer/home/home_data_helper.dart
// Chứa toàn bộ logic xử lý dữ liệu cho HomeView.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class HomeData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> canteens;
  final List<Map<String, dynamic>> dishes;

  HomeData({
    required this.categories,
    required this.canteens,
    required this.dishes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
class HomeDataHelper {
  // ── Normalize ────────────────────────────────────────────────────────────
  static String normalizeText(String value) {
    final lower = value.toLowerCase().trim();
    return lower
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ả', 'a')
        .replaceAll('ã', 'a').replaceAll('ạ', 'a').replaceAll('ă', 'a')
        .replaceAll('ắ', 'a').replaceAll('ằ', 'a').replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a').replaceAll('ặ', 'a').replaceAll('â', 'a')
        .replaceAll('ấ', 'a').replaceAll('ầ', 'a').replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a').replaceAll('ậ', 'a')
        .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e').replaceAll('ẹ', 'e').replaceAll('ê', 'e')
        .replaceAll('ế', 'e').replaceAll('ề', 'e').replaceAll('ể', 'e')
        .replaceAll('ễ', 'e').replaceAll('ệ', 'e')
        .replaceAll('í', 'i').replaceAll('ì', 'i').replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i').replaceAll('ị', 'i')
        .replaceAll('ó', 'o').replaceAll('ò', 'o').replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o').replaceAll('ọ', 'o').replaceAll('ô', 'o')
        .replaceAll('ố', 'o').replaceAll('ồ', 'o').replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o').replaceAll('ộ', 'o').replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o').replaceAll('ờ', 'o').replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o').replaceAll('ợ', 'o')
        .replaceAll('ú', 'u').replaceAll('ù', 'u').replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u').replaceAll('ụ', 'u').replaceAll('ư', 'u')
        .replaceAll('ứ', 'u').replaceAll('ừ', 'u').replaceAll('ử', 'u')
        .replaceAll('ữ', 'u').replaceAll('ự', 'u')
        .replaceAll('ý', 'y').replaceAll('ỳ', 'y').replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y').replaceAll('ỵ', 'y');
  }

  // ── Category icon mapping ─────────────────────────────────────────────────
  static Map<String, dynamic> categoryLogo(String value) {
    final n = value.toLowerCase();
    if (n.contains('an nhanh') || n.contains('fast') || n.contains('snack')) {
      return {'icon': Icons.fastfood_rounded,            'bgColor': const Color(0xFFFFE1D6)};
    }
    if (n.contains('do uong') || n.contains('đồ uống') || n.contains('drink')) {
      return {'icon': Icons.local_drink_rounded,         'bgColor': const Color(0xFFDDF3FF)};
    }
    if (n.contains('tra sua') || n.contains('trà sữa') || n.contains('tea') || n.contains('coffee')) {
      return {'icon': Icons.emoji_food_beverage_rounded, 'bgColor': const Color(0xFFEDE3FF)};
    }
    if (n.contains('trang mieng') || n.contains('tráng miệng') || n.contains('dessert')) {
      return {'icon': Icons.icecream_rounded,            'bgColor': const Color(0xFFFFE7F1)};
    }
    if (n.contains('com') || n.contains('cơm') || n.contains('meal')) {
      return {'icon': Icons.rice_bowl_rounded,           'bgColor': const Color(0xFFFFF0CF)};
    }
    if (n.contains('pho') || n.contains('phở') || n.contains('bun') || n.contains('bún') || n.contains('mi') || n.contains('mì')) {
      return {'icon': Icons.ramen_dining_rounded,        'bgColor': const Color(0xFFFFF4DA)};
    }
    if (n.contains('chay') || n.contains('vegetarian') || n.contains('vegan')) {
      return {'icon': Icons.eco_rounded,                 'bgColor': const Color(0xFFE6F7DF)};
    }
    if (n.contains('hai san') || n.contains('hải sản') || n.contains('seafood')) {
      return {'icon': Icons.set_meal_rounded,            'bgColor': const Color(0xFFDFF4F8)};
    }
    return {'icon': Icons.restaurant_menu_rounded,       'bgColor': const Color(0xFFFFE8D9)};
  }

  // ── Build card lists ──────────────────────────────────────────────────────
  static List<Map<String, dynamic>> buildCategoryCards(
      List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) return [];
    return categories.take(8).map((item) {
      final name = item['categoryName']?.toString() ?? 'Category';
      final logo = categoryLogo(name);
      return {'icon': logo['icon'], 'bgColor': logo['bgColor'], 'name': name};
    }).toList();
  }

  static List<Map<String, dynamic>> buildRestaurantCards(
      List<Map<String, dynamic>> canteens) {
    return canteens.take(10).map((item) {
      final rawTop = item['topDishes'];
      final topDishes = (rawTop is List)
          ? rawTop.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      return {
        'imageUrl':     item['logoUrl']?.toString() ?? item['bannerUrl']?.toString(),
        'name':         item['name']?.toString() ?? '',
        'rate':         item['totalDishes']?.toString() ?? '0',
        'rating':       'Dishes',
        'type':         item['location']?.toString() ?? '',
        'food_type':    item['openHours']?.toString() ?? '',
        'canteenId':    item['id'],
        'avgRating':    (item['avgRating'] as num?)?.toDouble(),
        'totalReviews': (item['totalReviews'] as num?)?.toInt() ?? 0,
        'topDishes':    topDishes,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> buildDishCards(
      List<Map<String, dynamic>> dishes) {
    return dishes.map((item) {
      final price       = (item['price'] as num?)?.toDouble();
      final rate        = (item['rate'] as num?)?.toDouble() ?? 0.0;
      final luotDanhGia = (item['rating'] as num?)?.toInt() ?? 0;
      final sold        = (item['soLuongDaBan'] as num?)?.toInt() ?? 0;
      return {
        'imageUrl':     item['imageUrl']?.toString(),
        'name':         item['name']?.toString() ?? '',
        'price':        price,
        'soLuongDaBan': sold,
        'rate':         rate > 0 ? rate.toStringAsFixed(1) : '',
        'rating':       luotDanhGia > 0 ? '$luotDanhGia' : '',
        'type':         item['categoryName']?.toString() ?? '',
        'food_type':    item['canteenName']?.toString() ?? '',
        'dishId':       item['id'],
        'id':           item['id'],
        'description':  item['description']?.toString() ?? '',
        'canteenName':  item['canteenName']?.toString() ?? '',
        'categoryName': item['categoryName']?.toString() ?? '',
      };
    }).toList();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> filterByCategory(
      List<Map<String, dynamic>> dishes, String? selected) {
    if (selected == null || selected.isEmpty) return dishes;
    final normalizedSelected = normalizeText(selected);
    return dishes.where((d) {
      final cat = normalizeText(d['type']?.toString() ?? '');
      return cat == normalizedSelected ||
          cat.contains(normalizedSelected) ||
          normalizedSelected.contains(cat);
    }).toList();
  }

  static List<Map<String, dynamic>> filterDishesBySearch(
      List<Map<String, dynamic>> dishes, String query, bool onlyByName) {
    final q = normalizeText(query);
    if (q.isEmpty) return dishes;
    return dishes.where((d) {
      final name = normalizeText(d['name']?.toString() ?? '');
      if (onlyByName) return name.contains(q);
      final canteen  = normalizeText(d['food_type']?.toString() ?? '');
      final category = normalizeText(d['type']?.toString() ?? '');
      return name.contains(q) || canteen.contains(q) || category.contains(q);
    }).toList();
  }

  static List<Map<String, dynamic>> filterRestaurantsBySearch(
      List<Map<String, dynamic>> restaurants, String query) {
    final q = normalizeText(query);
    if (q.isEmpty) return restaurants;
    return restaurants.where((r) {
      final name     = normalizeText(r['name']?.toString() ?? '');
      final location = normalizeText(r['type']?.toString() ?? '');
      final hours    = normalizeText(r['food_type']?.toString() ?? '');
      return name.contains(q) || location.contains(q) || hours.contains(q);
    }).toList();
  }

  static List<String> buildSearchSuggestions(
      List<Map<String, dynamic>> dishes,
      List<Map<String, dynamic>> restaurants,
      String query,
      bool includeRestaurants) {
    final q = normalizeText(query);
    if (q.isEmpty) return [];
    final names = <String>{
      ...dishes.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty),
      if (includeRestaurants)
        ...restaurants.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty),
    };
    return names
        .where((n) => normalizeText(n).startsWith(q))
        .toList()
      ..sort();
  }

  // ── Meal-time suggestion ──────────────────────────────────────────────────
  static String mealPeriodTitle() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10)  return 'Gợi ý bữa sáng';
    if (h >= 10 && h < 15) return 'Gợi ý bữa trưa';
    if (h >= 15 && h < 17) return 'Gợi ý bữa xế';
    if (h >= 17 && h < 22) return 'Gợi ý bữa tối';
    return 'Món ngon gợi ý';
  }

  static List<Map<String, dynamic>> getSuggestionsByTime(
      List<Map<String, dynamic>> dishCards) {
    if (dishCards.isEmpty) return [];
    final h = DateTime.now().hour;
    List<String> kw = [];
    if (h >= 5 && h < 10)  kw = ['bun', 'pho', 'mi', 'banh mi', 'xoi', 'chao', 'breakfast'];
    if (h >= 10 && h < 15) kw = ['com', 'set', 'phan', 'meal', 'lunch', 'ga', 'ca', 'thit', 'suon'];
    if (h >= 15 && h < 17) kw = ['snack', 'an vat', 'tra sua', 'tea', 'kem', 'cake', 'banh'];
    if (h >= 17 && h < 22) kw = ['com', 'lau', 'nuong', 'bun bo', 'dinner'];

    List<Map<String, dynamic>> filtered = [];
    if (kw.isNotEmpty) {
      filtered = dishCards.where((d) {
        final name = normalizeText(d['name']?.toString() ?? '');
        return kw.any((k) => name.contains(k));
      }).toList();
    }

    if (filtered.isEmpty) {
      filtered = List.from(dishCards)
        ..sort((a, b) {
          final ra = double.tryParse(a['rate']?.toString() ?? '0') ?? 0.0;
          final rb = double.tryParse(b['rate']?.toString() ?? '0') ?? 0.0;
          return rb.compareTo(ra);
        });
      return filtered.take(15).toList();
    }
    return filtered;
  }
}
