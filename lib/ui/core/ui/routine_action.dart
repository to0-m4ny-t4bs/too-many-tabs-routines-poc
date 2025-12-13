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
  final RoutineActionState action;
}

ColorComposition colorCompositionFromAction(
  BuildContext context,
  RoutineActionState action,
) {
  final Color background, foreground;
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (action) {
    case RoutineActionState.toStart:
    case RoutineActionState.toHome:
      foreground = darkMode ? colorScheme.primary : colorScheme.onPrimary;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.primary;
      break;
    case RoutineActionState.toStop:
      foreground = darkMode ? colorScheme.onSurface : colorScheme.onTertiary;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.tertiary;
      break;
    case RoutineActionState.toArchive:
    case RoutineActionState.toTrash:
      foreground = darkMode
          ? colorScheme.onSurface
          : colorScheme.onInverseSurface;
      background = darkMode
          ? colorScheme.surfaceContainerLow
          : colorScheme.inverseSurface;
      break;
    case RoutineActionState.toReschedule:
    case RoutineActionState.toRestore:
      foreground = colorScheme.primary;
      background = colorScheme.surface;
      break;
    case RoutineActionState.toAdd:
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
  final RoutineActionState state;
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

enum RoutineActionState {
  toStart(0),
  toStop(1),
  toArchive(2),
  toTrash(3),
  toReschedule(4),
  toRestore(5),
  toAdd(6),
  toHome(7);

  const RoutineActionState(this.code);

  final int code;
}
