import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/features/observation_form/widgets/yard_list_name_dialog.dart';
import 'package:tikli/features/observation_form/widgets/yard_list_picker.dart';

import '../helpers/observation_fakes.dart';

void main() {
  String? selected;
  String? addedName;

  /// Shows the picker. "Lisää uusi" opens [YardListNameDialog], like the
  /// observation form does.
  Future<void> pumpPicker(WidgetTester tester) async {
    selected = null;
    addedName = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => YardListPicker(
                  yardLists: [koti, mokki],
                  selectedId: koti.id,
                  onSelected: (id) => selected = id,
                  onAddNew: () async {
                    addedName = await YardListNameDialog.show(
                      context,
                      existingLists: [koti, mokki],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('yardListPicker')));
    await tester.pumpAndSettle();
  }

  testWidgets('picks a yard list', (tester) async {
    await pumpPicker(tester);
    expect(find.text('Koti'), findsOneWidget);

    await openPicker(tester);
    await tester.tap(find.text('Mökki').last);
    await tester.pumpAndSettle();

    expect(selected, 'mokki');
  });

  testWidgets('names a new yard list from "Lisää uusi"', (tester) async {
    await pumpPicker(tester);

    await openPicker(tester);
    await tester.tap(find.text('Lisää uusi').last);
    await tester.pumpAndSettle();
    expect(find.text('Uusi pihapinna'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Lisää'));
    await tester.pump();
    expect(find.text('Anna pihapinnalle nimi.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('yardListNameField')), 'mökki');
    await tester.tap(find.text('Lisää'));
    await tester.pump();
    expect(find.text('Pihapinna "mökki" on jo olemassa.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('yardListNameField')),
      ' Saari ',
    );
    await tester.tap(find.text('Lisää'));
    await tester.pumpAndSettle();

    expect(addedName, 'Saari');
    expect(find.text('Uusi pihapinna'), findsNothing);
  });
}
