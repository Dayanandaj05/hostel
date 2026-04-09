import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/design/psg_design_system.dart';

class AdminMessMenuScreen extends StatefulWidget {
  const AdminMessMenuScreen({super.key});

  @override
  State<AdminMessMenuScreen> createState() => _AdminMessMenuScreenState();
}

class _AdminMessMenuScreenState extends State<AdminMessMenuScreen> {
  static const _slots = ['Breakfast', 'Lunch', 'Dinner'];

  void _showAddDialog(BuildContext context, String slot) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Item to $slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (name.isNotEmpty) {
                FirebaseFirestore.instance.collection('mess_menu').add({
                  'slot': slot,
                  'itemName': name,
                  'price': price,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const PsgGlassAppBar(
          title: 'Manage Mess Menu',
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('mess_menu')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            // Group by slot
            final Map<String, List<QueryDocumentSnapshot>> grouped = {
              'Breakfast': [],
              'Lunch': [],
              'Dinner': [],
            };

            for (var doc in docs) {
              final slot = doc['slot'] as String?;
              if (slot != null && grouped.containsKey(slot)) {
                grouped[slot]!.add(doc);
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 16, right: 16),
              itemCount: _slots.length,
              itemBuilder: (context, i) {
                final slot = _slots[i];
                final items = grouped[slot] ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        slot,
                        style: PsgText.headline(18, color: PsgColors.primary),
                      ),
                      children: [
                        ...items.map((doc) => ListTile(
                              title: Text(doc['itemName'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${doc['price']}',
                                    style: PsgText.body(14, weight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: PsgColors.error),
                                    onPressed: () => FirebaseFirestore.instance
                                        .collection('mess_menu')
                                        .doc(doc.id)
                                        .delete(),
                                  ),
                                ],
                              ),
                            )),
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline, color: PsgColors.primary),
                          title: const Text('Add Item', style: TextStyle(color: PsgColors.primary)),
                          onTap: () => _showAddDialog(context, slot),
                        ),
                      ],
                    ),
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
