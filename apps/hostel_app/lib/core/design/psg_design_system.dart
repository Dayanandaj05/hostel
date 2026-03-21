// ─────────────────────────────────────────────────────────────────────────────
// PSG HOSTEL  —  Design System
// Glassmorphism  |  Manrope headlines  |  Inter body  |  Primary #003F87
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COLOURS
// ══════════════════════════════════════════════════════════════════════════════
abstract class PsgColors {
  static const primary            = Color(0xFF003F87);
  static const primaryContainer   = Color(0xFF0056B3);
  static const secondary          = Color(0xFF366288);
  static const secondaryContainer = Color(0xFFA9D3FF);
  static const error              = Color(0xFFBA1A1A);
  static const errorContainer     = Color(0xFFFFDAD6);
  static const background         = Color(0xFFF7F9FB);
  static const onSurface          = Color(0xFF191C1E);
  static const onSurfaceVariant   = Color(0xFF424752);
  static const outline            = Color(0xFF727784);
  static const green              = Color(0xFF15803D);
  static const amber              = Color(0xFFB45309);

  // Glass
  static Color glass(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassBorder()         => Colors.white.withOpacity(0.20);
  static Color glassShadow()         => primary.withOpacity(0.06);
}

// ══════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ══════════════════════════════════════════════════════════════════════════════
abstract class PsgText {
  static TextStyle headline(double size,
          {FontWeight weight = FontWeight.w900, Color? color}) =>
      GoogleFonts.manrope(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: -0.5,
          color: color);

  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label(double size,
          {FontWeight weight = FontWeight.w700,
          double letterSpacing = 0.8,
          Color? color}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          color: color);
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME
// ══════════════════════════════════════════════════════════════════════════════
abstract class PsgTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PsgColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PsgColors.primary,
        primary: PsgColors.primary,
        secondary: PsgColors.secondary,
        error: PsgColors.error,
        surface: PsgColors.background,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: PsgColors.primaryContainer,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PsgColors.primaryContainer, width: 1.5),
        ),
        labelStyle: PsgText.label(12,
            weight: FontWeight.w700,
            letterSpacing: 1.4,
            color: PsgColors.primary),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MESH GRADIENT BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
class MeshBackground extends StatelessWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: PsgColors.background),
      // top-left blue blob
      Positioned(
        top: -40, left: -40,
        child: _blob(320, const Color(0xFF0056B3), 0.18)),
      // top-right sky blob
      Positioned(
        top: -20, right: -60,
        child: _blob(280, const Color(0xFFA9D3FF), 0.22)),
      // bottom-right deep blob
      Positioned(
        bottom: -60, right: -40,
        child: _blob(260, const Color(0xFF003F87), 0.12)),
      // bottom-left light blob
      Positioned(
        bottom: -40, left: -40,
        child: _blob(260, const Color(0xFFACC7FF), 0.22)),
      child,
    ]);
  }

  Widget _blob(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0)]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ══════════════════════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? shadowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.40),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? PsgColors.primary).withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCROLL-AWARE GLASS APP BAR
// ══════════════════════════════════════════════════════════════════════════════
class PsgGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double scrollOffset;
  final List<Widget>? actions;
  final Widget? leading;
  final String? title;

  const PsgGlassAppBar({
    super.key,
    this.scrollOffset = 0,
    this.actions,
    this.leading,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final t = (scrollOffset / 60).clamp(0.0, 1.0);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: 40 * t.toDouble(), sigmaY: 40 * t.toDouble()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.40 * t),
            border: Border(
              bottom:
                  BorderSide(color: Colors.white.withOpacity(0.20 * t)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                if (title == null) ...[
                  const Icon(Icons.school_rounded,
                      color: PsgColors.primaryContainer, size: 28),
                  const SizedBox(width: 8),
                  Text('PSG HOSTEL',
                      style: PsgText.headline(20,
                          color: PsgColors.primaryContainer)),
                ] else
                  Text(title!,
                      style: PsgText.headline(20,
                          color: PsgColors.primaryContainer)),
                const Spacer(),
                if (actions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATED GLASS BOTTOM NAV
// ══════════════════════════════════════════════════════════════════════════════
class PsgBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PsgNavItem> items;

  const PsgBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.40),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: Colors.white.withOpacity(0.20)),
                boxShadow: [
                  BoxShadow(
                    color: PsgColors.primary.withOpacity(0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final active = i == currentIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                          horizontal: active ? 20 : 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(
                                colors: [
                                  PsgColors.primary,
                                  PsgColors.primaryContainer
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
                                      .withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active
                                ? items[i].activeIcon ?? items[i].icon
                                : items[i].icon,
                            color: active
                                ? Colors.white
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            style: PsgText.label(8,
                                letterSpacing: 0.8,
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade500),
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
    );
  }
}

class PsgNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  const PsgNavItem(
      {required this.icon, required this.label, this.activeIcon});
}

// ══════════════════════════════════════════════════════════════════════════════
// GRADIENT FILLED BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class PsgFilledButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PsgFilledButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<PsgFilledButton> createState() => _PsgFilledButtonState();
}

class _PsgFilledButtonState extends State<PsgFilledButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [PsgColors.primary, PsgColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: PsgColors.primaryContainer.withOpacity(0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.loading
                ? [
                    const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                  ]
                : [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(widget.label,
                        style: PsgText.label(14,
                            letterSpacing: 1.0, color: Colors.white)),
                  ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATUS CHIPS
// ══════════════════════════════════════════════════════════════════════════════
class PsgStatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const PsgStatusChip._({
    required this.label,
    required this.bg,
    required this.fg,
  });

  factory PsgStatusChip.approved() => const PsgStatusChip._(
      label: 'APPROVED',
      bg: Color(0xFFDCFCE7),
      fg: Color(0xFF15803D));

  factory PsgStatusChip.pending() => const PsgStatusChip._(
      label: 'PENDING',
      bg: Color(0xFFFEF9C3),
      fg: Color(0xFFB45309));

  factory PsgStatusChip.rejected() => const PsgStatusChip._(
      label: 'REJECTED',
      bg: Color(0xFFFFDAD6),
      fg: Color(0xFFBA1A1A));

  factory PsgStatusChip.fromString(String status) {
    return switch (status.toLowerCase()) {
      'approved' => PsgStatusChip.approved(),
      'rejected' => PsgStatusChip.rejected(),
      _ => PsgStatusChip.pending(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: PsgText.label(9, letterSpacing: 0.8, color: fg)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER ROW
// ══════════════════════════════════════════════════════════════════════════════
class PsgSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const PsgSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(),
            style: PsgText.label(10,
                letterSpacing: 1.4, color: PsgColors.secondary)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(action!,
                  style: PsgText.label(11,
                      letterSpacing: 0.4, color: PsgColors.primary)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: PsgColors.primary),
            ]),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAGGERED ENTRY ANIMATION WRAPPER
// ══════════════════════════════════════════════════════════════════════════════
class StaggeredEntry extends StatelessWidget {
  final Widget child;
  final int index;
  final int baseDurationMs;

  const StaggeredEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDurationMs = 400,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: baseDurationMs + index * 60),
      curve: Curves.easeOutCubic,
      builder: (_, val, innerChild) => Opacity(
        opacity: val,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - val)), child: innerChild),
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE ENTRY MIXIN  (add to State classes)
// ══════════════════════════════════════════════════════════════════════════════
mixin PsgPageEntry<T extends StatefulWidget> on State<T>,
    SingleTickerProviderStateMixin<T> {
  late final AnimationController entryController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  void initPageEntry() {
    entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    fadeAnim =
        CurvedAnimation(parent: entryController, curve: Curves.easeOut);
    slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
            CurvedAnimation(parent: entryController, curve: Curves.easeOut));
    entryController.forward();
  }

  Widget withEntry(Widget child) => FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(position: slideAnim, child: child));

  @override
  void dispose() {
    entryController.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AVATAR CHIP
// ══════════════════════════════════════════════════════════════════════════════
class PsgAvatarInitials extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const PsgAvatarInitials(
      {super.key, required this.name, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: (color ?? PsgColors.primaryContainer).withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: PsgText.headline(size * 0.35,
                color: color ?? PsgColors.primaryContainer)),
      ),
    );
  }
}
