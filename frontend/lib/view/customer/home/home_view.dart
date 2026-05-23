import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';

import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/category_cell.dart';
import '../menu/item_details_view.dart';
import 'home_data_helper.dart';
import 'home_meal_suggestion.dart';
import 'home_recent_items.dart';
import 'home_restaurants_section.dart';
import 'home_search_bar.dart';
import '../voucher/home_voucher_section.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController txtSearch = TextEditingController();
  Future<HomeData>? _homeFuture;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(_onSearchChanged);
    _homeFuture = _loadHomeData();
  }

  @override
  void dispose() {
    txtSearch.removeListener(_onSearchChanged);
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final v = txtSearch.text;
    if (v != _searchQuery) setState(() => _searchQuery = v);
  }

  Future<HomeData> _loadHomeData() async {
    List<Map<String, dynamic>> _parseList(dynamic raw) {
      final data = raw is Map ? raw['data'] : raw;
      return (data as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    try {
      final results = await Future.wait<dynamic>([
        ServiceCall.fetchGet(SVKey.svCanteenCategories, isToken: true),
        ServiceCall.fetchGet(SVKey.svCanteens,          isToken: true),
        ServiceCall.fetchGet(SVKey.svCanteenDishes,     isToken: true),
      ]);

      return HomeData(
        categories: _parseList(results[0]),
        canteens:   _parseList(results[1]),
        dishes:     _parseList(results[2]),
      );
    } catch (e) {
      debugPrint('HomeData fetch error: $e');
      return HomeData(categories: [], canteens: [], dishes: []);
    }
  }

  void _openDishDetail(Map<String, dynamic> dish) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsView(dishObj: dish)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        final data              = snapshot.data;
        final isLoading         = snapshot.connectionState == ConnectionState.waiting;
        final categories        = HomeDataHelper.buildCategoryCards(data?.categories ?? []);
        final restaurants       = HomeDataHelper.buildRestaurantCards(data?.canteens ?? []);
        final allDishesFull     = HomeDataHelper.buildDishCards(data?.dishes ?? []);
        final isCatSelected     = _selectedCategory != null && _selectedCategory!.isNotEmpty;
        final categoryDishes    = HomeDataHelper.filterByCategory(allDishesFull, _selectedCategory);
        final filteredDishes    = HomeDataHelper.filterDishesBySearch(categoryDishes, _searchQuery, isCatSelected);
        final restaurantResults = isCatSelected
            ? <Map<String, dynamic>>[]
            : HomeDataHelper.filterRestaurantsBySearch(restaurants, _searchQuery);
        final suggestions       = HomeDataHelper.getSuggestionsByTime(allDishesFull);
        final searchSuggestions = HomeDataHelper.buildSearchSuggestions(
          categoryDishes, restaurants, _searchQuery, !isCatSelected,
        );
        final showNoResult = !isCatSelected &&
            _searchQuery.trim().isNotEmpty &&
            restaurantResults.isEmpty &&
            filteredDishes.isEmpty;

        return Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // ── Greeting ─────────────────────────────────────────────
                  const SizedBox(height: 46),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          'Good morning ${ServiceCall.userPayload[KKey.name] ?? ''}!',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Search bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: HomeSearchBar(
                      controller: txtSearch,
                      searchQuery: _searchQuery,
                      suggestions: searchSuggestions.take(8).toList(),
                      isCategorySelected: isCatSelected,
                      onSuggestionTap: (s) {
                        txtSearch.text = s;
                        txtSearch.selection = TextSelection.fromPosition(
                          TextPosition(offset: s.length),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Category chips ───────────────────────────────────────
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cObj    = categories[index];
                        final catName = cObj['name']?.toString() ?? '';
                        return CategoryCell(
                          cObj: cObj,
                          isSelected: HomeDataHelper.normalizeText(catName) ==
                              HomeDataHelper.normalizeText(_selectedCategory ?? ''),
                          onTap: () => setState(() {
                            final isCurrent =
                                HomeDataHelper.normalizeText(_selectedCategory ?? '') ==
                                    HomeDataHelper.normalizeText(catName);
                            _selectedCategory = isCurrent ? null : catName;
                          }),
                        );
                      },
                    ),
                  ),

                  // ── Gợi ý + Popular Restaurants (chỉ khi không lọc) ─────
                  if (!isCatSelected && _searchQuery.trim().isEmpty) ...[
                    const SizedBox(height: 20),
                    HomeMealSuggestion(
                      title: HomeDataHelper.mealPeriodTitle(),
                      suggestions: suggestions,
                      isLoading: isLoading,
                      onDishTap: _openDishDetail,
                    ),
                    const SizedBox(height: 10),
                    const HomeVoucherSection(),
                    HomeRestaurantsSection(
                      restaurants: restaurantResults,
                      isLoading: isLoading,
                    ),
                  ] else if (!isCatSelected && _searchQuery.trim().isNotEmpty) ...[
                     const SizedBox(height: 20),
                     HomeRestaurantsSection(
                      restaurants: restaurantResults,
                      isLoading: isLoading,
                    ),
                  ],

                  // ── Không tìm thấy kết quả ──────────────────────────────
                  if (showNoResult)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        'Không tìm thấy món ăn hoặc căn tin phù hợp',
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // ── Recent Items ────────────────────────────────────────
                  HomeRecentItems(
                    dishes: filteredDishes.take(20).toList(),
                    isCategorySelected: isCatSelected,
                    selectedCategory: _selectedCategory,
                    isSearching: _searchQuery.trim().isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
