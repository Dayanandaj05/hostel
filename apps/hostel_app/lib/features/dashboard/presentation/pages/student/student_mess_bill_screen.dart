import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/app_routes.dart';
import '../../../../../core/design/psg_design_system.dart';
import '../../../../auth/presentation/controllers/auth_provider_controller.dart';
import '../../../../tokens/domain/entities/food_token_model.dart';
import '../../../../tokens/presentation/controllers/food_token_controller.dart';

class StudentMessBillScreen extends StatefulWidget {
  const StudentMessBillScreen({super.key});

  @override
  State<StudentMessBillScreen> createState() => _StudentMessBillScreenState();
}

class _StudentMessBillScreenState extends State<StudentMessBillScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () => setState(() => _scrollOffset = _scrollController.offset),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = AuthProviderController.of(context).user?.uid;
      if (uid != null) {
        context.read<FoodTokenController>().startWatchingTokens(uid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenController = context.watch<FoodTokenController>();
    final now = DateTime.now();

    final monthTokens = tokenController.myTokens.where((token) {
      final date = token.scheduledDate;
      if (date == null) return false;
      return date.year == now.year &&
          date.month == now.month &&
          token.status != FoodTokenStatus.cancelled;
    }).toList()
      ..sort((a, b) {
        final aDate = a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final total = monthTokens.fold<double>(0, (sum, token) {
      final lineTotal =
          token.totalPrice ?? ((token.itemPrice ?? 0) * (token.quantity ?? 1));
      return sum + lineTotal;
    });

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PsgGlassAppBar(
          scrollOffset: _scrollOffset,
          title: 'Mess Bill Details',
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: PsgColors.primary,
              size: 20,
            ),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.studentHome),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 88,
                16,
                10,
              ),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY TOTAL',
                          style: PsgText.label(
                            10,
                            letterSpacing: 1.0,
                            color: PsgColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: PsgText.body(12, color: PsgColors.onSurface),
                        ),
                      ],
                    ),
                    Text(
                      'Rs ${total.toStringAsFixed(0)}',
                      style: PsgText.headline(26, color: PsgColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: monthTokens.isEmpty
                  ? Center(
                      child: Text(
                        'No orders for this month yet.',
                        style:
                            PsgText.body(14, color: PsgColors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: monthTokens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final token = monthTokens[index];
                        final itemName = token.itemName ?? 'Food Item';
                        final qty = token.quantity ?? 1;
                        final unitPrice = token.itemPrice ?? 0;
                        final lineTotal = token.totalPrice ?? (unitPrice * qty);
                        final dateText = token.scheduledDate != null
                            ? DateFormat('dd MMM yyyy')
                                .format(token.scheduledDate!)
                            : 'Unknown date';

                        return GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      itemName,
                                      style: PsgText.label(
                                        14,
                                        color: PsgColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs ${lineTotal.toStringAsFixed(0)}',
                                    style: PsgText.label(
                                      14,
                                      color: PsgColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Qty: $qty  |  Unit: Rs ${unitPrice.toStringAsFixed(0)}  |  $dateText',
                                style: PsgText.body(
                                  12,
                                  color: PsgColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
