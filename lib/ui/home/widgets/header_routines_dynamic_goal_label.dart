import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class HeaderRoutinesDynamicGoalLabel extends StatefulWidget {
  const HeaderRoutinesDynamicGoalLabel({super.key, required this.routines});

  final List<RoutineSummary> routines;

  @override
  createState() => _HeaderRoutinesDynamicGoalLabelState();
}

class _HeaderRoutinesDynamicGoalLabelState
    extends State<HeaderRoutinesDynamicGoalLabel> {
  late Timer _timer;
  bool _ticking = false;
  late Duration _goal;

  @override
  void dispose() {
    if (_ticking) _timer.cancel();
    super.dispose();
  }

  void _refreshGoal() {
    var inPause = true;
    var goal = Duration();
    for (final routine in widget.routines) {
      if (routine.running) {
        inPause = false;
        var spent = routine.spent;
        if (routine.lastStarted != null) {
          spent += DateTime.now().difference(routine.lastStarted!);
        }
        final left = routine.goal - spent;
        if (left > Duration()) {
          goal += left;
        }
        continue;
      }
      if (routine.lastStarted == null) {
        goal += routine.goal;
        continue;
      }
      final left = routine.goal - routine.spent;
      if (left > Duration()) {
        goal += left;
      }
    }
    if (inPause && _ticking) {
      _ticking = false;
      _timer.cancel();
    }
    if (!inPause && !_ticking) {
      _ticking = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshGoal();
      });
    }
    setState(() {
      _goal = goal;
    });
  }

  @override
  build(BuildContext context) {
    _refreshGoal();
    final left = formatUntilGoal(_goal, Duration(), forceSuffix: false);
    return Text(
      left == "done" ? "done" : "$left left",
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 10.5,
        color: labelColor(context, Label.homeScreenGoalTotal),
      ),
    );
  }
}
