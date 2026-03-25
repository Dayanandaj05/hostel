import 'package:flutter/material.dart';
import 'package:hostel_app/services/mock/mock_data.dart';

class AdminMessMenuScreen extends StatelessWidget {
  const AdminMessMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = MockData.messMenuBySlot.entries.toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Menu')),
      body: ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, i) {
          final slot = slots[i];
          return ExpansionTile(
            title: Text(slot.key),
            children: slot.value
                .map((item) => ListTile(
                      title: Text(item['itemName']?.toString() ?? ''),
                      trailing: Text('₹${item['price']}'),
                    ))
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
