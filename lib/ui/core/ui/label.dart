import 'package:flutter/material.dart';

enum Label {
  homeScreenNumberOfPlannedRoutines(),
  homeScreenDayETA(),
  homeScreenRoutinesPlannedToday(),
  homeScreenGoalTotal(),
  homeScreenSpecialGoalTitle(),
}

Color labelColor(BuildContext context, Label label) {
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (label) {
    case Label.homeScreenNumberOfPlannedRoutines:
    case Label.homeScreenRoutinesPlannedToday:
    case Label.homeScreenDayETA:
    case Label.homeScreenSpecialGoalTitle:
      return darkMode
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimaryFixed;
    case Label.homeScreenGoalTotal:
      return darkMode
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimaryFixedVariant;
  }
}
