import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/utils/format_duration.dart';
import 'package:too_many_tabs/ui/core/colors.dart' as comp;

class Routine extends StatelessWidget {
  const Routine({
    super.key,
    required this.routine,
    required this.restore,
    required this.trash,
    required this.index,
  });

  final RoutineSummary routine;
  final void Function() restore, trash;
  final int index;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final background = index % 2 == (darkMode ? 0 : 1)
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    final foreground = index % 2 == (darkMode ? 0 : 1)
        ? colorScheme.onSurface
        : colorScheme.onSurface;
    final dismissReschedule = comp.Colors(
      context,
      ApplicationAction.rescheduleRoutine,
    );
    final dismissArchive = comp.Colors(context, ApplicationAction.toArchive);
    return Dismissible(
      key: ValueKey(key),
      // left to right: toArchive
      background: Container(
        color: dismissArchive.background,
        child: Padding(
          padding: EdgeInsets.only(left: 25),
          child: Row(
            children: [Icon(Icons.delete, color: dismissArchive.foreground)],
          ),
        ),
      ),
      // right to left: rescheduleRoutine
      secondaryBackground: Container(
        color: dismissReschedule.background,
        child: Padding(
          padding: EdgeInsets.only(right: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.add_task, color: dismissReschedule.foreground),
            ],
          ),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          trash();
        }
        if (direction == DismissDirection.endToStart) {
          restore();
        }
      },
      child: Container(
        color: background,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  routine.name.trim(),
                  style: TextStyle(color: foreground),
                ),
              ),
              Text(
                formatUntilGoal(routine.goal, routine.spent),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
