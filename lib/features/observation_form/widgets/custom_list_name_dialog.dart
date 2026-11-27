import 'package:flutter/material.dart';

import '../../../core/models/custom_list.dart';

/// Asks for the name of a new custom list. The name must not be empty or taken
/// by one of [existingLists].
///
/// Pops the trimmed name, or null when cancelled.
class CustomListNameDialog extends StatefulWidget {
  const CustomListNameDialog({super.key, required this.existingLists});

  final List<CustomList> existingLists;

  static Future<String?> show(
    BuildContext context, {
    required List<CustomList> existingLists,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => CustomListNameDialog(existingLists: existingLists),
    );
  }

  @override
  State<CustomListNameDialog> createState() => _CustomListNameDialogState();
}

class _CustomListNameDialogState extends State<CustomListNameDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = customListNameError(_controller.text, widget.existingLists);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uusi lista'),
      content: TextField(
        key: const Key('customListNameField'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Nimi',
          hintText: 'esim. Mökki',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Peruuta'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lisää')),
      ],
    );
  }
}
