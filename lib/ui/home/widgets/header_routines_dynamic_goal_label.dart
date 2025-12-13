import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class HeaderRoutinesDynamicGoalLabel extends StatefulWidget {
  const HeaderRoutinesDynamicGoalLabel({super.key, required this.routines});

  final List<RoutineSummary> routines;

  @override
  createState() => _HeaderRoutinesDynamicGoalLabelState();
}

class _HeaderRoutinesDynamicGoalLabelState
    extends State<HeaderRoutinesDynamicGoalLabel>
    with RestorationMixin {
  late Timer _timer;
  final _minutesToGoal = RestorableInt(0);

  @override
  String? get restorationId => "header_minutes_to_goal";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_minutesToGoal, restorationId!);
  }

  @override
  void dispose() {
    _timer.cancel();
    _minutesToGoal.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _startTimer();
    super.initState();
  }

  static const _refreshPeriod = Duration(milliseconds: 50);
  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (_) {
      var goal = Duration();
      for (final routine in widget.routines) {
        final Duration left, absoluteLeft;

        if (routine.running) {
          final spent =
              routine.spent + DateTime.now().difference(routine.lastStarted!);
          absoluteLeft = routine.goal - spent;
        } else {
          absoluteLeft = routine.goal - routine.spent;
        }

        left = absoluteLeft.inMilliseconds < 0 ? Duration() : absoluteLeft;
        goal += left;
      }
      setState(() {
        _minutesToGoal.value = goal.inMinutes;
      });
    });
  }

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      '[ ${formatUntilGoal(Duration(minutes: _minutesToGoal.value), Duration(), forceSuffix: false)} ]',
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 10.5,
        color: darkMode
            ? colorScheme.onPrimaryContainer
            : colorScheme.onPrimaryFixedVariant,
      ),
    );
  }
}
