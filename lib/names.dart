import 'package:unique_name_generator/unique_name_generator.dart';

var ung = UniqueNameGenerator(
  dictionaries: [adjectives, animals],
  style: NameStyle.capital,
  separator: ' ',
);

String getName({String seed = ''}) {
  if (seed.isEmpty) {
    return ung.generate();
  }
  return ung.generate(seed: seed.codeUnits.join().hashCode);
}
