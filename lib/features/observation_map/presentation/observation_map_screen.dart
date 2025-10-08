import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/enums/observation_type.dart';
import '../../observation_list/bloc/observation_list_bloc.dart';

class ObservationMapScreen extends StatelessWidget {
  const ObservationMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Havaintokartta'),
        backgroundColor: const Color(0xFF57BF32),
      ),
      body: BlocBuilder<ObservationListBloc, ObservationListState>(
        builder: (context, state) {
          final observationsWithPosition =
              state.observations.where((obs) => obs.position != null).toList();
          if (observationsWithPosition.isEmpty) {
            return const Center(child: Text('Ei havaintoja kartalla.'));
          }
          final markers =
              observationsWithPosition
                  .map(
                    (observation) => Marker(
                      point: observation.position!,
                      width: 80,
                      height: 40,
                      child: Column(
                        children: [
                          Icon(
                            observation.type == ObservationType.yard
                                ? Icons.home
                                : observation.type == ObservationType.life
                                ? Icons.eco
                                : Icons.calendar_month,
                            color: Colors.red,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2),
                              ],
                            ),
                            child: Text(
                              observation.species.commonName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList();
          final center = markers.first.point;
          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 6),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'fi.tikli.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
