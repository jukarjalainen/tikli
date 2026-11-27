// UI screen containing the form to save a new bird observation.
// Includes inputs for observation type, location (map), date.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/map/map_interaction_options.dart';
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
  final MapController _mapController = MapController();
  Timer? _mapMoveDebounce;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('d.M.yyyy HH:mm');
  }

  @override
  void dispose() {
    _mapMoveDebounce?.cancel();
    super.dispose();
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
                                (species) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Chip(label: Text(species.commonName)),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: GestureDetector(
                                        onTap: () {
                                          context
                                              .read<ObservationFormBloc>()
                                              .add(
                                                ObservationFormSpeciesRemoved(
                                                  species,
                                                ),
                                              );
                                          context.read<SpeciesListBloc>().add(
                                            SpeciesSelectionToggled(species.id),
                                          );
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                      trailing:
                          state.timestamp != null
                              ? IconButton(
                                icon: Icon(
                                  MdiIcons.trashCan,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  context.read<ObservationFormBloc>().add(
                                    const ObservationFormTimestampCleared(),
                                  );
                                },
                                tooltip: 'Tyhjennä',
                              )
                              : null,
                      onTap: () async {
                        final bloc = context.read<ObservationFormBloc>();
                        final initialDate = state.timestamp ?? DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
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
                          initialTime: TimeOfDay.fromDateTime(initialDate),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        final newDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime?.hour ?? initialDate.hour,
                          pickedTime?.minute ?? initialDate.minute,
                        );
                        bloc.add(ObservationFormTimestampChanged(newDateTime));
                      },
                    ),
                    const SizedBox(height: 16),
                    if (state.position != null)
                      AspectRatio(
                        aspectRatio: 3 / 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: state.position!,
                                  initialZoom: 15,
                                  interactionOptions:
                                      northUpInteractionOptions,
                                  onPositionChanged: (camera, hasGesture) {
                                    if (!hasGesture) {
                                      return;
                                    }
                                    final nextCenter = camera.center;
                                    _mapMoveDebounce?.cancel();
                                    _mapMoveDebounce = Timer(
                                      const Duration(seconds: 1),
                                      () {
                                        if (!mounted) {
                                          return;
                                        }
                                        context.read<ObservationFormBloc>().add(
                                          ObservationFormLocationChanged(
                                            nextCenter,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'fi.tikli.app',
                                  ),
                                ],
                              ),
                              IgnorePointer(
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.position != null) ...[
                      const SizedBox(height: 8),

                      if (state.municipality != null &&
                          state.municipality!.trim().isNotEmpty)
                        Text(
                          'Kunta: ${state.municipality}',
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
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
