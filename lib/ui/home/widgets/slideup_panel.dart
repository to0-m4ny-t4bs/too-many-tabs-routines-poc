import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class SlideUpPanel extends StatelessWidget {
  const SlideUpPanel({
    super.key,
    required this.viewModel,
    required this.isOpen,
    required this.pc,
    required this.tappedRoutine,
  });

  final HomeViewmodel viewModel;
  final bool isOpen;
  final RoutineSummary? tappedRoutine;
  final PanelController pc;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return tappedRoutine == null
            ? Container()
            : _SetGoal(
                routineID: tappedRoutine!.id,
                running: tappedRoutine!.running,
                routineName: tappedRoutine!.name,
                routineGoal: tappedRoutine!.goal,
                pc: pc,
                viewModel: viewModel,
              );
      },
    );
  }
}

class Collapsed extends StatelessWidget {
  const Collapsed({super.key, this.runningRoutine, this.eta});

  final RoutineSummary? runningRoutine;
  final DateTime? eta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(top: 4),
      child: Column(
        spacing: 4,
        children: [
          runningRoutine ==
                  null // running routine
              ? Text(
                  'Tap to pick a routine',
                  style: TextStyle(
                    color: darkMode
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.secondary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    _RoutineLabel(
                      running: true,
                      name: runningRoutine!.name,
                      color: darkMode
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.primary,
                      fontWeight: darkMode ? FontWeight.w600 : FontWeight.w300,
                    ),
                    _RoutineETA(
                      eta: eta!,
                      goal: runningRoutine!.goal,
                      restorationId: 'routine-eta-${runningRoutine!.id}',
                    ),
                  ],
                ),
          Expanded(
            child: Text(
              'Long press to set goals',
              style: TextStyle(
                color: darkMode ? colorScheme.secondary : colorScheme.onSurface,
                fontWeight: darkMode ? FontWeight.w500 : FontWeight.w200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetGoal extends StatelessWidget {
  const _SetGoal({
    required this.routineName,
    required this.running,
    required this.pc,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
  });

  final String routineName;
  final int routineID;
  final Duration routineGoal;
  final bool running;
  final PanelController pc;
  final HomeViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: darkMode
              ? [
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ]
              : [
                  colorScheme.surfaceBright,
                  colorScheme.surfaceBright,
                  colorScheme.surfaceBright,
                  colorScheme.surfaceContainerHighest,
                ],
        ),
      ),
      padding: EdgeInsets.only(top: 10),
      child: Column(
        spacing: 17,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Dimens.of(context).rowSpacing,
            children: [
              Text(
                'Set',
                style: TextStyle(
                  color: darkMode
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                ),
              ),
              _RoutineLabel(
                running: running,
                name: routineName,
                color: darkMode ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: darkMode
                    ? (running ? FontWeight.w300 : FontWeight.w600)
                    : (running ? FontWeight.w300 : FontWeight.w400),
              ),
              Text(
                'daily goal',
                style: TextStyle(
                  color: darkMode
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          _GoalSelect(
            pc: pc,
            viewModel: viewModel,
            routineID: routineID,
            routineGoal: routineGoal,
          ),
        ],
      ),
    );
  }
}

class _GoalSelect extends StatefulWidget {
  const _GoalSelect({
    required this.pc,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
  });

  final PanelController pc;
  final int routineID;
  final Duration routineGoal;
  final HomeViewmodel viewModel;

  @override
  createState() => _GoalSelectState();
}

(int, int) indexGoal(Duration goal) {
  if (goal.inMinutes > 0) {
    final hoursIndex = goal.inHours;
    final minutesIndex = goal.inMinutes.remainder(60) ~/ 30;
    return (hoursIndex, minutesIndex);
  }
  return (0, 1); // 0h30m
}

class _GoalSelectState extends State<_GoalSelect> {
  int hoursIndex = 0, minutesIndex = 1; // default is 0h30min

  @override
  @override
  void initState() {
    final initialIndex = indexGoal(widget.routineGoal);
    hoursIndex = initialIndex.$1;
    minutesIndex = initialIndex.$2;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    final double fontSize = 42;
    final numbersTextStyle = TextStyle(
      color: darkMode ? colorScheme.onPrimary : colorScheme.onSurface,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
    );
    final labelsTextStyle = TextStyle(
      color: darkMode ? colorScheme.onPrimaryFixed : colorScheme.onSurface,
      fontWeight: FontWeight.w500,
      fontSize: fontSize / 4,
    );
    final itemExtent = fontSize * 7 / 6 + 2;
    return SizedBox(
      height: 240,
      child: Column(
        spacing: 20,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoalWheel(
                  onSelected: (index) {
                    setState(() {
                      hoursIndex = index;
                    });
                  },
                  initialItem: hoursIndex,
                  width: fontSize * .63,
                  itemExtent: itemExtent,
                  delegate: ListWheelChildBuilderDelegate(
                    childCount: 5,
                    builder: (_, index) {
                      return Text('$index', style: numbersTextStyle);
                    },
                  ),
                ),
                Text('h', style: labelsTextStyle),
                _GoalWheel(
                  onSelected: (index) {
                    setState(() {
                      minutesIndex = index;
                    });
                  },
                  initialItem: minutesIndex,
                  width: fontSize * 1.42,
                  itemExtent: itemExtent,
                  delegate: ListWheelChildBuilderDelegate(
                    childCount: 2,
                    builder: (_, index) {
                      return Text(
                        (index * 30).toString().padLeft(2, '0'),
                        style: numbersTextStyle,
                      );
                    },
                  ),
                ),
                Text('min', style: labelsTextStyle),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.pc.close();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: darkMode
                      ? colorScheme.primary
                      : colorScheme.surface,
                  foregroundColor: darkMode
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                child: Text('Never mind'),
              ),
              ElevatedButton(
                onPressed: minutesIndex == 0 && hoursIndex == 0
                    ? null // set goal button is disabled unless duration > 0
                    : () async {
                        await widget.viewModel.updateRoutineGoal.execute(
                          GoalUpdate(
                            routineID: widget.routineID,
                            goal: Duration(
                              minutes: minutesIndex * 30,
                              hours: hoursIndex,
                            ),
                          ),
                        );
                        if (widget.viewModel.updateRoutineGoal.completed) {
                          widget.pc.close();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: darkMode
                      ? colorScheme.primaryContainer
                      : colorScheme.primary,
                  foregroundColor: darkMode
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onPrimary,
                ),
                child: const Text('Set Goal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalWheel extends StatelessWidget {
  const _GoalWheel({
    required this.delegate,
    required this.itemExtent,
    required this.width,
    required this.initialItem,
    required this.onSelected,
  });

  final ListWheelChildBuilderDelegate delegate;
  final double itemExtent, width;
  final int initialItem;
  final void Function(int) onSelected;

  @override
  build(BuildContext context) {
    return Container(
      width: width,
      margin: EdgeInsets.all(2),
      child: ListWheelScrollView.useDelegate(
        controller: FixedExtentScrollController(initialItem: initialItem),
        onSelectedItemChanged: onSelected,
        physics: FixedExtentScrollPhysics(),
        itemExtent: itemExtent * .92,
        perspective: 0.01,
        diameterRatio: .7,
        childDelegate: delegate,
      ),
    );
  }
}

class _RoutineLabel extends StatelessWidget {
  const _RoutineLabel({
    required this.name,
    required this.running,
    required this.color,
    required this.fontWeight,
  });

  final String name;
  final bool running;
  final Color color;
  final FontWeight fontWeight;

  //static const blurOffset = .1;
  //static const blurRadius = 2.0;

  @override
  build(BuildContext context) {
    //final shadowColor = running
    //    ? Theme.of(context).colorScheme.primary
    //    : Theme.of(context).colorScheme.primaryFixed;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        //color: running
        //    ? Theme.of(context).colorScheme.primary
        //    : Theme.of(context).colorScheme.primaryFixed,
        //boxShadow: [
        //  BoxShadow(
        //    color: shadowColor,
        //    offset: const Offset(blurOffset, blurOffset),
        //    blurRadius: blurRadius,
        //  ),
        //  BoxShadow(
        //    color: shadowColor,
        //    offset: const Offset(-blurOffset, blurOffset),
        //    blurRadius: blurRadius,
        //  ),
        //],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(),
        // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Text(
          name.trim(),
          style: TextStyle(fontWeight: fontWeight, color: color),
        ),
      ),
    );
  }
}

class _RoutineETA extends StatefulWidget {
  const _RoutineETA({
    required this.eta,
    required this.goal,
    required this.restorationId,
  });

  final String restorationId;
  final DateTime eta;
  final Duration goal;

  @override
  createState() => _RoutineETAState();
}

class _RoutineETAState extends State<_RoutineETA> with RestorationMixin {
  late Timer _timer;

  final _done = RestorableBool(false);

  @override
  get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_done, 'left_minutes_value');
  }

  @override
  initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static const _refreshPeriod = Duration(milliseconds: 50);

  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (_) {
      if (DateTime.now().isAfter(widget.eta)) {
        setState(() {
          _done.value = true;
        });
      }
    });
  }

  TextStyle _style(double size) {
    return TextStyle(fontWeight: FontWeight.w300, fontSize: size);
  }

  @override
  build(BuildContext context) {
    if (!_done.value) {
      var hours = widget.eta.hour.remainder(12).toString();
      if (hours == "0") {
        hours = "12";
      }
      final minutes = widget.eta.minute.toString().padLeft(2, '0');
      final tod = widget.eta.hour < 12 ? "am" : "pm";
      return Row(
        children: [
          Text('(ETA: $hours:$minutes', style: _style(12)),
          Text(tod, style: _style(10)),
          Text(')', style: _style(12)),
        ],
      );
    }
    // this block is the only reason we need to  track of _leftMinutes, though,
    // we might be able to stick with a stateless widget and leave the
    // computation (that should happen only once) to the listenable builder
    // building the Collapsed widget.
    return Text(
      '(reached ${formatUntilGoal(widget.goal, Duration())})',
      style: _style(12),
    );
  }
}
