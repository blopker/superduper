const _colors = [
  (start: 0xff441DFC, end: 0xff4E81EB, name: "Royal Horizon"),
  (start: 0xff2E3192, end: 0xff1BFFFF, name: "Ocean Mirage"),
  (start: 0xffD4145A, end: 0xffFBB03B, name: "Sunset Blaze"),
  (start: 0xff009245, end: 0xffFCEE21, name: "Electric Meadow"),
  (start: 0xff662D8C, end: 0xffED1E79, name: "Berry Pop"),
  (start: 0xffEE9CA7, end: 0xffFFDDE1, name: "Cotton Candy"),
  (start: 0xff614385, end: 0xff516395, name: "Mystic Twilight"),
  (start: 0xff02AABD, end: 0xff00CDAC, name: "Aqua Fresh"),
  (start: 0xffFF512F, end: 0xffDD2476, name: "Fiery Fuchsia"),
  (start: 0xffFF5F6D, end: 0xffFFC371, name: "Peach Cream"),
  (start: 0xff11998E, end: 0xff38EF7D, name: "Emerald Wave"),
  (start: 0xffC6EA8D, end: 0xffFE90AF, name: "Pastel Dream"),
  (start: 0xffEA8D8D, end: 0xffA890FE, name: "Lavender Haze"),
  (start: 0xffD8B5FF, end: 0xff1EAE98, name: "Mint Magic"),
  (start: 0xffFF61D2, end: 0xffFE9090, name: "Bubblegum"),
  (start: 0xffBFF098, end: 0xff6FD6FF, name: "Sky Breeze"),
  (start: 0xff4E65FF, end: 0xff92EFFD, name: "Blue Lagoon"),
  (start: 0xffA9F1DF, end: 0xffFFBBBB, name: "Frosted Mint"),
  (start: 0xffC33764, end: 0xff1D2671, name: "Deep Space"),
  (start: 0xff93A5CF, end: 0xffE4EfE9, name: "Silver Mist"),
  (start: 0xff868F96, end: 0xff596164, name: "Stormy Gray"),
  (start: 0xff09203F, end: 0xff537895, name: "Midnight Ocean"),
  (start: 0xffFFECD2, end: 0xffFCB69F, name: "Sun Kissed"),
  (start: 0xffA1C4FD, end: 0xffC2E9FB, name: "Ice Drop"),
  (start: 0xff764BA2, end: 0xff667EEA, name: "Purple Rain"),
  (start: 0xffFDFCFB, end: 0xffE2D1C3, name: "Vanilla Latte"),
  (start: 0xffFFFFFF, end: 0xffFFFFFF, name: "Pure White"),
  (start: 0xff282a36, end: 0xff282a36, name: "Dark Mode"),
  (start: 0xff00F5A0, end: 0xff00D9F5, name: "Neon Cyber"),
  (start: 0xffFF3CAC, end: 0xff784BA0, name: "Synthwave"),
  (start: 0xff00C9FF, end: 0xff92FE9D, name: "Pixel Blue"),
  (start: 0xff232526, end: 0xff414345, name: "Midnight Sky")
];

getColor(int index) {
  return _colors[index];
}

getColorList() {
  return _colors.map((e) => (start: e.start, end: e.end, name: e.name)).toList();
}
