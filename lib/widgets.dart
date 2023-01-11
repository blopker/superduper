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
          padding: EdgeInsets.only(right: 10, left: 10),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Color(0xff4A80F0) : Color(0xff1C2031),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Color(0xff4A80F0).withOpacity(0.3),
                          offset: Offset(0, 4),
                          blurRadius: 20),
                    ]
                  : [],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Text(
                  widget.text!,
                  style: TextStyle(
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
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final double? height;
  final double? width;
  final Widget? vectorBottom;
  final Widget? vectorTop;
  final Function? onTap;
  final String? tag;
  final bool selected;
  const DiscoverCard(
      {Key? key,
      this.title,
      this.subtitle,
      this.gradientStartColor,
      this.gradientEndColor,
      this.height,
      this.width,
      this.vectorBottom,
      this.vectorTop,
      this.onTap,
      this.tag,
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
        onTap: () => onTap!(),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                startColor ?? Color(0xff441DFC),
                endColor ?? Color(0xff4E81EB),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Container(
            // height: 176,
            // width: 305,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 24, top: 24, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: tag ?? '',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                title!,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          subtitle != null
                              ? Text(
                                  subtitle!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
