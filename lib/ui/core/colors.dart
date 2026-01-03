import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';

class Colors {
  Colors(BuildContext context, ApplicationAction action)
    : _comp = colorCompositionFromAction(context, action);
  final ColorComposition _comp;
  Color get foreground => _comp.foreground;
  Color get background => _comp.background;
}
