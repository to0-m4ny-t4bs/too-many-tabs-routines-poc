import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/routine_action.dart';

class FloatingAction extends StatelessWidget {
  const FloatingAction({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.colorComposition,
    this.verticalOffset,
  });

  final ColorComposition colorComposition;
  final void Function() onPressed;
  final IconData icon;
  final double? verticalOffset;

  @override
  build(BuildContext context) {
    const defaultOffset = 15.0;
    final double offset = verticalOffset == null
        ? defaultOffset
        : verticalOffset! + defaultOffset;
    return Padding(
      padding: EdgeInsets.only(bottom: offset, left: 25, right: 25),
      child: FloatingActionButton(
        heroTag: colorComposition.action.toString(),
        shape: CircleBorder(),
        foregroundColor: colorComposition.foreground,
        backgroundColor: colorComposition.background,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
