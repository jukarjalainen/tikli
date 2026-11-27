import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/features/observation_form/widgets/custom_list_name_dialog.dart';
import 'package:tikli/features/observation_form/widgets/custom_list_picker.dart';

import '../helpers/observation_fakes.dart';

void main() {
  String? selected;
  String? addedName;

  /// Shows the picker. "Lisää uusi" opens [CustomListNameDialog], like the
  /// observation form does.
  Future<void> pumpPicker(WidgetTester tester) async {
    selected = null;
    addedName = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => CustomListPicker(
                  customLists: [pihapinna, mokki],
                  selectedId: pihapinna.id,
                  onSelected: (id) => selected = id,
                  onAddNew: () async {
                    addedName = await CustomListNameDialog.show(
                      context,
                      existingLists: [pihapinna, mokki],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('customListPicker')));
    await tester.pumpAndSettle();
  }

  testWidgets('picks a custom list', (tester) async {
    await pumpPicker(tester);
    expect(find.text('Pihapinna'), findsOneWidget);

    await openPicker(tester);
    await tester.tap(find.text('Mökki').last);
    await tester.pumpAndSettle();

    expect(selected, 'mokki');
  });

  testWidgets('names a new custom list from "Lisää uusi"', (tester) async {
    await pumpPicker(tester);

    await openPicker(tester);
    await tester.tap(find.text('Lisää uusi').last);
    await tester.pumpAndSettle();
    expect(find.text('Uusi lista'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Lisää'));
    await tester.pump();
    expect(find.text('Anna listalle nimi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customListNameField')),
      'mökki',
    );
    await tester.tap(find.text('Lisää'));
    await tester.pump();
    expect(find.text('Lista "mökki" on jo olemassa.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customListNameField')),
      ' Saari ',
    );
    await tester.tap(find.text('Lisää'));
    await tester.pumpAndSettle();

    expect(addedName, 'Saari');
    expect(find.text('Uusi lista'), findsNothing);
  });
}
