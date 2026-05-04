import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../core/widgets/static_nav_bar.dart';
import '../../../../tokens/domain/entities/food_token_item_model.dart';
import '../../../../tokens/presentation/controllers/food_token_inventory_controller.dart';

class AdminFoodTokenInventoryScreen extends StatefulWidget {
  const AdminFoodTokenInventoryScreen({super.key});

  @override
  State<AdminFoodTokenInventoryScreen> createState() =>
      _AdminFoodTokenInventoryScreenState();
}

class _AdminFoodTokenInventoryScreenState
    extends State<AdminFoodTokenInventoryScreen> {
  static const _slots = ['Breakfast', 'Lunch', 'Dinner'];
  static const _audienceModes = [
    _AudienceMode(label: 'All', value: 'all'),
    _AudienceMode(label: 'South', value: 'south'),
    _AudienceMode(label: 'North', value: 'north'),
  ];

  String _selectedSlot = _slots[1];
  String _selectedAudienceMode = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FoodTokenInventoryController>()
          .startWatching(activeOnly: false);
    });
  }

  String _normalizeAudience(String value) {
    final key = value.trim().toLowerCase();
    if (key.contains('north')) return 'north';
    if (key.contains('south') || key.contains('regular')) return 'south';
    return 'both';
  }

  String? _forcedAudienceForCurrentMode() {
    if (_selectedAudienceMode == 'north') return 'North Indian';
    if (_selectedAudienceMode == 'south') return 'South Indian';
    return null;
  }

  bool _matchesAudienceMode(FoodTokenItemModel item) {
    if (_selectedAudienceMode == 'all') return true;
    final audience = _normalizeAudience(item.audience);
    if (_selectedAudienceMode == 'north') return audience == 'north';
    if (_selectedAudienceMode == 'south') return audience == 'south';
    return true;
  }

  void _openItemDialog([FoodTokenItemModel? item]) {
    showDialog<void>(
      context: context,
      builder: (_) => _ItemFormDialog(
        item: item,
        defaultSlot: _selectedSlot,
        forcedAudience: _forcedAudienceForCurrentMode(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PsgGlassAppBar(
          title: 'Token Menu Manager',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: PsgColors.primary),
            onPressed: () => context.go(AppRoutes.adminHome),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: StaticNavBar.reservedBottomPadding(context) - 24,
          ),
          child: FloatingActionButton.extended(
            onPressed: _openItemDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text('Add Menu Item',
                style: PsgText.label(12, color: Colors.white)),
            backgroundColor: PsgColors.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        body: Consumer<FoodTokenInventoryController>(
          builder: (context, controller, _) {
            final all = controller.items;
            final selected = all
                .where(
                  (item) =>
                      item.mealSlot == _selectedSlot &&
                      _matchesAudienceMode(item),
                )
                .toList()
              ..sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            final northCount = all
                .where((i) =>
                    i.mealSlot == _selectedSlot &&
                    _normalizeAudience(i.audience) == 'north')
                .length;
            final southCount = all
                .where((i) =>
                    i.mealSlot == _selectedSlot &&
                    _normalizeAudience(i.audience) == 'south')
                .length;
            final allCount =
                all.where((i) => i.mealSlot == _selectedSlot).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 96, 16, 104),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Treat token items like menu entries',
                        style: PsgText.headline(16, color: PsgColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set meal slot, veg type, quantity limits, and availability.',
                        style:
                            PsgText.body(12, color: PsgColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots.map((slot) {
                          final count =
                              all.where((i) => i.mealSlot == slot).length;
                          final active = _selectedSlot == slot;
                          return ChoiceChip(
                            selected: active,
                            onSelected: (_) =>
                                setState(() => _selectedSlot = slot),
                            label: Text('$slot ($count)'),
                            labelStyle: PsgText.label(
                              11,
                              color:
                                  active ? Colors.white : PsgColors.onSurface,
                            ),
                            selectedColor: PsgColors.primary,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.6),
                            side: BorderSide(
                              color: active
                                  ? PsgColors.primary
                                  : PsgColors.outline.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _audienceModes.map((mode) {
                          final active = _selectedAudienceMode == mode.value;
                          final count = mode.value == 'north'
                              ? northCount
                              : mode.value == 'south'
                                  ? southCount
                                  : allCount;

                          return ChoiceChip(
                            selected: active,
                            onSelected: (_) => setState(
                                () => _selectedAudienceMode = mode.value),
                            label: Text('${mode.label} ($count)'),
                            labelStyle: PsgText.label(
                              11,
                              color:
                                  active ? Colors.white : PsgColors.onSurface,
                            ),
                            selectedColor: mode.value == 'north'
                                ? Colors.indigo
                                : PsgColors.primary,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.6),
                            side: BorderSide(
                              color: active
                                  ? (mode.value == 'north'
                                      ? Colors.indigo
                                      : PsgColors.primary)
                                  : PsgColors.outline.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedAudienceMode == 'north') ...[
                        const SizedBox(height: 10),
                        Text(
                          'North menu items are shown only to students with approved North Indian mess for the selected month.',
                          style: PsgText.body(
                            11,
                            color: PsgColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (controller.isLoading && all.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (selected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 56),
                    child: Center(
                      child: Text(
                        _selectedAudienceMode == 'all'
                            ? 'No $_selectedSlot items yet.\nTap Add Menu Item to create one.'
                            : 'No ${_selectedAudienceMode == 'north' ? 'North Indian' : 'South Indian'} $_selectedSlot items yet.\nTap Add Menu Item to create one.',
                        textAlign: TextAlign.center,
                        style:
                            PsgText.body(14, color: PsgColors.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...selected.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MenuItemCard(
                          item: item,
                          onEdit: () => _openItemDialog(item),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onEdit,
  });

  final FoodTokenItemModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<FoodTokenInventoryController>();
    final color = item.isActive ? PsgColors.primary : PsgColors.outline;

    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (item.emoji != null && item.emoji!.trim().isNotEmpty)
                      ? item.emoji!.trim()
                      : '🍽️',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style:
                            PsgText.headline(16, color: PsgColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${item.price.toStringAsFixed(item.price == item.price.toInt() ? 0 : 2)} • Max ${item.limitPerPerson}/person • Stock ${item.totalQuantity}',
                      style:
                          PsgText.body(12, color: PsgColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.isActive,
                onChanged: (value) {
                  controller.updateItem(item.id, {'isActive': value});
                },
                activeThumbColor: PsgColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(label: item.mealSlot, color: PsgColors.primary),
              _ChipLabel(label: item.audience, color: Colors.indigo),
              _ChipLabel(
                label: item.isVeg ? 'Veg' : 'Non-Veg',
                color: item.isVeg ? Colors.green : Colors.red,
              ),
              _ChipLabel(
                label: item.isActive ? 'Available' : 'Hidden',
                color: item.isActive ? PsgColors.green : PsgColors.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: PsgText.label(10, color: color, letterSpacing: 0.4),
      ),
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({
    required this.defaultSlot,
    this.item,
    this.forcedAudience,
  });

  final FoodTokenItemModel? item;
  final String defaultSlot;
  final String? forcedAudience;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  static const _slots = ['Breakfast', 'Lunch', 'Dinner'];
  static const _audiences = ['Both', 'South Indian', 'North Indian'];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _stockCtrl;

  late String _mealSlot;
  late String _audience;
  bool _isVeg = true;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _emojiCtrl = TextEditingController(text: item?.emoji ?? '');
    _priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    _limitCtrl =
        TextEditingController(text: item?.limitPerPerson.toString() ?? '1');
    _stockCtrl =
        TextEditingController(text: item?.totalQuantity.toString() ?? '50');
    _mealSlot = item?.mealSlot ?? widget.defaultSlot;
    _audience = widget.forcedAudience ?? item?.audience ?? 'Both';
    _isVeg = item?.isVeg ?? true;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _priceCtrl.dispose();
    _limitCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final limit = int.tryParse(_limitCtrl.text.trim()) ?? 1;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    if (name.isEmpty || price <= 0 || limit <= 0 || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final controller = context.read<FoodTokenInventoryController>();
    bool ok;

    if (widget.item == null) {
      ok = await controller.addItem(
        FoodTokenItemModel(
          id: '',
          name: name,
          price: price,
          limitPerPerson: limit,
          totalQuantity: stock,
          mealSlot: _mealSlot,
          audience: _audience,
          isVeg: _isVeg,
          emoji: emoji.isEmpty ? null : emoji,
          isActive: _isActive,
        ),
      );
    } else {
      ok = await controller.updateItem(widget.item!.id, {
        'name': name,
        'itemName': name,
        'price': price,
        'limitPerPerson': limit,
        'totalQuantity': stock,
        'mealSlot': _mealSlot,
        'audience': _audience,
        'messCategory': _audience,
        'isVeg': _isVeg,
        'emoji': emoji.isEmpty ? null : emoji,
        'isActive': _isActive,
      });
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.item == null ? 'Menu item added.' : 'Menu item updated.'),
          backgroundColor: PsgColors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to save item.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _mealSlot,
              decoration: const InputDecoration(labelText: 'Meal Slot'),
              items: _slots
                  .map((slot) =>
                      DropdownMenuItem(value: slot, child: Text(slot)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _mealSlot = value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Visible For'),
              items: _audiences
                  .map(
                    (audience) => DropdownMenuItem(
                      value: audience,
                      child: Text(audience),
                    ),
                  )
                  .toList(),
              onChanged: widget.forcedAudience != null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _audience = value);
                      }
                    },
              disabledHint: Text(widget.forcedAudience ?? _audience),
            ),
            if (widget.forcedAudience != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Audience is fixed from the selected management view.',
                  style: PsgText.body(11, color: PsgColors.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _emojiCtrl,
              decoration: const InputDecoration(labelText: 'Emoji (optional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max per student'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock quantity'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Veg item'),
              value: _isVeg,
              onChanged: (v) => setState(() => _isVeg = v),
            ),
            SwitchListTile(
              title: const Text('Visible to students'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _AudienceMode {
  final String label;
  final String value;

  const _AudienceMode({required this.label, required this.value});
}
