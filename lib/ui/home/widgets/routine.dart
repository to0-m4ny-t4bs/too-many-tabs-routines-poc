import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_goal_label.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_spent_dynamic_label.dart';

class Routine extends StatelessWidget {
  const Routine({
    super.key,
    required this.routine,
    required this.setGoal,
    required this.startStopSwitch,
    required this.archive,
  });

  final RoutineSummary routine;
  final Function() setGoal, startStopSwitch, archive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final dismissibleColors = colorCompositionFromAction(
      context,
      ApplicationAction.toBacklog,
    );
    return Dismissible(
      key: ValueKey(routine.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        archive();
      },
      background: Container(
        color: dismissibleColors.background,
        child: Padding(
          padding: EdgeInsets.only(left: 25),
          child: Row(
            children: [
              Icon(Icons.archive, color: dismissibleColors.foreground),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: routine.running ? 10 : 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: routine.running
                    ? BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : BoxDecoration(),
              ),
            ),
            InkWell(
              splashColor: colorScheme.primaryContainer,
              onLongPress: startStopSwitch,
              onTap: setGoal,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5 + 20,
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: routine.running ? 10 : 20,
                              right: 5,
                            ),
                            child: Container(
                              width: 5,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: routine.running
                                    ? (darkMode
                                          ? colorScheme.primary
                                          : colorScheme.primary)
                                    : (darkMode
                                          ? colorScheme.primaryContainer
                                          : colorScheme.primaryFixed),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      routine.name.trim(),
                                      style: TextStyle(fontSize: 16),
                                      // overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                  routine.running
                                      ? RoutineSpentDynamicLabel(
                                          restorationId:
                                              'routine_spent_dynamic_label_${routine.id}',
                                          key: ValueKey(routine.id),
                                          spent: routine.spent,
                                          lastStarted: routine.lastStarted!,
                                        )
                                      : RoutineSpentLabel(spent: routine.spent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: routine.running
                          ? RoutineGoalDynamicLabel(
                              restorationId:
                                  'routine_goal_dynamic_label_${routine.id}',
                              key: ValueKey(routine.id),
                              spent: routine.spent,
                              goal: routine.goal,
                              running: routine.running,
                              lastStarted: routine.lastStarted!,
                            )
                          : RoutineGoalLabel(
                              spent: routine.spent,
                              goal: routine.goal,
                              running: routine.running,
                              lastStarted: routine.lastStarted,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
