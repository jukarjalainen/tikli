import 'package:flutter/material.dart';

import '../../../core/models/yard_list.dart';

/// Asks for the name of a new yard list. The name must not be empty or taken
/// by one of [existingLists].
///
/// Pops the trimmed name, or null when cancelled.
class YardListNameDialog extends StatefulWidget {
  const YardListNameDialog({super.key, required this.existingLists});

  final List<YardList> existingLists;

  static Future<String?> show(
    BuildContext context, {
    required List<YardList> existingLists,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => YardListNameDialog(existingLists: existingLists),
    );
  }

  @override
  State<YardListNameDialog> createState() => _YardListNameDialogState();
}

class _YardListNameDialogState extends State<YardListNameDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = yardListNameError(_controller.text, widget.existingLists);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uusi pihapinna'),
      content: TextField(
        key: const Key('yardListNameField'),
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
