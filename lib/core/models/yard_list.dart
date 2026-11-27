// Data model for a named yard list (pihapinna), e.g. "Koti" or "Mökki".

import 'package:equatable/equatable.dart';

class YardList extends Equatable {
  const YardList({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Id of the list that existing yard observations are moved to when the
  /// database is upgraded, and the list a fresh install starts with.
  static const String defaultId = 'default';

  /// Name of the list with [defaultId].
  static const String defaultName = 'Koti';

  final String id;
  final String name;
  final DateTime createdAt;

  YardList copyWith({String? name}) {
    return YardList(id: id, name: name ?? this.name, createdAt: createdAt);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  factory YardList.fromMap(Map<String, dynamic> map) {
    return YardList(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}

/// All yard lists, oldest first, and the id of the one last saved to, which
/// the observation form preselects.
class YardListsSnapshot extends Equatable {
  const YardListsSnapshot({required this.lists, required this.activeId});

  final List<YardList> lists;
  final String activeId;

  YardList? byId(String? id) {
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  YardList? get active => byId(activeId);

  @override
  List<Object?> get props => [lists, activeId];
}

/// Why [name] can't be used for a yard list, in Finnish, or null if it can.
///
/// The name must not be empty and must differ, ignoring case, from the names
/// in [lists] other than the list [exceptId] being renamed.
String? yardListNameError(
  String name,
  Iterable<YardList> lists, {
  String? exceptId,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Anna pihapinnalle nimi.';
  final lower = trimmed.toLowerCase();
  final taken = lists.any(
    (list) => list.id != exceptId && list.name.toLowerCase() == lower,
  );
  return taken ? 'Pihapinna "$trimmed" on jo olemassa.' : null;
}
