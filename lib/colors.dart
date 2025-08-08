import 'package:flutter/material.dart';

class ColorRange {
  late Color start;
  late Color end;
  late String name;

  ColorRange({required int start, required int end, required this.name}) {
    this.start = Color(start);
    this.end = Color(end);
  }
  ColorRange.clone(ColorRange other) {
    start = other.start;
    end = other.end;
    name = other.name;
  }
  Color fontColor() {
    return start.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  }
}

final _colors = [
  ColorRange(start: 0xff441DFC, end: 0xff4E81EB, name: "Royal Horizon"),
  ColorRange(start: 0xff2E3192, end: 0xff1BFFFF, name: "Ocean Mirage"),
  ColorRange(start: 0xffD4145A, end: 0xffFBB03B, name: "Sunset Blaze"),
  ColorRange(start: 0xff009245, end: 0xffFCEE21, name: "Electric Meadow"),
  ColorRange(start: 0xff662D8C, end: 0xffED1E79, name: "Berry Pop"),
  ColorRange(start: 0xffEE9CA7, end: 0xffFFDDE1, name: "Cotton Candy"),
  ColorRange(start: 0xff614385, end: 0xff516395, name: "Mystic Twilight"),
  ColorRange(start: 0xff02AABD, end: 0xff00CDAC, name: "Aqua Fresh"),
  ColorRange(start: 0xffFF512F, end: 0xffDD2476, name: "Fiery Fuchsia"),
  ColorRange(start: 0xffFF5F6D, end: 0xffFFC371, name: "Peach Cream"),
  ColorRange(start: 0xff11998E, end: 0xff38EF7D, name: "Emerald Wave"),
  ColorRange(start: 0xffC6EA8D, end: 0xffFE90AF, name: "Pastel Dream"),
  ColorRange(start: 0xffEA8D8D, end: 0xffA890FE, name: "Lavender Haze"),
  ColorRange(start: 0xffD8B5FF, end: 0xff1EAE98, name: "Mint Magic"),
  ColorRange(start: 0xffFF61D2, end: 0xffFE9090, name: "Bubblegum"),
  ColorRange(start: 0xffBFF098, end: 0xff6FD6FF, name: "Sky Breeze"),
  ColorRange(start: 0xff4E65FF, end: 0xff92EFFD, name: "Blue Lagoon"),
  ColorRange(start: 0xffA9F1DF, end: 0xffFFBBBB, name: "Frosted Mint"),
  ColorRange(start: 0xffC33764, end: 0xff1D2671, name: "Deep Space"),
  ColorRange(start: 0xff93A5CF, end: 0xffE4EfE9, name: "Silver Mist"),
  ColorRange(start: 0xff868F96, end: 0xff596164, name: "Stormy Gray"),
  ColorRange(start: 0xff09203F, end: 0xff537895, name: "Midnight Ocean"),
  ColorRange(start: 0xffFFECD2, end: 0xffFCB69F, name: "Sun Kissed"),
  ColorRange(start: 0xffA1C4FD, end: 0xffC2E9FB, name: "Ice Drop"),
  ColorRange(start: 0xff764BA2, end: 0xff667EEA, name: "Purple Rain"),
  ColorRange(start: 0xffFDFCFB, end: 0xffE2D1C3, name: "Vanilla Latte"),
  ColorRange(start: 0xffFFFFFF, end: 0xffFFFFFF, name: "Pure White"),
  ColorRange(start: 0xff282a36, end: 0xff282a36, name: "Dark Mode"),
  ColorRange(start: 0xff00F5A0, end: 0xff00D9F5, name: "Neon Cyber"),
  ColorRange(start: 0xffFF3CAC, end: 0xff784BA0, name: "Synthwave"),
  ColorRange(start: 0xff00C9FF, end: 0xff92FE9D, name: "Pixel Blue"),
  ColorRange(start: 0xff232526, end: 0xff414345, name: "Midnight Sky")
];

ColorRange getColor(int index) {
  return ColorRange.clone(_colors.elementAtOrNull(index) ?? _colors[0]);
}

List<ColorRange> getColorList() {
  return _colors.toList();
}
