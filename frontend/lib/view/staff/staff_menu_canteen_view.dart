import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class StaffMenuCanteenView extends StatefulWidget {
  const StaffMenuCanteenView({super.key});

  @override
  State<StaffMenuCanteenView> createState() => _StaffMenuCanteenViewState();
}

class _StaffMenuCanteenViewState extends State<StaffMenuCanteenView> {
  late Future<_MenuCanteenData> pageFuture;

  @override
  void initState() {
    super.initState();
    pageFuture = _loadData();
  }

  Future<_MenuCanteenData> _loadData() async {
    dynamic canteenResponse;
    dynamic menuResponse;

    try {
      canteenResponse = await ServiceCall.fetchGet(SVKey.svStaffStoreInfo, isToken: true);
      menuResponse = await ServiceCall.fetchGet(SVKey.svStaffStoreMenu, isToken: true);
    } catch (e) {
      debugPrint('[StaffMenu] API error: $e');
    }

    final cMap = canteenResponse is Map && canteenResponse['data'] != null
        ? Map<String, dynamic>.from(canteenResponse['data'])
        : <String, dynamic>{};
        
    final canteen = {
      'name': cMap['tenGianHang'] ?? '',
      'location': cMap['moTa'] ?? '',
      'openHours': cMap['gioMoCua'] ?? '',
      'description': cMap['moTa'] ?? '',
    };

    final menu = menuResponse is Map && menuResponse['data'] is List
        ? (menuResponse['data'] as List).whereType<Map>().map((item) {
            final m = Map<String, dynamic>.from(item);
            return {
              'id': m['maMonAn'] ?? m['id'] ?? 0,
              'name': m['tenMonAn'] ?? m['name'] ?? '',
              'categoryName': m['tenDanhMuc'] ?? m['categoryName'] ?? 'Khac',
              'price': m['giaTien'] ?? m['price'] ?? 0,
              'description': m['moTa'] ?? m['description'] ?? '',
              'imageUrl': m['hinhAnh'] ?? m['imageUrl'] ?? '',
              'isAvailable': m['trangThai'] ?? m['isAvailable'] ?? true,
            };
          }).toList()
        : <Map<String, dynamic>>[];

    return _MenuCanteenData(canteen: canteen, menu: menu);
  }

  Future<void> _refresh() async {
    setState(() {
      pageFuture = _loadData();
    });
    await pageFuture;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _showCanteenEditor(Map<String, dynamic> canteen) async {
    final nameController =
        TextEditingController(text: canteen['name']?.toString() ?? '');
    final locationController =
        TextEditingController(text: canteen['location']?.toString() ?? '');
    final openHoursController =
        TextEditingController(text: canteen['openHours']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: canteen['description']?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cap nhat thong tin canteen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ten canteen'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Vi tri'),
              ),
              TextField(
                controller: openHoursController,
                decoration: const InputDecoration(labelText: 'Gio mo cua'),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mo ta'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty ||
                  openHoursController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Ten, vi tri, gio mo cua khong duoc de trong.')),
                );
                return;
              }

              try {
                /*
                await ServiceCall.post({
                    'name': nameController.text.trim(),
                    'location': locationController.text.trim(),
                    'openHours': openHoursController.text.trim(),
                    'description': descriptionController.text.trim(),
                });
                */

                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
                await _refresh();
              } catch (error) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
            child: const Text('Luu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDishEditor({Map<String, dynamic>? dish}) async {
    final isEdit = dish != null;
    final nameController =
        TextEditingController(text: dish?['name']?.toString() ?? '');
    final categoryController = TextEditingController(
        text: dish?['categoryName']?.toString() ?? 'Khac');
    final priceController = TextEditingController(
        text: _toDouble(dish?['price']).toStringAsFixed(0));
    final descriptionController =
        TextEditingController(text: dish?['description']?.toString() ?? '');
    final imageUrlController =
        TextEditingController(text: dish?['imageUrl']?.toString() ?? '');
    bool isAvailable = dish?['isAvailable'] != false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Sua mon an' : 'Them mon an',
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Ten mon'),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Danh muc'),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gia ban'),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mo ta'),
                    ),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isAvailable,
                      title: const Text('Con ban'),
                      onChanged: (value) {
                        setModalState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final price =
                              double.tryParse(priceController.text.trim());
                          if (nameController.text.trim().isEmpty ||
                              categoryController.text.trim().isEmpty ||
                              price == null ||
                              price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Ten mon, danh muc va gia ban khong hop le.')),
                            );
                            return;
                          }

                          final payload = {
                            'name': nameController.text.trim(),
                            'categoryName': categoryController.text.trim(),
                            'price': price,
                            'description': descriptionController.text.trim(),
                            'imageUrl': imageUrlController.text.trim(),
                            'isAvailable': isAvailable,
                          };

                          try {
                            if (isEdit) {
                              // edit
                            } else {
                              // create
                            }

                            if (!mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            await _refresh();
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())));
                          }
                        },
                        child: Text(isEdit ? 'Luu thay doi' : 'Them mon'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDish(dynamic dishId) async {
    final parsed = int.tryParse(dishId?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa mon an'),
        content: const Text('Ban chac chan muon xoa mon an nay?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Khong')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoa')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      // delete
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      appBar: AppBar(
        title: const Text('Quan ly mon an va canteen'),
        backgroundColor: const Color(0xfffff8f2),
        surfaceTintColor: const Color(0xfffff8f2),
      ),
      body: FutureBuilder<_MenuCanteenData>(
        future: pageFuture,
        builder: (context, snapshot) {
          final canteen = snapshot.data?.canteen ?? <String, dynamic>{};
          final menu = snapshot.data?.menu ?? <Map<String, dynamic>>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TColor.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                canteen['name']?.toString() ?? 'Canteen',
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showCanteenEditor(canteen),
                              icon: Icon(Icons.edit_rounded,
                                  color: TColor.primary),
                            ),
                          ],
                        ),
                        Text('Vi tri: ${canteen['location'] ?? '-'}',
                            style: TextStyle(
                                color: TColor.secondaryText, fontSize: 12)),
                        Text('Gio mo cua: ${canteen['openHours'] ?? '-'}',
                            style: TextStyle(
                                color: TColor.secondaryText, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          canteen['description']?.toString() ??
                              'Chua co mo ta.',
                          style: TextStyle(color: TColor.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Danh sach mon an (${menu.length})',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showDishEditor(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Them mon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (menu.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: TColor.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Canteen chua co mon an nao.',
                        style: TextStyle(color: TColor.secondaryText),
                      ),
                    )
                  else
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: menu.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final dish = menu[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColor.textfield),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dish['name']?.toString() ?? 'Mon an',
                                      style: TextStyle(
                                        color: TColor.primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showDishEditor(dish: dish),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteDish(dish['id']),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                  ),
                                ],
                              ),
                              Text('Danh muc: ${dish['categoryName'] ?? '-'}',
                                  style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 12)),
                              Text(
                                  'Gia: ${_toDouble(dish['price']).toStringAsFixed(0)} đ',
                                  style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 12)),
                              Text(
                                'Trang thai: ${dish['isAvailable'] == false ? 'Tam dung' : 'Dang ban'}',
                                style: TextStyle(
                                    color: TColor.secondaryText, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuCanteenData {
  final Map<String, dynamic> canteen;
  final List<Map<String, dynamic>> menu;

  _MenuCanteenData({required this.canteen, required this.menu});
}
