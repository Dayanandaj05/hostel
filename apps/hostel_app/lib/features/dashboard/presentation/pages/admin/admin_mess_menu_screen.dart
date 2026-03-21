import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../../app/app_routes.dart';

class AdminMessMenuScreen extends StatefulWidget {
  const AdminMessMenuScreen({super.key});

  @override
  State<AdminMessMenuScreen> createState() => _AdminMessMenuScreenState();
}

class _AdminMessMenuScreenState extends State<AdminMessMenuScreen> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Breakfast';
  String _selectedMess = 'North Indian';
  
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _saving = false;

  final List<String> _meals = ['Breakfast', 'Lunch', 'Dinner'];
  final List<String> _messes = ['North Indian', 'South Indian'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() => setState(() => _scrollOffset = _scrollController.offset));
    _fetchMenu();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _docId => "${DateFormat('yyyy-MM-dd').format(_selectedDate)}_${_selectedMeal}_${_selectedMess.split(' ')[0]}";

  Future<void> _fetchMenu() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('mess_menu').doc(_docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        _items = [];
      }
    } catch (e) {
      _snack('Error fetching menu: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveMenu() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('mess_menu').doc(_docId).set({
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'meal': _selectedMeal,
        'messType': _selectedMess,
        'items': _items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _snack('Menu saved successfully!', isSuccess: true);
    } catch (e) {
      _snack('Error saving menu: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add({'name': '', 'price': 0.0, 'maxQty': 1});
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _snack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? PsgColors.green : PsgColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Manage Mess Menu',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: PsgColors.primary, size: 20),
            onPressed: () => context.go(AppRoutes.adminDashboard),
          ),
        ),
        body: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 100, left: 24, right: 24,
          ),
          children: [
            _buildSelectors(),
            const SizedBox(height: 24),
            _buildItemsList(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _saveMenu,
          backgroundColor: PsgColors.primary,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, color: Colors.white),
          label: const Text('SAVE MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Date', style: PsgText.label(12, color: PsgColors.onSurfaceVariant)),
          subtitle: Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate), style: PsgText.headline(18, color: PsgColors.primary)),
          trailing: const Icon(Icons.calendar_today_rounded, color: PsgColors.primary),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 7)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _fetchMenu();
            }
          },
        ),
        const Divider(height: 32),
        // Meal & Mess
        Row(children: [
          Expanded(child: _dropdown('Meal', _selectedMeal, _meals, (v) {
            setState(() => _selectedMeal = v!);
            _fetchMenu();
          })),
          const SizedBox(width: 16),
          Expanded(child: _dropdown('Mess', _selectedMess, _messes, (v) {
            setState(() => _selectedMess = v!);
            _fetchMenu();
          })),
        ]),
      ]),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: PsgText.label(10, color: PsgColors.onSurfaceVariant)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: PsgText.body(14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  Widget _buildItemsList() {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Food Items', style: PsgText.headline(22, color: PsgColors.primary)),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
          ),
        ]),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No items added for this slot.', style: PsgText.body(14, color: PsgColors.onSurfaceVariant)))),
        ..._items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextFormField(
                    initialValue: item['name'],
                    onChanged: (v) => _items[i]['name'] = v,
                    decoration: const InputDecoration(labelText: 'Item Name', border: InputBorder.none),
                    style: PsgText.headline(16),
                  )),
                  IconButton(onPressed: () => _removeItem(i), icon: const Icon(Icons.delete_outline_rounded, color: PsgColors.error)),
                ]),
                const Divider(),
                Row(children: [
                  Expanded(child: _numberInput('Price (₹)', item['price'].toString(), (v) => _items[i]['price'] = double.tryParse(v) ?? 0.0)),
                  const SizedBox(width: 16),
                  Expanded(child: _numberInput('Max Qty', item['maxQty'].toString(), (v) => _items[i]['maxQty'] = int.tryParse(v) ?? 1)),
                ]),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _numberInput(String label, String initialValue, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: InputBorder.none),
      style: PsgText.body(15, weight: FontWeight.w600),
    );
  }
}
