import 'package:flutter/material.dart';

class HeaderAction extends StatelessWidget {
  const HeaderAction({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final void Function() onPressed;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      // color: darkMode
      //     ? colorScheme.onPrimaryContainer
      //     : colorScheme.onPrimaryFixed,
      color: darkMode ? colorScheme.onPrimaryContainer : colorScheme.primary,
    );
  }
}
