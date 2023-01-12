import 'package:superduper/utils.dart';
import 'package:unique_name_generator/unique_name_generator.dart';

//2a26
var a = [50, 50, 49, 49, 50, 50];

//2a27
var b = [118, 51, 46, 50, 46, 48];

//2a28
var c = [50, 50, 49, 49, 50, 50];

//2a29
var d = [67, 79, 77, 79, 68, 85, 76, 69];

var asd = strToLis('040134b3000000000000');
// Manufacturer Name
// COMODULE

// Hardware Revision
// v3.2.0

// Firmware Revision
// 221122

// Software Revision
// 221122

String toStr(List<int> data) {
  return data.map((e) => String.fromCharCode(e)).join();
}

void main(List<String> args) {
  print('Software Revision');
  print(a.map((e) => String.fromCharCode(e)).join());
  print('boop');
  print(b.map((e) => String.fromCharCode(e)).join());
  print('Firmware Revision');
  print(c.map((e) => String.fromCharCode(e)).join());
  print('Manufacturer Name');
  print(d.map((e) => String.fromCharCode(e)).join());
  print(asd);
  print(toStr(asd));
  //https://www.comodule.com/
  //nordic bluetooth

  var ung = UniqueNameGenerator(
    dictionaries: [adjectives, animals],
    style: NameStyle.capital,
    separator: ' ',
  );

  List<String> names = List.generate(10, (index) => ung.generate(seed: 1));
  print(names);
}
