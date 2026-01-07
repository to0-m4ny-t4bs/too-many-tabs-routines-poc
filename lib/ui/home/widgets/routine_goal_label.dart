import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/ui/home/view_models/routine_state.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_spent_dynamic_label.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class RoutineGoalLabel extends StatelessWidget {
  const RoutineGoalLabel({
    super.key,
    required this.state,
    required this.spent,
    required this.goal,
    required this.lastStarted,
  });
  final Duration spent, goal;
  final RoutineState state;
  final DateTime? lastStarted;

  @override
  build(BuildContext context) {
    final DateTime eta = DateTime.now().add(goal - spent);

    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    final textStyle = TextStyle(
      color: state == RoutineState.isRunning
          ? colorScheme.onPrimary
          : (darkMode ? colorScheme.onPrimaryContainer : colorScheme.primary),
      fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
      fontWeight: darkMode
          ? ((state == RoutineState.isRunning)
                ? FontWeight.w500
                : FontWeight.w400)
          : ((state == RoutineState.isRunning)
                ? FontWeight.w600
                : FontWeight.w300),
    );

    switch (state) {
      case RoutineState.isRunning:
        return _buildIsRunningLabel(context, eta);
      case RoutineState.goalReached:
      case RoutineState.overRun:
        return Transform.translate(
          offset: Offset((state == RoutineState.overRun) ? 4 : 0, 0),
          child: Icon(
            Icons.emoji_events,
            color: colorScheme.primary.withValues(alpha: .6),
          ), // Icon emoji_events
        ); // Transform.translate
      case RoutineState.notStarted:
      case RoutineState.inProgress:
        return goal == Duration.zero
            ? Icon(
                Symbols.cruelty_free,
                color: colorScheme.primary.withValues(alpha: .6),
              ) // Icon cruelty_free
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: (darkMode
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer),
                ), // BoxDecoration
                child: Text(formatUntilGoal(goal, spent), style: textStyle),
              ); // Container
    }
  }

  Widget _buildIsRunningLabel(BuildContext context, DateTime eta) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 3,
            children: [
              Text(
                'ETA:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: darkMode ? FontWeight.w200 : FontWeight.w400,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 1,
                children: [
                  Text(
                    _format(eta),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: darkMode ? FontWeight.w300 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    eta.hour >= 12 ? "pm" : "am",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: darkMode ? FontWeight.w300 : FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            spacing: 4,
            children: [
              Text(
                'Left:',
                style: TextStyle(
                  fontWeight: darkMode ? FontWeight.w700 : FontWeight.w900,
                  fontSize: 13,
                  color: darkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                ),
              ),
              Text(
                formatUntilGoal(goal, spent),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: darkMode ? FontWeight.w700 : FontWeight.w900,
                  color: darkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RoutineGoalDynamicLabel extends StatefulWidget {
  const RoutineGoalDynamicLabel({
    super.key,
    required this.spent,
    required this.goal,
    required this.lastStarted,
    required this.state,
    required this.restorationId,
  });

  final Duration spent, goal;
  final DateTime lastStarted;
  final RoutineState state;
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
      state: widget.state,
      lastStarted: widget.lastStarted,
    );
  }
}

String _format(DateTime t) {
  var h = t.hour;
  if (h == 0 || h == 12) {
    h = 12;
  } else {
    h = h.remainder(12);
  }
  return '$h:${t.minute.toString().padLeft(2, "0")}';
}
