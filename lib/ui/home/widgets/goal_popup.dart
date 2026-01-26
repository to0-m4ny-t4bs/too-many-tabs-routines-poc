import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';

class GoalPopup extends StatefulWidget {
  GoalPopup({
    super.key,
    required this.routineName,
    required this.running,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
    required this.close,
  });

  final void Function() close;
  final String routineName;
  final int routineID;
  final Duration routineGoal;
  final bool running;
  final HomeViewmodel viewModel;

  final _stateKey = GlobalKey<GoalPopupState>();

  void commit() {
    _stateKey.currentState?.commit();
  }

  @override
  get key => _stateKey;

  @override
  createState() => GoalPopupState();
}

class GoalPopupState extends State<GoalPopup> {
  void commit() {
    setter.commit();
  }

  late SetGoal setter;

  @override
  void initState() {
    super.initState();
    setter = SetGoal(
      routineName: widget.routineName,
      running: widget.running,
      viewModel: widget.viewModel,
      routineID: widget.routineID,
      routineGoal: widget.routineGoal,
      close: widget.close,
    );
  }

  @override
  Widget build(BuildContext context) {
    return setter;
  }
}

class SetGoal extends StatefulWidget {
  SetGoal({
    super.key,
    required this.routineName,
    required this.running,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
    required this.close,
  });

  final String routineName;
  final int routineID;
  final Duration routineGoal;
  final bool running;
  final HomeViewmodel viewModel;
  final void Function() close;

  final _stateKey = GlobalKey<SetGoalState>();

  void commit() => _stateKey.currentState?.commit();

  @override
  get key => _stateKey;

  @override
  createState() => SetGoalState();
}

class SetGoalState extends State<SetGoal> {
  late GoalSelect select;

  void commit() => select.commitGoal();

  @override
  void initState() {
    super.initState();
    select = GoalSelect(
      viewModel: widget.viewModel,
      routineID: widget.routineID,
      routineGoal: widget.routineGoal,
      close: widget.close,
    );
  }

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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          spacing: 17,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [select],
        ),
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
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .2, .5, .8, 1],
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black,
            Colors.transparent,
            Colors.transparent,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Container(
        width: width,
        margin: EdgeInsets.all(2),
        child: ListWheelScrollView.useDelegate(
          controller: FixedExtentScrollController(initialItem: initialItem),
          onSelectedItemChanged: onSelected,
          physics: FixedExtentScrollPhysics(),
          itemExtent: itemExtent * .92,
          perspective: 0.003,
          diameterRatio: .7,
          childDelegate: delegate,
        ),
      ),
    );
  }
}

class GoalSelect extends StatefulWidget {
  GoalSelect({
    super.key,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
    required this.close,
  });

  final _stateKey = GlobalKey<GoalSelectState>();

  void commitGoal() {
    _stateKey.currentState?.commitGoal();
  }

  @override
  GlobalKey<GoalSelectState> get key => _stateKey;

  void cancel() => close();

  final int routineID;
  final Duration routineGoal;
  final HomeViewmodel viewModel;
  final void Function() close;

  @override
  createState() => GoalSelectState();
}

(int, int) indexGoal(Duration goal) {
  if (goal.inMinutes > 0) {
    final hoursIndex = goal.inHours;
    final minutesIndex = goal.inMinutes.remainder(60) ~/ 30;
    return (hoursIndex, minutesIndex);
  }
  return (0, 1); // 0h30m
}

class GoalSelectState extends State<GoalSelect> {
  int hoursIndex = 0, minutesIndex = 1; // default is 0h30min

  @override
  @override
  void initState() {
    final initialIndex = indexGoal(widget.routineGoal);
    hoursIndex = initialIndex.$1;
    minutesIndex = initialIndex.$2;
    super.initState();
  }

  void commitGoal() async {
    await widget.viewModel.updateRoutineGoal.execute(
      GoalUpdate(
        routineID: widget.routineID,
        goal: Duration(minutes: minutesIndex * 30, hours: hoursIndex),
      ),
    );
    if (widget.viewModel.updateRoutineGoal.completed) {
      widget.close();
    }
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
        ],
      ),
    );
  }
}
