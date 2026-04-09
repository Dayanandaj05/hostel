import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_routes.dart';
import '../../../../tokens/domain/entities/food_token_item_model.dart';
import '../../../../tokens/presentation/controllers/food_token_inventory_controller.dart';
import '../../../../../core/design/psg_design_system.dart';

class AdminFoodTokenInventoryScreen extends StatefulWidget {
  const AdminFoodTokenInventoryScreen({super.key});

  @override
  State<AdminFoodTokenInventoryScreen> createState() => _AdminFoodTokenInventoryScreenState();
}

class _AdminFoodTokenInventoryScreenState extends State<AdminFoodTokenInventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodTokenInventoryController>().startWatching(activeOnly: false);
    });
  }

  void _openItemDialog([FoodTokenItemModel? item]) {
    showDialog(
      context: context,
      builder: (ctx) => _ItemFormDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PsgGlassAppBar(
          title: 'Food Token Inventory',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: PsgColors.primary),
            onPressed: () => context.go(AppRoutes.adminHome),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openItemDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
          backgroundColor: PsgColors.primary,
        ),
        body: Consumer<FoodTokenInventoryController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.items.isEmpty) {
              return Center(
                child: Text(
                  'No items found.\nAdd one to start your inventory.',
                  textAlign: TextAlign.center,
                  style: PsgText.body(16, color: PsgColors.onSurfaceVariant),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 80),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.items[index];
                return GlassCard(
                  onTap: () => _openItemDialog(item),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (item.isActive ? PsgColors.primary : Colors.grey)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_dining_rounded,
                          color: item.isActive ? PsgColors.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: PsgText.headline(
                                16,
                                color: item.isActive ? PsgColors.onSurface : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${item.price.toInt()}  •  Max ${item.limitPerPerson}/person',
                              style: PsgText.body(
                                14,
                                color: PsgColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Stock: ${item.totalQuantity}',
                              style: PsgText.body(
                                12,
                                color: item.totalQuantity <= 10
                                    ? PsgColors.error
                                    : PsgColors.primary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: item.isActive,
                        onChanged: (val) {
                          context.read<FoodTokenInventoryController>().updateItem(
                                item.id,
                                {'isActive': val},
                              );
                        },
                        activeTrackColor: PsgColors.primary.withValues(alpha: 0.5),
                        activeThumbColor: PsgColors.primary,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({this.item});
  final FoodTokenItemModel? item;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _stockCtrl;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    _limitCtrl = TextEditingController(text: item?.limitPerPerson.toString() ?? '1');
    _stockCtrl = TextEditingController(text: item?.totalQuantity.toString() ?? '50');
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _limitCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final limit = int.tryParse(_limitCtrl.text) ?? 1;
    final stock = int.tryParse(_stockCtrl.text) ?? 0;

    if (name.isEmpty) return;

    final controller = context.read<FoodTokenInventoryController>();

    if (widget.item == null) {
      controller.addItem(
        FoodTokenItemModel(
          id: '',
          name: name,
          price: price,
          limitPerPerson: limit,
          totalQuantity: stock,
          isActive: _isActive,
        ),
      );
    } else {
      controller.updateItem(widget.item!.id, {
        'name': name,
        'price': price,
        'limitPerPerson': limit,
        'totalQuantity': stock,
        'isActive': _isActive,
      });
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max limit per person'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Available Quantity'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
