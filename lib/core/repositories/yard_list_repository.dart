// Repository for the named yard lists (pihapinnat), e.g. "Koti" and "Mökki".
// Keeps an in-memory snapshot in sync with the SQLite DatabaseService.

import 'dart:async';

import '../models/yard_list.dart';
import '../services/database_service.dart';
import '../utils/clock.dart';

/// Thrown when a yard list name is empty or already taken. [message] is
/// shown to the user.
class YardListNameException implements Exception {
  const YardListNameException(this.message);

  final String message;

  @override
  String toString() => message;
}

class YardListRepository {
  YardListRepository({
    DatabaseService? databaseService,
    Clock clock = DateTime.now,
  }) : _dbService = databaseService ?? DatabaseService(),
       _clock = clock {
    _ready = _load();
  }

  final DatabaseService _dbService;
  final Clock _clock;
  final StreamController<YardListsSnapshot> _controller =
      StreamController<YardListsSnapshot>.broadcast();
  late final Future<void> _ready;

  List<YardList> _lists = const [];
  String _activeId = YardList.defaultId;
  bool _loaded = false;

  /// The latest snapshot, or null while the lists are still loading.
  YardListsSnapshot? get current => _loaded ? _snapshot : null;

  YardListsSnapshot get _snapshot =>
      YardListsSnapshot(lists: List.unmodifiable(_lists), activeId: _activeId);

  /// The current snapshot (once loaded), then every change.
  Stream<YardListsSnapshot> watch() async* {
    if (_loaded) yield _snapshot;
    yield* _controller.stream;
  }

  /// Creates a yard list named [name].
  ///
  /// Throws [YardListNameException] if the name is empty or taken.
  Future<YardList> create(String name) async {
    await _ready;
    final error = yardListNameError(name, _lists);
    if (error != null) throw YardListNameException(error);
    final list = YardList(
      id: 'yard-${_clock().microsecondsSinceEpoch}',
      name: name.trim(),
      createdAt: _clock(),
    );
    await _dbService.insertYardList(list.toMap());
    _lists = [..._lists, list];
    _notify();
    return list;
  }

  /// Remembers [id] as the yard list last saved to, which the observation
  /// form preselects next time.
  Future<void> setActive(String id) async {
    await _ready;
    if (!_lists.any((list) => list.id == id)) {
      throw ArgumentError.value(id, 'id', 'No such yard list');
    }
    if (id == _activeId) return;
    await _dbService.setSetting(DatabaseService.activeYardListIdKey, id);
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
    final rows = await _dbService.getYardLists();
    _lists = [for (final row in rows) YardList.fromMap(row)];
    final storedActive = await _dbService.getSetting(
      DatabaseService.activeYardListIdKey,
    );
    if (storedActive != null && _lists.any((list) => list.id == storedActive)) {
      _activeId = storedActive;
    } else if (_lists.isNotEmpty) {
      _activeId = _lists.first.id;
    }
    _loaded = true;
    _notify();
  }
}
