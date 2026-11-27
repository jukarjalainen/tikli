import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/models/species.dart';

void main() {
  test('Species.rare keeps the typed name and derives the id from it', () {
    final species = Species.rare('Jokin Harvinainen laji');

    expect(species.id, 'rare_jokin_harvinainen_laji');
    expect(species.commonName, 'Jokin Harvinainen laji');
  });

  group('Species.unlisted', () {
    test('recovers every suggested rare species name from its id', () {
      final asset = File('assets/data/all_finnish_birds.json');
      final suggestions =
          (jsonDecode(asset.readAsStringSync()) as List<dynamic>)
              .cast<String>();

      expect(suggestions, isNotEmpty);
      expect(
        suggestions.map(
          (name) => Species.unlisted(Species.rare(name).id).commonName,
        ),
        suggestions,
      );
    });

    test('recovers a typed rare species name in lower case', () {
      final rare = Species.rare('Jokin Harvinainen laji');

      expect(
        Species.unlisted(rare.id),
        Species(id: rare.id, commonName: 'jokin harvinainen laji'),
      );
    });
  });
}
