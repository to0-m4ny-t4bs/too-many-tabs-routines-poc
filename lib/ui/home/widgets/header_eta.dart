import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/widgets/header_routines_dynamic_goal_label.dart';

class HeaderEta extends StatefulWidget {
  const HeaderEta({super.key, required this.routines});

  final List<RoutineSummary> routines;

  @override
  createState() => _HeaderEtaSTate();
}

class _HeaderEtaSTate extends State<HeaderEta> {
  late final AppLifecycleListener _listener;

  DateTime _eta = DateTime.now();
  late Timer _timer;
  bool _ticking = false;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refreshEta);
  }

  @override
  dispose() {
    _listener.dispose();
    if (_ticking) _timer.cancel();
    super.dispose();
  }

  void _refreshEta() {
    final now = DateTime.now();
    var eta = DateTime.now();
    var inPause = true;
    for (final routine in widget.routines) {
      if (routine.running) inPause = false;
      if (routine.lastStarted == null) {
        eta = eta.add(routine.goal);
      } else {
        final left =
            routine.goal -
            routine.spent -
            (routine.running
                ? now.difference(routine.lastStarted!)
                : Duration());
        eta = eta.add(left);
      }
      if (inPause && !_ticking) {
        _ticking = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _refreshEta();
        });
      }
      if (!inPause && _ticking) {
        _ticking = false;
        _timer.cancel();
      }
      setState(() {
        _eta = eta;
      });
    }
  }

  @override
  build(BuildContext context) {
    _refreshEta();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(
              Icons.alarm,
              size: 17,
              color: labelColor(context, Label.homeScreenDayETA),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  _format(_eta),
                  style: TextStyle(
                    fontSize: 18,
                    color: labelColor(context, Label.homeScreenDayETA),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    _eta.hour >= 12 ? "pm" : "am",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: labelColor(context, Label.homeScreenDayETA),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        HeaderRoutinesDynamicGoalLabel(routines: widget.routines),
      ],
    );
  }

  String _format(DateTime t) {
    var h = t.hour;
    if (h == 0) {
      h = 12;
    } else {
      h = h.remainder(12);
    }
    return '$h:${t.minute.toString().padLeft(2, "0")}';
  }
}
