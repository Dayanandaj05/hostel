import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';
import 'package:hostel_app/features/tokens/domain/entities/food_token_model.dart';
import 'package:hostel_app/features/tokens/presentation/controllers/food_token_controller.dart';

const _kNavy = Color(0xFF0D2137);
const _kTeal = Color(0xFF009688);

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FoodItem? _selectedItem;
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'Lunch';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start watching tokens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<FoodTokenController>().startWatchingTokens(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleBookToken() async {
    if (_selectedItem == null) return;

    final controller = context.read<FoodTokenController>();
    final uid = AuthProviderController.of(context).user?.uid;
    
    if (uid == null) return;

    final success = await controller.bookToken(
      userId: uid,
      item: _selectedItem!,
      quantity: _quantity,
      tokenDate: _selectedDate,
      mealSlot: _selectedSlot,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.successMessage ?? 'Token booked!')),
      );
      // Reset selection
      setState(() {
        _selectedItem = null;
        _quantity = 1;
      });
      // Switch to My Tokens tab
      _tabController.animateTo(1);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Booking failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book My Token', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _kNavy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Book Token'),
            Tab(text: 'My Tokens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookTab(),
          _buildMyTokensTab(),
        ],
      ),
    );
  }

  Widget _buildBookTab() {
    final curTheme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Food Item',
            style: curTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: kFoodItems.length,
              itemBuilder: (context, index) {
                final item = kFoodItems[index];
                final isSelected = _selectedItem?.id == item.id;
                return _buildFoodCard(item, isSelected);
              },
            );
          }),
          const SizedBox(height: 24),
          _buildSelectionControls(),
          const SizedBox(height: 32),
          _buildBookingSummary(),
          const SizedBox(height: 24),
          Consumer<FoodTokenController>(
            builder: (context, controller, child) {
              return SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedItem == null || controller.isBooking) ? null : _handleBookToken,
                  child: controller.isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Book Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodItem item, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedItem = item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _kNavy.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kNavy : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price}',
                    style: const TextStyle(color: _kTeal, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.isVeg ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: _kNavy, size: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildControlSection(
                title: 'Select Date',
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text('${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildControlSection(
          title: 'Meal Slot',
          child: Row(
            children: ['Breakfast', 'Lunch', 'Dinner'].map((slot) {
              final isSelected = _selectedSlot == slot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: _kNavy,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  onSelected: (val) {
                    if (val) setState(() => _selectedSlot = slot);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _buildControlSection(
          title: 'Quantity',
          child: Row(
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 28, color: _kNavy),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add_circle_outline, size: 28, color: _kNavy),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedItem == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            '₹${_selectedItem!.price * _quantity}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTokensTab() {
    return Consumer<FoodTokenController>(
      builder: (context, controller, child) {
        if (controller.isLoadingTokens) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.myTokens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No tokens booked yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myTokens.length,
          itemBuilder: (context, index) {
            final token = controller.myTokens[index];
            return _buildTokenCard(token, controller);
          },
        );
      },
    );
  }

  Widget _buildTokenCard(FoodTokenModel token, FoodTokenController controller) {
    final foodItem = kFoodItems.firstWhere((i) => i.id == token.foodItemId, 
        orElse: () => FoodItem(id: '', name: token.foodItemName, price: token.pricePerItem, emoji: '🍱', isVeg: true));
    
    final canCancel = token.isActive && (token.tokenDate.isAfter(DateTime.now().subtract(const Duration(days: 1))));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kNavy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(foodItem.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(token.foodItemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildStatusChip(token.isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${token.tokenDate.day.toString().padLeft(2, '0')} ${_getMonthName(token.tokenDate.month)} ${token.tokenDate.year} • ${token.mealSlot}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${token.quantity} × ₹${token.pricePerItem}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Total: ₹${token.totalPrice}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
                    ),
                  ],
                ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: controller.isCancelling 
                        ? null 
                        : () async {
                            final success = await controller.cancelToken(token.id!);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Token cancelled!')),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: controller.isCancelling && controller.errorMessage == null // Simplified check
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                        : const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Expired',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
