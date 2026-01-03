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
        ? colorScheme.primaryContainer.withValues(alpha: .1)
        : colorScheme.surfaceContainerLow;
    final foreground = index % 2 == (darkMode ? 0 : 1)
        ? colorScheme.onSurface
        : colorScheme.onSurface;
    final colors = comp.Colors(context, ApplicationAction.restoreRoutine);
    return Dismissible(
      key: ValueKey(key),
      background: Container(
        color: colors.background,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Icon(Icons.archive, color: colors.foreground)],
          ),
        ),
      ),
      onDismissed: (_) {
        restore();
      },
      direction: DismissDirection.endToStart,
      child: Container(
        color: background,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
