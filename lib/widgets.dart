import 'package:flutter/material.dart';

class CategoryBoxes extends StatefulWidget {
  final Function(bool isSelected)? onPressed;
  final String? text;

  const CategoryBoxes({Key? key, this.onPressed, this.text}) : super(key: key);

  @override
  State<CategoryBoxes> createState() => _CategoryBoxesState();
}

class _CategoryBoxesState extends State<CategoryBoxes> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isSelected = !isSelected;
            widget.onPressed!(isSelected);
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? const Color(0xff4A80F0)
                  : const Color(0xff1C2031),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: const Color(0xff4A80F0).withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 20),
                    ]
                  : [],
            ),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Text(
                  widget.text!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscoverCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? metric;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final double? height;
  final double? width;
  final bool locked;
  final Widget? vectorBottom;
  final Widget? vectorTop;
  final Function()? onTap;
  final Function()? onLongPress;
  final String? tag;
  final bool selected;
  const DiscoverCard(
      {Key? key,
      this.title,
      this.subtitle,
      this.locked = false,
      this.gradientStartColor,
      this.gradientEndColor,
      this.height,
      this.width,
      this.vectorBottom,
      this.vectorTop,
      this.onTap,
      this.onLongPress,
      this.tag,
      this.metric,
      this.selected = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var startColor = gradientStartColor;
    var endColor = gradientStartColor;
    if (!selected) {
      startColor = Colors.grey[800];
      endColor = Colors.grey[800];
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                startColor ?? const Color(0xff441DFC),
                endColor ?? const Color(0xff4E81EB),
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
                      Hero(
                        tag: tag ?? '',
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Text(
                                title!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              if (locked)
                                const Icon(Icons.lock,
                                    color: Colors.white, size: 16)
                            ],
                          ),
                        ),
                      ),
                      if (subtitle != null)
                        Column(
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              subtitle!,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white),
                            ),
                          ],
                        )
                    ],
                  ),
                ),
                metric != null
                    ? Text(
                        metric!,
                        style: Theme.of(context).textTheme.bodyMedium,
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
