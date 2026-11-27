import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tikli/core/models/custom_list.dart';
import 'package:tikli/core/services/database_service.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tikli_db_test');
    path = p.join(tempDir.path, 'observations.db');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// Writes a database as version 1 of the app left it, with one observation
  /// of each of [types], each with its type as id.
  Future<void> createVersion1Database(List<String> types) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE observations (
              id TEXT PRIMARY KEY, speciesId TEXT NOT NULL, type TEXT NOT NULL,
              timestamp TEXT, latitude REAL, longitude REAL, municipality TEXT
            )
          ''');
          for (final type in types) {
            await db.insert('observations', {
              'id': type,
              'speciesId': 'tikli',
              'type': type,
            });
          }
        },
      ),
    );
    await db.close();
  }

  DatabaseService openService() {
    final service = DatabaseService(
      databaseFactory: databaseFactoryFfi,
      path: path,
    );
    addTearDown(service.close);
    return service;
  }

  test('turns the old yard list into the custom list "Pihapinna"', () async {
    await createVersion1Database(['yard', 'yearly', 'life']);
    final service = openService();

    final rows = await service.getAllObservations();
    expect(
      {for (final row in rows) row['id']: (row['type'], row['customListId'])},
      {
        'yard': ('custom', CustomList.migratedYardListId),
        'yearly': ('yearly', null),
        'life': ('life', null),
      },
    );
    final lists = await service.getCustomLists();
    expect(lists.single['id'], CustomList.migratedYardListId);
    expect(lists.single['name'], 'Pihapinna');
    expect(
      await service.getSetting(DatabaseService.activeCustomListIdKey),
      CustomList.migratedYardListId,
    );
  });

  test('adds no custom list when there were no yard observations', () async {
    await createVersion1Database(['yearly', 'life']);
    final service = openService();

    expect(await service.getCustomLists(), isEmpty);
    expect(
      await service.getSetting(DatabaseService.activeCustomListIdKey),
      isNull,
    );
  });

  test('starts a new database without custom lists', () async {
    final service = openService();

    expect(await service.getCustomLists(), isEmpty);
    expect(
      await service.getSetting(DatabaseService.activeCustomListIdKey),
      isNull,
    );
  });

  test(
    'stores new custom lists, oldest first, and the last used one',
    () async {
      final service = openService();

      for (final (id, name, year) in [
        ('b', 'Mökki', 2101),
        ('a', 'Saari', 2100),
      ]) {
        await service.insertCustomList(
          CustomList(id: id, name: name, createdAt: DateTime(year)).toMap(),
        );
      }
      await service.setSetting(DatabaseService.activeCustomListIdKey, 'b');

      expect((await service.getCustomLists()).map((row) => row['name']), [
        'Saari',
        'Mökki',
      ]);
      expect(
        await service.getSetting(DatabaseService.activeCustomListIdKey),
        'b',
      );
    },
  );
}
