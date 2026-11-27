// Data model for a list the user names, e.g. "Pihapinna", "Mökki" or
// "Työmatka". The yearly and life lists are built in; every other list is a
// custom list.

import 'package:equatable/equatable.dart';

class CustomList extends Equatable {
  const CustomList({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Id of the list that yard observations of the old fixed yard list move to
  /// when the database is upgraded.
  static const String migratedYardListId = 'pihapinna';

  /// Name of the list with [migratedYardListId].
  static const String migratedYardListName = 'Pihapinna';

  final String id;
  final String name;
  final DateTime createdAt;

  CustomList copyWith({String? name}) {
    return CustomList(id: id, name: name ?? this.name, createdAt: createdAt);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  factory CustomList.fromMap(Map<String, dynamic> map) {
    return CustomList(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}

/// All custom lists, oldest first, and the id of the one last saved to, which
/// the observation form preselects. [activeId] is null until the user has
/// saved to a custom list, or while there are none.
class CustomListsSnapshot extends Equatable {
  const CustomListsSnapshot({required this.lists, this.activeId});

  final List<CustomList> lists;
  final String? activeId;

  CustomList? byId(String? id) {
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  CustomList? get active => byId(activeId);

  @override
  List<Object?> get props => [lists, activeId];
}

/// Why [name] can't be used for a custom list, in Finnish, or null if it can.
///
/// The name must not be empty and must differ, ignoring case, from the names
/// in [lists] other than the list [exceptId], and from the built-in lists.
String? customListNameError(
  String name,
  Iterable<CustomList> lists, {
  String? exceptId,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Anna listalle nimi.';
  final lower = trimmed.toLowerCase();
  final taken =
      _builtInListNames.contains(lower) ||
      lists.any(
        (list) => list.id != exceptId && list.name.toLowerCase() == lower,
      );
  return taken ? 'Lista "$trimmed" on jo olemassa.' : null;
}

const _builtInListNames = {'vuodenpinnat', 'elämänpinnat'};
