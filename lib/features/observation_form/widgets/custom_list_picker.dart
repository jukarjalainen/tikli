import 'package:flutter/material.dart';

import '../../../core/models/custom_list.dart';

/// Dropdown for the custom list to save to. Its last item,
/// "Lisää uusi", calls [onAddNew] instead of picking a list.
class CustomListPicker extends StatelessWidget {
  const CustomListPicker({
    super.key,
    required this.customLists,
    required this.selectedId,
    required this.onSelected,
    required this.onAddNew,
  });

  /// Dropdown value of the "Lisää uusi" item. Not a custom list id.
  static const addNewValue = '__add_new_custom_list__';

  final List<CustomList> customLists;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final hasSelection = customLists.any((list) => list.id == selectedId);
    return DropdownButton<String>(
      key: const Key('customListPicker'),
      value: hasSelection ? selectedId : null,
      hint: const Text('Valitse'),
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: [
        for (final list in customLists)
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
