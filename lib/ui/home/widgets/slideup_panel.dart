import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';

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
  const Collapsed({super.key, required this.runningRoutine});

  final RoutineSummary? runningRoutine;

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
                  'Swipe any item to start the routine timer.',
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
                    Text(
                      'Good luck with',
                      style: TextStyle(
                        fontWeight: darkMode
                            ? FontWeight.w500
                            : FontWeight.w300,
                      ),
                    ),
                    _RoutineLabel(
                      running: true,
                      name: runningRoutine!.name,
                      color: darkMode
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.primary,
                      fontWeight: darkMode ? FontWeight.w600 : FontWeight.w300,
                    ),
                    const Text('!'),
                  ],
                ),
          Expanded(
            child: Text(
              'Tap any item to update goals.',
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
  Widget build(BuildContext context) {
    final initialIndex = indexGoal(widget.routineGoal);
    setState(() {
      hoursIndex = initialIndex.$1;
      minutesIndex = initialIndex.$2;
    });
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
    final itemExtent = fontSize * 7 / 6;
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
          name,
          style: TextStyle(fontWeight: fontWeight, color: color),
        ),
      ),
    );
  }
}
