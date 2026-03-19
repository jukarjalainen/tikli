// Service class handling all local SQLite database operations.
// Responsible for initializing the database, creating tables, and executing CRUD queries.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton instance of the database
  static Database? _database;

  // Getter to retrieve the database instance, initializing it if necessary
  Future<Database> get database async {
    // If the database is already initialized, return it
    if (_database != null) return _database!;
    // Otherwise, initialize the database
    _database = await _initDB('observations.db');
    return _database!;
  }

  // Private method to initialize the database
  Future<Database> _initDB(String filePath) async {
    // Get the default database path for the device
    final dbPath = await getDatabasesPath();
    // Combine the database path with the file name
    final path = join(dbPath, filePath);

    // Open the database, setting its version and creation callback
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Callback to create the database schema when the database is first created
  Future<void> _createDB(Database db, int version) async {
    // Create a table named 'observations' with the specified columns
    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY,          -- Unique identifier for each observation
        speciesId TEXT NOT NULL,      -- ID of the species being observed
        type TEXT NOT NULL,           -- Type/category of the observation
        timestamp TEXT,               -- Time when the observation was made
        latitude REAL,                -- Latitude of the observation location
        longitude REAL,               -- Longitude of the observation location
        municipality TEXT,                 -- municipality or description of the location
      )
    ''');
  }

  // Gets observations from the database and returns them as a list of maps
  Future<List<Map<String, dynamic>>> getAllObservations() async {
    final db = await database;
    // 'observations' on Vaiheessa 3 luomasi taulun nimi
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
  /// This method is asynchronous and will return a Future that completes
  /// when the deletion is complete. If the observation with the given
  /// ID does not exist in the database, this method will do nothing.
  ///
  /// [id] The ID of the observation to delete. This should be a unique
  /// identifier for the observation in the database.
  Future<void> deleteObservation(String id) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [id]);
  }
}
