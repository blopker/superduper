const _colors = [
  (start: 0xff441DFC, end: 0xff4E81EB),
  (start: 0xff2E3192, end: 0xff1BFFFF),
  (start: 0xffD4145A, end: 0xffFBB03B),
  (start: 0xff009245, end: 0xffFCEE21),
  (start: 0xff662D8C, end: 0xffED1E79),
  (start: 0xffEE9CA7, end: 0xffFFDDE1),
  (start: 0xff614385, end: 0xff516395),
  (start: 0xff02AABD, end: 0xff00CDAC),
  (start: 0xffFF512F, end: 0xffDD2476),
  (start: 0xffFF5F6D, end: 0xffFFC371),
  (start: 0xff11998E, end: 0xff38EF7D),
  (start: 0xffC6EA8D, end: 0xffFE90AF),
  (start: 0xffEA8D8D, end: 0xffA890FE),
  (start: 0xffD8B5FF, end: 0xff1EAE98),
  (start: 0xffFF61D2, end: 0xffFE9090),
  (start: 0xffBFF098, end: 0xff6FD6FF),
  (start: 0xff4E65FF, end: 0xff92EFFD),
  (start: 0xffA9F1DF, end: 0xffFFBBBB),
  (start: 0xffC33764, end: 0xff1D2671),
  (start: 0xff93A5CF, end: 0xffE4EfE9),
  (start: 0xff868F96, end: 0xff596164),
  (start: 0xff09203F, end: 0xff537895),
  (start: 0xffFFECD2, end: 0xffFCB69F),
  (start: 0xffA1C4FD, end: 0xffC2E9FB),
  (start: 0xff764BA2, end: 0xff667EEA),
  (start: 0xffFDFCFB, end: 0xffE2D1C3)
];

getColor(int index) {
  return _colors[index];
}

getColorList() {
  return _colors.map((e) => (start: e.start, end: e.end)).toList();
}
