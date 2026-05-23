import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../shared/login/welcome_view.dart';

class StaffBackendToolsView extends StatefulWidget {
  const StaffBackendToolsView({super.key});

  @override
  State<StaffBackendToolsView> createState() => _StaffBackendToolsViewState();
}

class _StaffBackendToolsViewState extends State<StaffBackendToolsView> {
  late Future<_BackendData> pageFuture;

  @override
  void initState() {
    super.initState();
    pageFuture = _loadData();
  }

  Future<_BackendData> _loadData() async {
    dynamic categoriesResponse = [];
    dynamic promotionsResponse = [];
    dynamic statsResponse = [];

    try {
      promotionsResponse = await ServiceCall.fetchGet(
        SVKey.svStaffPromotions,
        isToken: true,
      );
    } catch (_) {}

    final categories = categoriesResponse is List
        ? categoriesResponse
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    final promotions = promotionsResponse is List
        ? promotionsResponse
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    final stats = statsResponse is List
        ? statsResponse
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    return _BackendData(
        categories: categories, promotions: promotions, stats: stats);
  }

  Future<void> _refresh() async {
    setState(() {
      pageFuture = _loadData();
    });
    await pageFuture;
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Them danh muc'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Ten danh muc'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huy')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Ten danh muc khong duoc de trong.')),
                );
                return;
              }

              try {
                // await Call API

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
            child: const Text('Them'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      appBar: AppBar(
        title: const Text('Tien ich backend cho staff'),
        backgroundColor: const Color(0xfffff8f2),
        surfaceTintColor: const Color(0xfffff8f2),
      ),
      body: FutureBuilder<_BackendData>(
        future: pageFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final categories = data?.categories ?? <Map<String, dynamic>>[];
          final promotions = data?.promotions ?? <Map<String, dynamic>>[];
          final stats = data?.stats ?? <Map<String, dynamic>>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CountCard(
                          title: 'Danh muc', value: '${categories.length}'),
                      const SizedBox(width: 8),
                      _CountCard(
                          title: 'Voucher', value: '${promotions.length}'),
                      const SizedBox(width: 8),
                      _CountCard(
                          title: 'Thong ke mon', value: '${stats.length}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Them danh muc'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Dong bo lai du lieu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Danh muc mon an',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _SimpleListCard(
                      children: categories
                          .map((item) => '• ${item['name'] ?? ''}')
                          .toList(growable: false),
                      emptyText: 'Chua co danh muc.',
                    ),
                  const SizedBox(height: 14),
                  Text(
                    'Voucher dang co',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SimpleListCard(
                    children: promotions
                        .map((item) =>
                            '• ${item['title'] ?? 'Voucher'} - ${item['discountPercent'] ?? 0}%')
                        .toList(growable: false),
                    emptyText: 'Chua co voucher nao.',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Thong ke mon an (backend)',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SimpleListCard(
                    children: stats
                        .map((item) =>
                            '• ${item['dishName'] ?? 'Mon'}: ${item['orderCount'] ?? 0} don')
                        .toList(growable: false),
                    emptyText: 'Chua co thong ke.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ServiceCall.logout();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WelcomeView()),
                          (route) => false,
                        );
                      },
                      child: const Text('Dang xuat'),
                    ),
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

class _CountCard extends StatelessWidget {
  final String title;
  final String value;

  const _CountCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TColor.textfield),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: TColor.secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleListCard extends StatelessWidget {
  final List<String> children;
  final String emptyText;

  const _SimpleListCard({required this.children, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: children.isEmpty
          ? Text(
              emptyText,
              style: TextStyle(color: TColor.secondaryText),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        item,
                        style: TextStyle(color: TColor.secondaryText),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _BackendData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> promotions;
  final List<Map<String, dynamic>> stats;

  _BackendData({
    required this.categories,
    required this.promotions,
    required this.stats,
  });
}
