import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ColorComposition {
  const ColorComposition({
    required this.foreground,
    required this.background,
    required this.action,
  });
  final Color foreground;
  final Color background;
  final ApplicationAction action;
}

ColorComposition colorCompositionFromAction(
  BuildContext context,
  ApplicationAction action,
) {
  final Color background, foreground;
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (action) {
    case ApplicationAction.startRoutine:
    case ApplicationAction.toHome:
      foreground = darkMode ? colorScheme.primary : colorScheme.onPrimary;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.primary;
      break;
    case ApplicationAction.stopRoutine:
      foreground = darkMode ? colorScheme.onSurface : colorScheme.onTertiary;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.tertiary;
      break;
    case ApplicationAction.backlogRoutine:
    case ApplicationAction.archiveRoutine:
    case ApplicationAction.toBacklog:
    case ApplicationAction.toArchive:
      foreground = darkMode
          ? colorScheme.onSurface
          : colorScheme.onInverseSurface;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.inverseSurface;
      break;
    case ApplicationAction.rescheduleRoutine:
    case ApplicationAction.restoreRoutine:
      foreground = colorScheme.primary;
      background = colorScheme.surface;
      break;
    case ApplicationAction.downloadBackup:
    case ApplicationAction.addRoutine:
      background = darkMode
          ? colorScheme.primaryContainer
          : colorScheme.primary;
      foreground = darkMode
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimary;
      break;
  }
  return ColorComposition(
    foreground: foreground,
    background: background,
    action: action,
  );
}

class RoutineAction extends StatelessWidget {
  const RoutineAction({
    super.key,
    required this.onPressed,
    required this.state,
    required this.icon,
    required this.label,
  });

  final Function(BuildContext) onPressed;
  final ApplicationAction state;
  final IconData icon;
  final String label;

  @override
  build(BuildContext context) {
    final composition = colorCompositionFromAction(context, state);
    return SlidableAction(
      backgroundColor: composition.background,
      foregroundColor: composition.foreground,
      onPressed: onPressed,
      icon: icon,
      label: label,
    );
  }
}

enum ApplicationAction {
  startRoutine(0),
  stopRoutine(1),
  backlogRoutine(2),
  archiveRoutine(3),
  rescheduleRoutine(4),
  restoreRoutine(5),
  addRoutine(6),
  toHome(7),
  toBacklog(8),
  toArchive(9),
  downloadBackup(10);

  const ApplicationAction(this.code);

  final int code;
}
