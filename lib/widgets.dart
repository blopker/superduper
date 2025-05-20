import 'package:flutter/material.dart';
import 'package:superduper/colors.dart';

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? metric;
  final int colorIndex;
  final double? height;
  final double? width;
  final Widget? vectorBottom;
  final Widget? vectorTop;
  final Function()? onTap;
  final Function()? onLongPress;
  final String? tag;
  final bool selected;
  final IconData? titleIcon;

  const DiscoverCard(
      {super.key,
      this.title,
      this.subtitle,
      this.height,
      this.width,
      this.vectorBottom,
      this.vectorTop,
      this.onTap,
      this.onLongPress,
      this.tag,
      this.metric,
      this.colorIndex = 0,
      this.selected = true,
      this.titleIcon});

  @override
  Widget build(BuildContext context) {
    var defaultColors = getColor(colorIndex);
    var startColor = defaultColors.start;
    var endColor = defaultColors.end;
    var textColor = defaultColors.fontColor();

    if (!selected) {
      startColor = Colors.grey[800]!;
      endColor = Colors.grey[800]!;
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                startColor,
                endColor,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 24, top: 20, bottom: 20, right: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (titleIcon != null) // Check if there's an icon
                            Icon(
                              titleIcon,
                              size: 24, // Adjust the size as needed
                              color: textColor,
                            ),
                          if (titleIcon !=
                              null) // Add spacing if there's an icon
                            const SizedBox(width: 10),
                          if (title != null)
                            Text(
                              title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: textColor),
                            ),
                        ],
                      ),
                      if (subtitle != null)
                        Column(
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              subtitle!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ).copyWith(color: textColor),
                            ),
                          ],
                        ),
                      if (vectorBottom != null)
                        Column(
                          children: [const SizedBox(height: 12), vectorBottom!],
                        )
                    ],
                  ),
                ),
                metric != null
                    ? Text(
                        metric!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: textColor),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
