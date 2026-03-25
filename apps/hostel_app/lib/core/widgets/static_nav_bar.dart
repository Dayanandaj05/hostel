import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/psg_design_system.dart';
import '../config/navbar_items.dart';

class StaticNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Map<String, int> badgeCounts;

  const StaticNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badgeCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PsgColors.primary.withValues(alpha: 0.12),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (i) {
                    final active = i == currentIndex;
                    final item = items[i];
                    final badgeCount = item.badgeKey != null
                        ? (badgeCounts[item.badgeKey] ?? 0)
                        : 0;
                    final hasBadge = badgeCount > 0;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: PsgDurations.standard,
                        curve: PsgCurves.snappy,
                        padding: EdgeInsets.symmetric(
                          horizontal: active ? 20 : 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(
                                  colors: [
                                    PsgColors.primary,
                                    PsgColors.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: PsgColors.primaryContainer
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedScale(
                                  scale: active ? 1.1 : 1.0,
                                  duration: PsgDurations.fast,
                                  child: Icon(
                                    item.icon,
                                    color: active
                                        ? Colors.white
                                        : PsgColors.primary,
                                    size: 18,
                                  ),
                                ),
                                if (hasBadge)
                                  Positioned(
                                    right: -8,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: PsgColors.error,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                      ),
                                      child: Text(
                                        badgeCount > 99 ? '99+' : '$badgeCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: PsgDurations.fast,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : PsgColors.primary,
                              ),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
