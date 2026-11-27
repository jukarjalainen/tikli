// A dialog widget allowing users to manually input and add a rare bird species 
// that is not found in the standard local JSON list.

import 'package:flutter/material.dart';
import '../../../core/models/species.dart';
import '../../../core/services/all_birds_service.dart';

class RareSpeciesDialog extends StatefulWidget {
  const RareSpeciesDialog({super.key, required this.existingSpecies});
  final List<Species> existingSpecies;

  @override
  State<RareSpeciesDialog> createState() => _RareSpeciesDialogState();
}

class _RareSpeciesDialogState extends State<RareSpeciesDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _allBirds = [];
  List<String> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBirds();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBirds() async {
    try {
      final birds = await AllBirdsService.loadAllBirds();
      setState(() {
        _allBirds = birds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Virhe lajien lataamisessa: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _suggestions = AllBirdsService.filterBirds(_allBirds, _controller.text);
    });
  }

  void _onAddSpecies() {
    final speciesName = _controller.text.trim();
    if (speciesName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kirjoita lajin nimi')));
      return;
    }

    // Check if the species name already exists in the existingSpecies list
    final existingIndex = widget.existingSpecies.indexWhere(
      (s) => s.commonName.toLowerCase() == speciesName.toLowerCase()
    );

    if (existingIndex != -1) {
      // If the species name already exists in the existingSpecies list, return
      // the existing Species object.
      Navigator.of(context).pop(widget.existingSpecies[existingIndex]);
      return;
    }

    // Create a temporary Species object for the rare bird
    Navigator.of(context).pop(Species.rare(speciesName));
  }

  void _onSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lisää harvinainen laji',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Lajin nimi',
                    hintText: 'Kirjoita lajin nimi...',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onAddSpecies(),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(suggestion),
                          onTap: () => _onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Peruuta'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onAddSpecies,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF57BF32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Lisää'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
