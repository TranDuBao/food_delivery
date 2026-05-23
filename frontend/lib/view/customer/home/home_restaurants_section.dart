// lib/view/customer/home/home_restaurants_section.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common_widget/popular_resutaurant_row.dart';
import 'package:food_delivery/common_widget/view_all_title_row.dart';
import '../menu/menu_items_view.dart';

/// Section "Popular Restaurants" trên HomeView.
class HomeRestaurantsSection extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final bool isLoading;

  const HomeRestaurantsSection({
    super.key,
    required this.restaurants,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ViewAllTitleRow(title: 'Popular Restaurants', onView: () {}),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final pObj = restaurants[index];
              return PopularRestaurantRow(
                pObj: pObj,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuItemsView(mObj: pObj),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
