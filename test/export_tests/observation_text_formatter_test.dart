import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/features/export/formatters/observation_text_formatter.dart';

import '../helpers/observation_fakes.dart';

void main() {
  test('prints a separately numbered yearly list for each year', () {
    final text = formatObservationsAsText([
      testObservation(
        '1',
        DateTime(2027, 1, 2),
        species: tikli,
        municipality: 'Oulu',
      ),
      testObservation('2', DateTime(2026, 2, 1), species: tikli),
      testObservation('3', DateTime(2026, 1, 1)),
      testObservation('4', DateTime(2026, 1, 1), type: ObservationType.life),
    ]);

    expect(
      text,
      'Vuodenpinnat 2026\n'
      '1. talitiainen 1.1.2026\n'
      '2. tikli 1.2.2026\n'
      '\n'
      'Vuodenpinnat 2027\n'
      '1. tikli 2.1.2027 Oulu\n'
      '\n'
      'Pihapinnat\n'
      '\n'
      'Elämänpinnat\n'
      '1. talitiainen 1.1.2026\n',
    );
  });

  test('prints a separate yard list for each named yard list', () {
    final text = formatObservationsAsText(
      [
        testObservation(
          '1',
          DateTime(2026, 6, 1),
          type: ObservationType.yard,
          yardListId: 'mokki',
        ),
        testObservation(
          '2',
          DateTime(2026, 5, 1),
          species: tikli,
          type: ObservationType.yard,
        ),
        testObservation(
          '3',
          DateTime(2026, 5, 2),
          type: ObservationType.yard,
        ),
        testObservation(
          '4',
          DateTime(2026, 7, 1),
          type: ObservationType.yard,
          yardListId: 'deleted',
        ),
      ],
      yardLists: [koti, mokki],
    );

    expect(
      text,
      'Vuodenpinnat\n'
      '\n'
      'Pihapinnat: Koti\n'
      '1. tikli 1.5.2026\n'
      '2. talitiainen 2.5.2026\n'
      '\n'
      'Pihapinnat: Mökki\n'
      '1. talitiainen 1.6.2026\n'
      '\n'
      'Pihapinnat\n'
      '1. talitiainen 1.7.2026\n'
      '\n'
      'Elämänpinnat\n',
    );
  });

  test('keeps every heading when there are no observations', () {
    expect(
      formatObservationsAsText(const []),
      'Vuodenpinnat\n\nPihapinnat\n\nElämänpinnat\n',
    );
  });
}
