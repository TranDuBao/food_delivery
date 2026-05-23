// lib/view/customer/main_tabview/tab_invite_button.dart
// Widget tab Invite: nhấn → InviteView, giữ lâu → mở More menu.

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';

class TabInviteButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const TabInviteButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onMoreTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 25,
            color: isSelected ? TColor.primary : TColor.placeholder,
          ),
          const SizedBox(height: 2),
          Text(
            'Invite',
            style: TextStyle(
              color: isSelected ? TColor.primary : TColor.placeholder,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
