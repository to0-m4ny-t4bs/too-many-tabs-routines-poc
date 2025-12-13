import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_spent_dynamic_label.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class RoutineGoalLabel extends StatelessWidget {
  const RoutineGoalLabel({
    super.key,
    required this.spent,
    required this.goal,
    required this.running,
  });
  final Duration spent, goal;
  final bool running;

  @override
  build(BuildContext context) {
    final done = spent.inMinutes >= goal.inMinutes;

    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    final textStyle = TextStyle(
      color: running
          ? colorScheme.onPrimary
          : (darkMode ? colorScheme.onPrimaryContainer : colorScheme.primary),
      fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
      fontWeight: darkMode
          ? (running ? FontWeight.w500 : FontWeight.w400)
          : (running ? FontWeight.w600 : FontWeight.w300),
    );

    final textStyleDone = TextStyle(
      color: colorScheme.onSurface,
      fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.w200,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: done
            ? colorScheme.surfaceContainerHigh
            : (running
                  ? (darkMode ? colorScheme.primary : colorScheme.primary)
                  : (darkMode
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer)),
      ),
      child: done
          ? Text('Completed', style: textStyleDone)
          : (!running
                ? Text(formatUntilGoal(goal, spent), style: textStyle)
                : Row(
                    spacing: 4,
                    children: [
                      Text('Done within', style: textStyle),
                      Text(formatUntilGoal(goal, spent), style: textStyle),
                    ],
                  )),
    );
  }
}

class RoutineGoalDynamicLabel extends StatefulWidget {
  const RoutineGoalDynamicLabel({
    super.key,
    required this.spent,
    required this.goal,
    required this.lastStarted,
    required this.running,
    required this.restorationId,
  });

  final Duration spent, goal;
  final DateTime lastStarted;
  final bool running;
  final String? restorationId;

  @override
  createState() => _RoutineGoalDynamicLabelState();
}

class _RoutineGoalDynamicLabelState extends State<RoutineGoalDynamicLabel> {
  late Timer _timer;
  late AppLifecycleListener _listener;

  late Duration _spent;

  @override
  initState() {
    super.initState();
    _startTimer();
    _spent = routineDurationSpent(widget.lastStarted, widget.spent);
    _listener = AppLifecycleListener(
      onResume: () {
        setState(() {
          _spent = routineDurationSpent(widget.lastStarted, widget.spent);
        });
      },
    );
  }

  @override
  dispose() {
    _timer.cancel();
    _listener.dispose();
    super.dispose();
  }

  static const _refreshPeriod = Duration(seconds: 1);

  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (timer) {
      setState(() {
        _spent += _refreshPeriod;
      });
    });
  }

  @override
  build(BuildContext context) {
    return RoutineGoalLabel(
      spent: _spent,
      goal: widget.goal,
      running: widget.running,
    );
  }
}
