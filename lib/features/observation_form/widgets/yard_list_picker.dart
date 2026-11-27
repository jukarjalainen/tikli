import 'package:flutter/material.dart';

import '../../../core/models/yard_list.dart';

/// Dropdown for the yard list (pihapinna) to save to. Its last item,
/// "Lisää uusi", calls [onAddNew] instead of picking a list.
class YardListPicker extends StatelessWidget {
  const YardListPicker({
    super.key,
    required this.yardLists,
    required this.selectedId,
    required this.onSelected,
    required this.onAddNew,
  });

  /// Dropdown value of the "Lisää uusi" item. Not a yard list id.
  static const addNewValue = '__add_new_yard_list__';

  final List<YardList> yardLists;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final hasSelection = yardLists.any((list) => list.id == selectedId);
    return DropdownButton<String>(
      key: const Key('yardListPicker'),
      value: hasSelection ? selectedId : null,
      hint: const Text('Valitse'),
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: [
        for (final list in yardLists)
          DropdownMenuItem(
            value: list.id,
            child: Text(list.name, overflow: TextOverflow.ellipsis),
          ),
        const DropdownMenuItem(
          value: addNewValue,
          child: Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('Lisää uusi'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        if (value == addNewValue) {
          onAddNew();
        } else {
          onSelected(value);
        }
      },
    );
  }
}
