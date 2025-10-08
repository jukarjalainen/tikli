import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/species.dart';
import '../bloc/observation_form_bloc.dart';
import '../../species_list/bloc/species_list_bloc.dart';

class ObservationFormScreen extends StatefulWidget {
  const ObservationFormScreen({super.key, required this.selectedSpecies});

  final List<Species> selectedSpecies;

  @override
  State<ObservationFormScreen> createState() => _ObservationFormScreenState();
}

class _ObservationFormScreenState extends State<ObservationFormScreen> {
  late final DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('d.M.yyyy HH:mm');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ObservationFormBloc, ObservationFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ObservationFormStatus.success) {
          context.read<SpeciesListBloc>().add(const SpeciesSelectionCleared());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Havainto tallennettu')));
          Navigator.of(context).pop();
        } else if (state.status == ObservationFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lisaa havainto'),
          backgroundColor: const Color(0xFF57BF32),
        ),
        body: BlocBuilder<ObservationFormBloc, ObservationFormState>(
          builder: (context, state) {
            return AbsorbPointer(
              absorbing: state.isSaving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valitut lajit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          state.selectedSpecies
                              .map(
                                (species) =>
                                    Chip(label: Text(species.commonName)),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pinnatyypit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ObservationType.values.map(
                      (type) => CheckboxListTile(
                        value: state.selectedTypes.contains(type),
                        onChanged:
                            (_) => context.read<ObservationFormBloc>().add(
                              ObservationTypeToggled(type),
                            ),
                        title: Text(type.label),
                        activeColor: const Color(0xFF57BF32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Havaintoaika'),
                      subtitle: Text(
                        state.timestamp != null
                            ? _dateFormat.format(state.timestamp!)
                            : 'Ei asetettu',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.timestamp != null)
                            IconButton(
                              icon: Icon(MdiIcons.trashCan),
                              onPressed: () =>
                                  context.read<ObservationFormBloc>().add(
                                const ObservationFormTimestampCleared(),
                              ),
                              tooltip: 'Poista päivämäärä',
                            ),
                        ],
                      ),
                      onTap: () async {
                        final bloc = context.read<ObservationFormBloc>();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: state.timestamp ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (!context.mounted || pickedDate == null) {
                          return;
                        }
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            state.timestamp ?? DateTime.now(),
                          ),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        final newDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime?.hour ??
                              (state.timestamp ?? DateTime.now()).hour,
                          pickedTime?.minute ??
                              (state.timestamp ?? DateTime.now()).minute,
                        );
                        bloc.add(ObservationFormTimestampChanged(newDateTime));
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place),
                      title: const Text('Paikkakunta'),
                      subtitle: Text(() {
                        if (state.position == null) {
                          return 'Ei asetettu';
                        }
                        final trimmed = state.address?.trim() ?? '';
                        return trimmed.isNotEmpty
                            ? trimmed
                            : 'Paikkatieto puuttuu';
                      }()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.position != null)
                            TextButton(
                              onPressed: () =>
                                  _editCoordinates(context, state.position!),
                              child: const Text('Editoi'),
                            ),
                          if (state.position != null)
                            IconButton(
                              icon: Icon(MdiIcons.trashCan),
                              onPressed: () =>
                                  context.read<ObservationFormBloc>().add(
                                const ObservationFormLocationCleared(),
                              ),
                              tooltip: 'Poista sijainti',
                            ),
                        ],
                      ),
                      onTap: state.position == null
                          ? () async {
                              // Set default position when clicked while empty
                              final bloc = context.read<ObservationFormBloc>();
                              final defaultPosition =
                                  const LatLng(60.1699, 24.9384);
                              await _editCoordinates(context, defaultPosition);
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: state.address ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Paikan kuvaus',
                        prefixIcon: Icon(Icons.map),
                      ),
                      onChanged:
                          (value) => context.read<ObservationFormBloc>().add(
                            ObservationFormAddressChanged(value),
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: state.notes ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Muistiinpanot',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      maxLines: 3,
                      onChanged:
                          (value) => context.read<ObservationFormBloc>().add(
                            ObservationFormNotesChanged(value),
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (state.position != null)
                      AspectRatio(
                        aspectRatio: 3 / 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: state.position!,
                              initialZoom: 12,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'fi.tikli.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: state.position!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: BlocBuilder<ObservationFormBloc, ObservationFormState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      state.isSaving
                          ? null
                          : () => context.read<ObservationFormBloc>().add(
                            const ObservationFormSubmitted(),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF57BF32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      state.isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Tallenna'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _editCoordinates(BuildContext context, LatLng current) async {
    final bloc = context.read<ObservationFormBloc>();
    final latController = TextEditingController(
      text: current.latitude.toStringAsFixed(6),
    );
    final lngController = TextEditingController(
      text: current.longitude.toStringAsFixed(6),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit coordinates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: 'Latitude (lat)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(labelText: 'Longitude (lng)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final lat = double.tryParse(latController.text.replaceAll(',', '.'));
    final lng = double.tryParse(lngController.text.replaceAll(',', '.'));
    if (lat == null || lng == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide valid coordinates.')),
      );
      return;
    }
    bloc.add(ObservationFormLocationChanged(LatLng(lat, lng)));
  }
}
