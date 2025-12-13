import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class RoutineSpentDynamicLabel extends StatefulWidget {
  const RoutineSpentDynamicLabel({
    super.key,
    required this.spent,
    required this.lastStarted,
    required this.restorationId,
  });

  final Duration spent;
  final DateTime lastStarted;
  final String? restorationId;

  @override
  createState() => _RoutineSpentDynamicLabelState();
}

class _RoutineSpentDynamicLabelState extends State<RoutineSpentDynamicLabel> {
  late Timer _timer;
  late Duration _spent;
  late AppLifecycleListener _listener;

  @override
  initState() {
    super.initState();
    _spent = routineDurationSpent(widget.lastStarted, widget.spent);
    _listener = AppLifecycleListener(
      onResume: () {
        setState(() {
          _spent = routineDurationSpent(widget.lastStarted, widget.spent);
        });
      },
    );
    _startTimer();
  }

  @override
  dispose() {
    _listener.dispose();
    _timer.cancel();
    super.dispose();
  }

  static const _refreshPeriod = Duration(milliseconds: 20);

  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (timer) {
      setState(() {
        _spent += _refreshPeriod;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoutineSpentLabel(spent: _spent);
  }
}

class RoutineSpentLabel extends StatelessWidget {
  const RoutineSpentLabel({super.key, required this.spent});
  final Duration spent;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatSpentDuration(spent),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11.4,
        fontFamily: 'Mono',
      ),
    );
  }
}

Duration routineDurationSpent(DateTime lastStarted, Duration spent) {
  return DateTime.now().difference(lastStarted) + spent;
}
