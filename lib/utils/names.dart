import 'package:unique_name_generator/unique_name_generator.dart';

/// Generates a readable name for a bike from a seed.
///
/// This uses the unique name generator package to create a consistent,
/// readable name based on the bike's ID or another seed value.
String getName({required String seed}) {
  final nameGenerator = UniqueNameGenerator(
    dictionaries: [adjectives, animals],
    style: NameStyle.capital,
    separator: ' ',
  );

  return nameGenerator.generate(seed: seed.codeUnits.join().hashCode);
}
