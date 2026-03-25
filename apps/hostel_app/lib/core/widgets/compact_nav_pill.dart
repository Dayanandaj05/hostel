import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/psg_design_system.dart';
import '../config/navbar_items.dart';

class CompactNavPill extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const CompactNavPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CompactNavPill> createState() => _CompactNavPillState();
}

class _CompactNavPillState extends State<CompactNavPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: PsgDurations.standard,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: PsgCurves.snappy),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _selectItem(int index) {
    widget.onTap(index);
    _toggleExpand();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Expanded menu (appears behind pill)
            if (_isExpanded)
              GestureDetector(
                onTap: _toggleExpand,
                child: Container(color: Colors.transparent),
              ),

            // Animated pill container
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final expandProgress = _expandAnimation.value;
                final width = isMobile
                    ? 60 +
                          expandProgress *
                              (MediaQuery.of(context).size.width - 92)
                    : 60 + expandProgress * 200;
                final itemsVisible = widget.items.length;

                return Padding(
                  padding: EdgeInsets.only(bottom: expandProgress * 70),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 24 + expandProgress * 18,
                        sigmaY: 24 + expandProgress * 18,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 0),
                        width: width,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 + expandProgress * 4,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.46 - expandProgress * 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PsgColors.primary.withValues(
                                alpha: 0.16 - expandProgress * 0.06,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _isExpanded
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    itemsVisible,
                                    (i) => _buildNavItem(i),
                                  ),
                                ),
                              )
                            : _buildCollapsedPill(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedPill() {
    return GestureDetector(
      onTap: _toggleExpand,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Icon(Icons.menu_rounded, color: PsgColors.primary, size: 20),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isActive = index == widget.currentIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectItem(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: PsgDurations.standard,
          curve: PsgCurves.snappy,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [PsgColors.primary, PsgColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: PsgColors.primaryContainer.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: PsgDurations.fast,
                child: Icon(
                  item.icon,
                  color: isActive ? Colors.white : PsgColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: PsgDurations.fast,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : PsgColors.primary,
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
      ),
    );
  }
}
