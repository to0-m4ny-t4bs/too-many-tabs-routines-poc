import 'package:flutter/material.dart';

enum Label {
  homeScreenNumberOfPlannedRoutines(0),
  homeScreenDayETA(1),
  homeScreenRoutinesPlannedToday(2),
  homeScreenGoalTotal(3);

  const Label(this.code);

  final int code;
}

Color labelColor(BuildContext context, Label label) {
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (label) {
    case Label.homeScreenNumberOfPlannedRoutines:
    case Label.homeScreenRoutinesPlannedToday:
    case Label.homeScreenDayETA:
      return darkMode
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimaryFixed;
    case Label.homeScreenGoalTotal:
      return darkMode
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimaryFixedVariant;
  }
}
