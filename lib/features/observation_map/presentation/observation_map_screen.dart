// UI screen showing the observations of the list open on the observations page
// on a map. Observations too close together to tell apart at the current zoom
// share one marker.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/map/map_interaction_options.dart';
import '../../observation_list/bloc/observation_list_bloc.dart';
import '../widgets/observation_cluster_layer.dart';

class ObservationMapScreen extends StatelessWidget {
  const ObservationMapScreen({super.key});

  /// The highest zoom OpenStreetMap has tiles for.
  static const double maxZoom = 19;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObservationListBloc, ObservationListState>(
      builder: (context, state) {
        final listName = shownListName(state);
        final observations = [
          for (final observation in state.observationsFor(state.filterType))
            if (observation.position != null) observation,
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text('Havaintokartta · $listName'),
            backgroundColor: const Color(0xFF57BF32),
          ),
          body:
              observations.isEmpty
                  ? Center(
                    child: Text(
                      'Listalla "$listName" ei ole havaintoja kartalla.',
                      textAlign: TextAlign.center,
                    ),
                  )
                  : FlutterMap(
                    options: MapOptions(
                      initialCenter: observations.first.position!,
                      initialZoom: 6,
                      initialRotation: 0,
                      maxZoom: maxZoom,
                      interactionOptions: northUpInteractionOptions,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'fi.tikli.app',
                      ),
                      ObservationClusterLayer(observations: observations),
                    ],
                  ),
        );
      },
    );
  }

  /// The name of the list open on the observations page, with the year for
  /// the yearly list, e.g. `Vuodenpinnat 2026` or `Mökki`.
  static String shownListName(ObservationListState state) {
    final label = state.choiceFor(state.filterType).label;
    return state.filterType == ObservationType.yearly
        ? '$label ${state.shownYear}'
        : label;
  }
}
