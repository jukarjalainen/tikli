// Repository for the lists the user names (custom lists), e.g. "Pihapinna".
// Keeps an in-memory snapshot in sync with the SQLite DatabaseService.

import 'dart:async';

import '../models/custom_list.dart';
import '../services/database_service.dart';
import '../utils/clock.dart';

/// Thrown when a custom list name is empty or already taken. [message] is
/// shown to the user.
class CustomListNameException implements Exception {
  const CustomListNameException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CustomListRepository {
  CustomListRepository({
    DatabaseService? databaseService,
    Clock clock = DateTime.now,
  }) : _dbService = databaseService ?? DatabaseService(),
       _clock = clock {
    _ready = _load();
  }

  final DatabaseService _dbService;
  final Clock _clock;
  final StreamController<CustomListsSnapshot> _controller =
      StreamController<CustomListsSnapshot>.broadcast();
  late final Future<void> _ready;

  List<CustomList> _lists = const [];
  String? _activeId;
  bool _loaded = false;

  /// The latest snapshot, or null while the lists are still loading.
  CustomListsSnapshot? get current => _loaded ? _snapshot : null;

  CustomListsSnapshot get _snapshot => CustomListsSnapshot(
    lists: List.unmodifiable(_lists),
    activeId: _activeId,
  );

  /// The current snapshot (once loaded), then every change.
  Stream<CustomListsSnapshot> watch() async* {
    if (_loaded) yield _snapshot;
    yield* _controller.stream;
  }

  /// Creates a custom list named [name].
  ///
  /// Throws [CustomListNameException] if the name is empty or taken.
  Future<CustomList> create(String name) async {
    await _ready;
    final error = customListNameError(name, _lists);
    if (error != null) throw CustomListNameException(error);
    final list = CustomList(
      id: 'list-${_clock().microsecondsSinceEpoch}',
      name: name.trim(),
      createdAt: _clock(),
    );
    await _dbService.insertCustomList(list.toMap());
    _lists = [..._lists, list];
    _notify();
    return list;
  }

  /// Remembers [id] as the custom list last saved to, which the observation
  /// form preselects next time.
  Future<void> setActive(String id) async {
    await _ready;
    if (!_lists.any((list) => list.id == id)) {
      throw ArgumentError.value(id, 'id', 'No such custom list');
    }
    if (id == _activeId) return;
    await _dbService.setSetting(DatabaseService.activeCustomListIdKey, id);
    _activeId = id;
    _notify();
  }

  void dispose() {
    _controller.close();
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(_snapshot);
  }

  Future<void> _load() async {
    final rows = await _dbService.getCustomLists();
    _lists = [for (final row in rows) CustomList.fromMap(row)];
    final storedActive = await _dbService.getSetting(
      DatabaseService.activeCustomListIdKey,
    );
    if (_lists.any((list) => list.id == storedActive)) {
      _activeId = storedActive;
    }
    _loaded = true;
    _notify();
  }
}
