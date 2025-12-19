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
  const Collapsed({super.key, required this.viewModel});

  final HomeViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(top: 5),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.pinnedRoutine != null) {
            final running = viewModel.pinnedRoutine!;
            final done = running.spent > running.goal;
            final eta = running.lastStarted!.add(running.goal - running.spent);
            return Column(
              spacing: 4,
              children: [
                _RoutineLabel(running: true, name: running.name),
                _RoutineETA(eta: eta, goal: running.goal, done: done),
              ],
            );
          } else {
            return Column(
              spacing: 4,
              children: [
                Text(
                  'Free your mind',
                  style: TextStyle(
                    color: darkMode
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.secondary,
                  ),
                ),
                Text(
                  'and your ass will follow.',
                  style: TextStyle(
                    color: darkMode
                        ? colorScheme.secondary
                        : colorScheme.onSurface,
                    fontWeight: darkMode ? FontWeight.w500 : FontWeight.w200,
                  ),
                ),
              ],
            );
          }
        },
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
  const _RoutineLabel({required this.name, required this.running});

  final String name;
  final bool running;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      name.trim(),
      style: TextStyle(
        color: darkMode
            ? colorScheme.onPrimaryContainer
            : colorScheme.secondary,
      ),
    );
  }
}

class _RoutineETA extends StatelessWidget {
  const _RoutineETA({
    required this.done,
    required this.eta,
    required this.goal,
  });
  final bool done;
  final DateTime? eta;
  final Duration goal;

  TextStyle _style(BuildContext context, double? size) {
    final fontWeight = Theme.of(context).brightness == Brightness.dark
        ? FontWeight.w500
        : FontWeight.w200;
    return TextStyle(fontWeight: fontWeight, fontSize: size);
  }

  @override
  build(BuildContext context) {
    if (!done) {
      var hours = eta!.hour.remainder(12).toString();
      if (hours == "0") {
        hours = "12";
      }
      final minutes = eta!.minute.toString().padLeft(2, '0');
      final tod = eta!.hour < 12 ? "am" : "pm";
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 5,
        children: [
          Text('ETA', style: _style(context, 12)),
          Text('$hours:$minutes', style: _style(context, null)),
          Text(tod, style: _style(context, 12)),
        ],
      );
    }
    return Text(
      'Completed (${formatUntilGoal(goal, Duration())})',
      style: _style(context, null),
    );
  }
}
