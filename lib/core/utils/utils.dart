List<int> strToLis(String s) {
  s = s.replaceAll(' ', '');
  List<int> r = [];
  var l = s.length;
  for (var i = 0; i < l; i += 2) {
    r.add(int.parse(s[i] + s[i + 1], radix: 16));
  }
  return r;
}
