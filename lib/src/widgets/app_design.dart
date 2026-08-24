import 'package:flutter/material.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/theme/app_theme.dart';

final class BikeColorPalette {
  BikeColorPalette._({
    required this.accent,
    required this.onAccent,
    required this.secondary,
    required this.onSecondary,
    required this.panel,
    required this.panelRaised,
    required this.surfaceLow,
    required this.surfaceHighest,
    required this.outline,
    required this.outlineVariant,
  });

  factory BikeColorPalette.from(BikeColor color) {
    final sourceAccent = color.gradientColors.last;
    final sourceSecondary = color.gradientColors.first;
    final panel = color.panelTint;
    final panelRaised = Color.alphaBlend(
      sourceAccent.withValues(alpha: 0.16),
      AppColors.surfaceRaised,
    );
    final surfaceHighest = Color.alphaBlend(
      sourceAccent.withValues(alpha: 0.22),
      AppColors.surfaceRaised,
    );
    final accent = _accessibleAccent(sourceAccent, surfaceHighest);
    final secondary = _accessibleAccent(sourceSecondary, surfaceHighest);
    return BikeColorPalette._(
      accent: accent,
      onAccent: foregroundFor(accent),
      secondary: secondary,
      onSecondary: foregroundFor(secondary),
      panel: panel,
      panelRaised: panelRaised,
      surfaceLow: Color.alphaBlend(
        sourceAccent.withValues(alpha: 0.07),
        AppColors.inkLight,
      ),
      surfaceHighest: surfaceHighest,
      outline: Color.alphaBlend(
        sourceAccent.withValues(alpha: 0.34),
        AppColors.border,
      ),
      outlineVariant: Color.alphaBlend(
        sourceAccent.withValues(alpha: 0.18),
        AppColors.borderTint,
      ),
    );
  }

  final Color accent;
  final Color onAccent;
  final Color secondary;
  final Color onSecondary;
  final Color panel;
  final Color panelRaised;
  final Color surfaceLow;
  final Color surfaceHighest;
  final Color outline;
  final Color outlineVariant;

  static Color foregroundFor(Color background) {
    final inkContrast = _contrastRatio(background, AppColors.ink);
    final whiteContrast = _contrastRatio(background, Colors.white);
    return inkContrast >= whiteContrast ? AppColors.ink : Colors.white;
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color _accessibleAccent(Color preferred, Color background) {
    const minimumContrast = 4.5;
    if (_contrastRatio(preferred, background) >= minimumContrast) {
      return preferred;
    }
    final inkContrast = _contrastRatio(background, AppColors.ink);
    final whiteContrast = _contrastRatio(background, Colors.white);
    final target = inkContrast >= whiteContrast ? AppColors.ink : Colors.white;
    var lowerBound = 0.0;
    var upperBound = 1.0;
    var result = target;
    for (var iteration = 0; iteration < 24; iteration++) {
      final amount = (lowerBound + upperBound) / 2;
      final candidate = Color.lerp(preferred, target, amount)!;
      if (_contrastRatio(candidate, background) >= minimumContrast) {
        result = candidate;
        upperBound = amount;
      } else {
        lowerBound = amount;
      }
    }
    return result;
  }
}

final class BikeColorTheme extends StatelessWidget {
  const BikeColorTheme({
    required this.color,
    required this.child,
    super.key,
  });

  final BikeColor color;
  final Widget child;

  static BikeColorPalette? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BikeColorThemeScope>()
        ?.palette;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final palette = BikeColorPalette.from(color);
    final primaryContainer = Color.alphaBlend(
      palette.accent.withValues(alpha: 0.28),
      palette.panelRaised,
    );
    final secondaryContainer = Color.alphaBlend(
      palette.secondary.withValues(alpha: 0.24),
      palette.panelRaised,
    );
    final scheme = base.colorScheme.copyWith(
      primary: palette.accent,
      onPrimary: palette.onAccent,
      primaryContainer: primaryContainer,
      onPrimaryContainer: BikeColorPalette.foregroundFor(primaryContainer),
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: BikeColorPalette.foregroundFor(
        secondaryContainer,
      ),
      surface: palette.panel,
      surfaceContainerLowest: AppColors.ink,
      surfaceContainerLow: palette.surfaceLow,
      surfaceContainer: palette.panel,
      surfaceContainerHigh: palette.panelRaised,
      surfaceContainerHighest: palette.surfaceHighest,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      outline: palette.outline,
      outlineVariant: palette.outlineVariant,
    );
    final disabledForeground = AppColors.textMuted.withValues(alpha: 0.45);
    final textButtonStyle = base.textButtonTheme.style?.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabledForeground
            : palette.accent,
      ),
    );
    final outlinedButtonStyle = base.outlinedButtonTheme.style?.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabledForeground
            : palette.accent,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? palette.outline.withValues(alpha: 0.45)
              : palette.accent.withValues(alpha: 0.72),
        ),
      ),
    );
    final iconButtonStyle = base.iconButtonTheme.style?.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabledForeground
            : palette.accent,
      ),
    );

    final themed = base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: color.pageBaseColor,
      canvasColor: palette.panelRaised,
      cardTheme: base.cardTheme.copyWith(color: palette.panel),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: palette.panelRaised,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: palette.panelRaised,
      ),
      dividerTheme: base.dividerTheme.copyWith(color: palette.outlineVariant),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: palette.panel,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.accent, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlinedButtonStyle,
      ),
      iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
      listTileTheme: base.listTileTheme.copyWith(iconColor: palette.accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.outlineVariant,
        ),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: palette.accent,
        linearTrackColor: palette.panelRaised,
      ),
      textSelectionTheme: base.textSelectionTheme.copyWith(
        cursorColor: palette.accent,
        selectionColor: palette.accent.withValues(alpha: 0.34),
        selectionHandleColor: palette.accent,
      ),
    );

    return _BikeColorThemeScope(
      palette: palette,
      child: Theme(data: themed, child: child),
    );
  }
}

final class _BikeColorThemeScope extends InheritedWidget {
  const _BikeColorThemeScope({required this.palette, required super.child});

  final BikeColorPalette palette;

  @override
  bool updateShouldNotify(_BikeColorThemeScope oldWidget) {
    return palette.accent != oldWidget.palette.accent ||
        palette.secondary != oldWidget.palette.secondary;
  }
}

final class AppPageBody extends StatelessWidget {
  const AppPageBody({
    required this.child,
    this.maxWidth = 760,
    this.bikeColor,
    this.safeTop = true,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final BikeColor? bikeColor;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        gradient: bikeColor?.pageGradient,
      ),
      child: SafeArea(
        top: safeTop,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class BikePageScaffold extends StatelessWidget {
  const BikePageScaffold({
    required this.title,
    required this.color,
    required this.children,
    this.actions = const [],
    this.maxWidth = 760,
    super.key,
  });

  final String title;
  final BikeColor color;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return BikeColorTheme(
      color: color,
      child: Scaffold(
        backgroundColor: color.pageBaseColor,
        appBar: AppBar(title: Text(title.toUpperCase()), actions: actions),
        body: AppPageBody(
          maxWidth: maxWidth,
          bikeColor: color,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: children,
          ),
        ),
      ),
    );
  }
}

final class BikeHeader extends StatelessWidget {
  const BikeHeader({
    required this.color,
    required this.name,
    required this.isActive,
    this.region,
    this.trailing,
    this.avatarSize = 68,
    super.key,
  });

  final BikeColor color;
  final String name;
  final bool isActive;
  final BikeRegion? region;
  final Widget? trailing;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final palette = BikeColorPalette.from(color);
    return Row(
      children: [
        BikeAvatar(color: color, size: avatarSize),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: StatusPill(
                    label: 'Active bike',
                    color: palette.accent,
                  ),
                ),
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              if (region case final bikeRegion?) ...[
                const SizedBox(height: 3),
                Text('${bikeRegion.label} region'),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

final class BrandMasthead extends StatelessWidget {
  const BrandMasthead({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = (constraints.maxWidth * 0.255).clamp(104.0, 240.0);
        return Semantics(
          header: true,
          child: SizedBox(
            height: 108,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(0, -fontSize * 0.23),
                  child: Text(
                    'SUPERDUPER',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: 'monospace',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.8,
                      letterSpacing: -fontSize * 0.07,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    final accent =
        BikeColorTheme.maybeOf(context)?.accent ?? AppColors.magentaSoft;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Semantics(
                  label: eyebrow,
                  excludeSemantics: true,
                  child: Text(
                    eyebrow!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Semantics(
                label: title,
                header: true,
                excludeSemantics: true,
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
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
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final panel = BikeColorTheme.maybeOf(context)?.panel ?? AppColors.surface;
    return Material(
      color: color ?? panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ),
      ],
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
        color: colors.last,
        borderRadius: BorderRadius.circular(size * 0.34),
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
        SizedBox(
          width: 24,
          height: 18,
          child: DecoratedBox(
            key: const ValueKey('bike-color-swatch'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(colors: color.gradientColors),
            ),
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

  Color get pageBaseColor => Color.alphaBlend(
    gradientColors.first.withValues(alpha: 0.2),
    AppColors.ink,
  );

  LinearGradient get pageGradient {
    final colors = gradientColors;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0, 0.45, 1],
      colors: [
        pageBaseColor,
        Color.alphaBlend(colors.last.withValues(alpha: 0.1), AppColors.ink),
        AppColors.ink,
      ],
    );
  }

  Color get panelTint {
    return Color.alphaBlend(
      gradientColors.last.withValues(alpha: 0.11),
      AppColors.surface,
    );
  }

  Color get iconColor {
    return BikeColorPalette.foregroundFor(gradientColors.last);
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
