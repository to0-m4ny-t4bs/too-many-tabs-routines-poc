import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class Routine extends StatelessWidget {
  const Routine({
    super.key,
    required this.routine,
    required this.restore,
    required this.index,
  });

  final RoutineSummary routine;
  final void Function() restore;
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
    return Slidable(
      key: key,
      endActionPane: ActionPane(
        dismissible: DismissiblePane(onDismissed: restore, closeOnCancel: true),
        motion: BehindMotion(),
        children: [
          RoutineAction(
            onPressed: (_) {
              restore();
            },
            icon: Icons.archive,
            state: ApplicationAction.backlogRoutine,
            label: 'Restore',
          ),
        ],
      ),
      child: Container(
        color: background,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  routine.name.trim(),
                  style: TextStyle(color: foreground),
                ),
              ),
              Text(formatUntilGoal(routine.goal, routine.spent)),
            ],
          ),
        ),
      ),
    );
  }
}
