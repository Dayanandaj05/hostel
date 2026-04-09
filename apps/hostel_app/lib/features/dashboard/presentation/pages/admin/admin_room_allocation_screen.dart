import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_app/core/design/psg_design_system.dart';

class AdminRoomAllocationScreen extends StatefulWidget {
  const AdminRoomAllocationScreen({super.key});

  @override
  State<AdminRoomAllocationScreen> createState() => _AdminRoomAllocationScreenState();
}

class _AdminRoomAllocationScreenState extends State<AdminRoomAllocationScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoomSheet(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final currentRoom = data['roomNumber'] ?? '';
    final roomCtrl = TextEditingController(text: currentRoom);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: GlassCard(
                borderRadius: 32,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Allocate Room for $name', style: PsgText.headline(20, color: PsgColors.primary)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: roomCtrl,
                      style: PsgText.body(14, color: PsgColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Room Number',
                        hintText: 'e.g. A-101',
                        labelStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: PsgColors.primary), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PsgFilledButton(
                      label: 'Save Room',
                      loading: isSaving,
                      onPressed: () async {
                        final newRoom = roomCtrl.text.trim();
                        if (newRoom == currentRoom) {
                          Navigator.pop(context);
                          return;
                        }

                        setSheetState(() => isSaving = true);
                        try {
                          await doc.reference.update({
                            'roomNumber': newRoom,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room updated seamlessly')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (context.mounted) setSheetState(() => isSaving = false);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: PsgColors.primary, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
          ),
          title: 'Room Allocation',
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: PsgText.body(14, color: PsgColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search by name or roll number',
                      hintStyle: PsgText.body(14, color: PsgColors.onSurfaceVariant),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search_rounded, color: PsgColors.outline),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: PsgColors.primary));
                    if (snapshot.hasError) return Center(child: Text('Error loading users', style: PsgText.body(14, color: PsgColors.error)));
                    
                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final roll = (data['rollNumber'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || roll.contains(_searchQuery);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 60, color: PsgColors.outline),
                            const SizedBox(height: 16),
                            Text('No students found', style: PsgText.label(16, color: PsgColors.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Unknown Student';
                        final roll = data['rollNumber'] ?? 'N/A';
                        final room = data['roomNumber'] ?? '';

                        final hasRoom = room.toString().trim().isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _showRoomSheet(doc),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: PsgColors.primary.withValues(alpha: 0.15),
                                    child: const Icon(Icons.person, color: PsgColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: PsgText.headline(16, color: PsgColors.onSurface)),
                                        Text('Roll: $roll', style: PsgText.body(12, color: PsgColors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: hasRoom ? PsgColors.green.withValues(alpha: 0.15) : PsgColors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: hasRoom ? PsgColors.green.withValues(alpha: 0.3) : PsgColors.amber.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('ROOM', style: PsgText.label(9, color: hasRoom ? PsgColors.green : PsgColors.amber)),
                                        Text(hasRoom ? room : 'Unassigned', style: PsgText.headline(12, color: hasRoom ? PsgColors.green : PsgColors.amber)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
