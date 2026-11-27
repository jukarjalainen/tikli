// Service class handling all local SQLite database operations.
// Responsible for initializing the database, creating tables, migrating the
// schema, and executing CRUD queries.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/custom_list.dart';

class DatabaseService {
  /// [databaseFactory] and [path] are for tests. By default the platform
  /// sqflite factory and `observations.db` in the databases folder are used.
  DatabaseService({DatabaseFactory? databaseFactory, String? path})
    : _databaseFactory = databaseFactory,
      _path = path;

  /// Current schema version.
  ///
  /// 1: observations only.
  /// 2: lists the user names (`custom_lists`), `observations.customListId` and
  ///    a key-value `settings` table. The fixed yard list (type `yard`) became
  ///    the custom list "Pihapinna".
  static const int schemaVersion = 2;

  /// Settings key holding the id of the custom list last saved to, which the
  /// observation form preselects.
  static const String activeCustomListIdKey = 'activeCustomListId';

  final DatabaseFactory? _databaseFactory;
  final String? _path;
  Future<Database>? _database;

  // Getter to retrieve the database instance, initializing it if necessary
  Future<Database> get database => _database ??= _initDB();

  Future<Database> _initDB() async {
    final factory = _databaseFactory ?? databaseFactory;
    final path =
        _path ?? join(await factory.getDatabasesPath(), 'observations.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) await (await database).close();
  }

  // Callback to create the database schema when the database is first created
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY,          -- Unique identifier for each observation
        speciesId TEXT NOT NULL,      -- ID of the species being observed
        type TEXT NOT NULL,           -- Type/category of the observation
        timestamp TEXT,               -- Time when the observation was made
        latitude REAL,                -- Latitude of the observation location
        longitude REAL,               -- Longitude of the observation location
        municipality TEXT,            -- municipality or description of the location
        customListId TEXT             -- custom list of a custom observation
      )
    ''');
    await _createCustomListTables(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE observations ADD COLUMN customListId TEXT');
      await _createCustomListTables(db);
      await _moveYardObservationsToCustomList(db);
    }
  }

  /// Creates the custom list and settings tables. A new database has no custom
  /// lists.
  Future<void> _createCustomListTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE custom_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Turns the observations of the old fixed yard list into the custom list
  /// "Pihapinna", if there are any, and preselects it in the observation form.
  Future<void> _moveYardObservationsToCustomList(DatabaseExecutor db) async {
    final moved = await db.update(
      'observations',
      {'type': 'custom', 'customListId': CustomList.migratedYardListId},
      where: 'type = ?',
      whereArgs: ['yard'],
    );
    if (moved == 0) return;
    await db.insert(
      'custom_lists',
      CustomList(
        id: CustomList.migratedYardListId,
        name: CustomList.migratedYardListName,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await db.insert('settings', {
      'key': activeCustomListIdKey,
      'value': CustomList.migratedYardListId,
    });
  }

  // Gets observations from the database and returns them as a list of maps
  Future<List<Map<String, dynamic>>> getAllObservations() async {
    final db = await database;
    return await db.query('observations');
  }

  // Saves an observation to the database by inserting a map representation of the observation
  Future<void> insertObservation(Map<String, dynamic> observationMap) async {
    final db = await database;
    await db.insert(
      'observations',
      observationMap,
      // If an observation with the same ID already exists, replace it with the new one
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes an observation from the database by its ID
  ///
  /// If the observation with the given ID does not exist in the database,
  /// this method will do nothing.
  Future<void> deleteObservation(String id) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [id]);
  }

  /// Custom lists, oldest first.
  Future<List<Map<String, dynamic>>> getCustomLists() async {
    final db = await database;
    return db.query('custom_lists', orderBy: 'createdAt ASC');
  }

  Future<void> insertCustomList(Map<String, dynamic> customListMap) async {
    final db = await database;
    await db.insert('custom_lists', customListMap);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
