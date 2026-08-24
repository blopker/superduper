import 'package:flutter/material.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/theme/app_theme.dart';

final class AppPageBody extends StatelessWidget {
  const AppPageBody({required this.child, this.maxWidth = 760, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _BackgroundGlow(),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

final class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 42, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Superduper',
      image: true,
      child: Image.asset(
        'assets/superduper-nobg.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

final class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: compact ? 34 : 44),
        SizedBox(width: compact ? 8 : 11),
        Text(
          'SUPERDUPER',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.eyebrow,
    this.action,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.magentaSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 16), action!],
      ],
    );
  }
}

final class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

final class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class BikeAvatar extends StatelessWidget {
  const BikeAvatar({required this.color, this.size = 58, super.key});

  final BikeColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = color.gradientColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        Icons.electric_bike_rounded,
        color: color.iconColor,
        size: size * 0.52,
      ),
    );
  }
}

final class BikeColorLabel extends StatelessWidget {
  const BikeColorLabel({required this.color, super.key});

  final BikeColor color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: color.gradientColors),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(color.displayName)),
      ],
    );
  }
}

extension BikeColorDesign on BikeColor {
  List<Color> get gradientColors => _bikeGradients[legacyIndex];

  Color get iconColor {
    return switch (this) {
      BikeColor.pureWhite ||
      BikeColor.silverMist ||
      BikeColor.vanillaLatte ||
      BikeColor.sunKissed ||
      BikeColor.peachCream ||
      BikeColor.iceDrop => AppColors.ink,
      _ => Colors.white,
    };
  }
}

const _bikeGradients = <List<Color>>[
  [Color(0xFF173D73), Color(0xFFF278A7)],
  [Color(0xFF053B58), Color(0xFF36C3C8)],
  [Color(0xFFFF503B), Color(0xFFFFB745)],
  [Color(0xFF09A36D), Color(0xFFB7F53F)],
  [Color(0xFF9C176E), Color(0xFFFF5A9D)],
  [Color(0xFFF28FD3), Color(0xFF8AC9FF)],
  [Color(0xFF3E216E), Color(0xFFED4A9C)],
  [Color(0xFF00A8A8), Color(0xFF8AF1DB)],
  [Color(0xFFEF168E), Color(0xFFFF713D)],
  [Color(0xFFFFB08E), Color(0xFFFFE0B2)],
  [Color(0xFF087B61), Color(0xFF30D69A)],
  [Color(0xFFA58AFF), Color(0xFFFFB4D9)],
  [Color(0xFF8E70CF), Color(0xFFE1C7FF)],
  [Color(0xFF72DDB2), Color(0xFFCEF7BB)],
  [Color(0xFFFF5CAD), Color(0xFFFF9AD3)],
  [Color(0xFF5CAFF2), Color(0xFFB8E5FF)],
  [Color(0xFF006A92), Color(0xFF25D0D6)],
  [Color(0xFF9ADBC6), Color(0xFFE8FFF8)],
  [Color(0xFF131126), Color(0xFF483A72)],
  [Color(0xFFAAB3C1), Color(0xFFF1F3F6)],
  [Color(0xFF414651), Color(0xFF89929F)],
  [Color(0xFF07243D), Color(0xFF0C6682)],
  [Color(0xFFFFBC46), Color(0xFFFFE398)],
  [Color(0xFFA6DBF1), Color(0xFFEAFBFF)],
  [Color(0xFF5121A4), Color(0xFFA264F4)],
  [Color(0xFFD5B892), Color(0xFFFFEDD1)],
  [Color(0xFFE7E8EC), Color(0xFFFFFFFF)],
  [Color(0xFF090A0D), Color(0xFF30323A)],
  [Color(0xFF00D8C8), Color(0xFFFF2BAD)],
  [Color(0xFF42208E), Color(0xFFFF318B)],
  [Color(0xFF1751D0), Color(0xFF24BCFF)],
  [Color(0xFF07152F), Color(0xFF203F78)],
];

final class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.85, -1.05),
            radius: 0.9,
            colors: [Color(0x241F0929), AppColors.ink],
            stops: [0, 0.62],
          ),
        ),
      ),
    );
  }
}
