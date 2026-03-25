import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../../app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../domain/entities/food_token_model.dart';
import '../../../presentation/controllers/food_token_controller.dart';

class MyTokensScreen extends StatefulWidget {
  const MyTokensScreen({super.key});
  @override
  State<MyTokensScreen> createState() => _MyTokensScreenState();
}

class _MyTokensScreenState extends State<MyTokensScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  late TabController _tabController;

  void _onBottomNavTap(int index) {
    final routeByIndex = {
      0: AppRoutes.studentHome,
      1: AppRoutes.studentTokens,
      2: AppRoutes.studentFees,
      3: AppRoutes.studentNotices,
      4: AppRoutes.studentLeave,
    };
    final route = routeByIndex[index];
    if (route != null) {
      context.go(route);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<FoodTokenController>().startWatchingTokens(uid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'My Tokens',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.studentTokens),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: PsgColors.primary),
              onPressed: () => context.go(AppRoutes.studentHome),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: PsgColors.primary,
                        unselectedLabelColor: PsgColors.onSurfaceVariant,
                        indicatorColor: PsgColors.secondary,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(text: '⏳ Active'),
                          Tab(text: '✓ History'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<FoodTokenController>(
                  builder: (context, controller, _) {
                    if (controller.isLoading && controller.myTokens.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final active = controller.myTokens
                        .where((t) => t.status == FoodTokenStatus.active)
                        .toList();
                    final history = controller.myTokens
                        .where((t) => t.status != FoodTokenStatus.active)
                        .toList();
                    return AnimatedSwitcher(
                      duration: PsgDurations.standard,
                      switchInCurve: PsgCurves.entrance,
                      switchOutCurve: PsgCurves.exit,
                      child: TabBarView(
                        key: ValueKey('${active.length}-${history.length}'),
                        controller: _tabController,
                        children: [
                          _buildList(active, 'No active tokens'),
                          _buildList(history, 'No token history'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PsgBottomNav(
          currentIndex: 1,
          onTap: _onBottomNavTap,
          scrollOffset: _scrollOffset,
          items: const [
            PsgNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'HOME',
            ),
            PsgNavItem(
              icon: Icons.restaurant_outlined,
              activeIcon: Icons.restaurant_rounded,
              label: 'MESS',
            ),
            PsgNavItem(
              icon: Icons.payments_outlined,
              activeIcon: Icons.payments_rounded,
              label: 'FEES',
            ),
            PsgNavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'NOTICES',
            ),
            PsgNavItem(
              icon: Icons.flight_takeoff_outlined,
              activeIcon: Icons.flight_takeoff_rounded,
              label: 'LEAVE',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<FoodTokenModel> tokens, String emptyMsg) {
    if (tokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: tokens.length,
      itemBuilder: (_, i) => _TokenCard(token: tokens[i]),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.token});
  final FoodTokenModel token;

  @override
  Widget build(BuildContext context) {
    final isActive = token.status == FoodTokenStatus.active;
    final statusColor = isActive ? const Color(0xFF009688) : Colors.grey;
    final mealIcon = switch ((token.mealSlot ?? '').toLowerCase()) {
      String s when s.contains('breakfast') => Icons.free_breakfast_rounded,
      String s when s.contains('dinner') => Icons.dinner_dining_rounded,
      _ => Icons.lunch_dining_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: PsgDurations.standard,
            curve: PsgCurves.snappy,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
              boxShadow: [
                BoxShadow(
                  color: PsgColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? const [Color(0xFF0D2137), Color(0xFF1E3A5F)]
                          : [Colors.grey.shade500, Colors.grey.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(mealIcon, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: PsgDurations.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF009688)
                              : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'USED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 100,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.itemName ?? 'Food Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0D2137),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          token.mealSlot ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _pill('Qty: ${token.quantity ?? 1}', Colors.indigo),
                            const SizedBox(width: 8),
                            _pill(
                              '₹${token.totalPrice?.toStringAsFixed(0) ?? '--'}',
                              const Color(0xFF009688),
                            ),
                          ],
                        ),
                        if (token.scheduledDate != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _fmt(token.scheduledDate!),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    isActive
                        ? Icons.qr_code_2_rounded
                        : Icons.check_circle_rounded,
                    color: statusColor,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
    ),
  );

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
