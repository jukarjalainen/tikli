import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tikli/core/models/yard_list.dart';
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

  /// Writes a database as version 1 of the app left it.
  Future<void> createVersion1Database() async {
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
          for (final (id, type) in [('a', 'yard'), ('b', 'yearly')]) {
            await db.insert('observations', {
              'id': id,
              'speciesId': 'tikli',
              'type': type,
            });
          }
        },
      ),
    );
    await db.close();
  }

  test('moves old yard observations to the default yard list', () async {
    await createVersion1Database();
    final service = DatabaseService(
      databaseFactory: databaseFactoryFfi,
      path: path,
    );
    addTearDown(service.close);

    final rows = await service.getAllObservations();
    expect({for (final row in rows) row['id']: row['yardListId']}, {
      'a': YardList.defaultId,
      'b': null,
    });
    final lists = await service.getYardLists();
    expect(lists.single['id'], YardList.defaultId);
    expect(lists.single['name'], YardList.defaultName);
    expect(
      await service.getSetting(DatabaseService.activeYardListIdKey),
      YardList.defaultId,
    );
  });

  test('starts a new database with the default yard list active', () async {
    final service = DatabaseService(
      databaseFactory: databaseFactoryFfi,
      path: path,
    );
    addTearDown(service.close);

    expect((await service.getYardLists()).single['name'], 'Koti');
    expect(
      await service.getSetting(DatabaseService.activeYardListIdKey),
      YardList.defaultId,
    );
  });

  test('stores new yard lists and the last used one', () async {
    final service = DatabaseService(
      databaseFactory: databaseFactoryFfi,
      path: path,
    );
    addTearDown(service.close);

    await service.insertYardList(
      YardList(id: 'mokki', name: 'Mökki', createdAt: DateTime(2100)).toMap(),
    );
    await service.setSetting(DatabaseService.activeYardListIdKey, 'mokki');

    expect((await service.getYardLists()).map((row) => row['name']), [
      'Koti',
      'Mökki',
    ]);
    expect(
      await service.getSetting(DatabaseService.activeYardListIdKey),
      'mokki',
    );
  });
}
