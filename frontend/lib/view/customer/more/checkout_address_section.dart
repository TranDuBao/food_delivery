// lib/view/customer/more/checkout_address_section.dart
// Phần chọn tòa nhà + phòng học trong màn xác nhận đặt hàng

import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common_widget/round_textfield.dart';

class CheckoutAddressSection extends StatelessWidget {
  final TextEditingController nameController;
  final List<Map<String, dynamic>> buildings;
  final List<Map<String, dynamic>> rooms;
  final int? selectedBuildingId;
  final int? selectedRoomId;
  final void Function(int?) onBuildingChanged;
  final void Function(int?) onRoomChanged;

  const CheckoutAddressSection({
    super.key,
    required this.nameController,
    required this.buildings,
    required this.rooms,
    required this.selectedBuildingId,
    required this.selectedRoomId,
    required this.onBuildingChanged,
    required this.onRoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundTextfield(
          hintText: 'Họ và tên người nhận',
          controller: nameController,
          left: Icon(Icons.person_outline, color: TColor.secondaryText, size: 20),
        ),
        const SizedBox(height: 12),
        Row(children: [
          // Dropdown Tòa nhà
          Expanded(child: _DropdownBox(
            icon: Icons.business_outlined,
            hint: 'Tòa nhà',
            value: selectedBuildingId,
            items: buildings.map((b) => DropdownMenuItem<int>(
              value: b['maToaNha'] as int,
              child: Text(b['tenToaNha'].toString(),
                  style: TextStyle(color: TColor.primaryText, fontSize: 14)),
            )).toList(),
            onChanged: onBuildingChanged,
          )),
          const SizedBox(width: 12),
          // Dropdown Phòng học
          Expanded(child: _DropdownBox(
            icon: Icons.meeting_room_outlined,
            hint: 'Phòng học',
            value: selectedRoomId,
            items: rooms
                .where((r) => selectedBuildingId == null || r['maToaNha'] == selectedBuildingId)
                .map((r) => DropdownMenuItem<int>(
                  value: r['maPhong'] as int,
                  child: Text(r['tenPhong'].toString(),
                      style: TextStyle(color: TColor.primaryText, fontSize: 14)),
                )).toList(),
            onChanged: onRoomChanged,
          )),
        ]),
      ],
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final IconData icon;
  final String hint;
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final void Function(int?) onChanged;

  const _DropdownBox({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(children: [
        Icon(icon, color: TColor.secondaryText, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: TextStyle(color: TColor.placeholder, fontSize: 14)),
              borderRadius: BorderRadius.circular(20),
              menuMaxHeight: 300,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: TColor.primaryText),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}
