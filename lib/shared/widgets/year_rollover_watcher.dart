import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/observation_list/bloc/observation_list_bloc.dart';

/// Asks the [ObservationListBloc] to check for a new year when the app returns
/// to the foreground, and once a minute while it stays open.
class YearRolloverWatcher extends StatefulWidget {
  const YearRolloverWatcher({super.key, required this.child});

  static const Duration checkInterval = Duration(minutes: 1);

  final Widget child;

  @override
  State<YearRolloverWatcher> createState() => _YearRolloverWatcherState();
}

class _YearRolloverWatcherState extends State<YearRolloverWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      YearRolloverWatcher.checkInterval,
      (_) => _requestYearCheck(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestYearCheck();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _requestYearCheck() {
    context.read<ObservationListBloc>().add(
      const ObservationListYearCheckRequested(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
