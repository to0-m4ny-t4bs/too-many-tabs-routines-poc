import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/view_models/special_goal_setting_update.dart';

class GoalPopup extends StatelessWidget {
  const GoalPopup({
    super.key,
    required this.viewModel,
    required this.goalSetting,
    required this.onCancel,
    required this.onGoalSet,
    required this.currentGoal,
  });

  final void Function() onCancel, onGoalSet;
  final SpecialGoal goalSetting;
  final SettingsViewmodel viewModel;
  final Duration currentGoal;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: _SetGoal(
        viewModel: viewModel,
        goalSetting: goalSetting,
        currentGoal: currentGoal,
        onCancel: onCancel,
        onGoalSet: onGoalSet,
      ),
    );
  }
}

class _SetGoal extends StatelessWidget {
  const _SetGoal({
    required this.viewModel,
    required this.goalSetting,
    required this.onCancel,
    required this.onGoalSet,
    required this.currentGoal,
  });

  final Duration currentGoal;
  final SpecialGoal goalSetting;
  final SettingsViewmodel viewModel;
  final void Function() onCancel, onGoalSet;

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
              viewModel: viewModel,
              goalSetting: goalSetting,
              currentGoal: currentGoal,
              onCancel: onCancel,
              onGoalSet: onGoalSet,
            ),
          ],
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

class _GoalSelect extends StatefulWidget {
  const _GoalSelect({
    required this.viewModel,
    required this.goalSetting,
    required this.currentGoal,
    required this.onCancel,
    required this.onGoalSet,
  });

  final SpecialGoal goalSetting;
  final Duration currentGoal;
  final SettingsViewmodel viewModel;
  final void Function() onCancel, onGoalSet;

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
  void initState() {
    final initialIndex = indexGoal(widget.currentGoal);
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
                onPressed: widget.onCancel,
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
                onPressed: () async {
                  await widget.viewModel.updateSpecialGoalSetting.execute(
                    SpecialGoalSettingUpdate(
                      setting: widget.goalSetting,
                      goal: Duration(
                        minutes: minutesIndex * 30,
                        hours: hoursIndex,
                      ),
                    ),
                  );
                  if (widget.viewModel.updateSpecialGoalSetting.completed) {
                    widget.onGoalSet();
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
