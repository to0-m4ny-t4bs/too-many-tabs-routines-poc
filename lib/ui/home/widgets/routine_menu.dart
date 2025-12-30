import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';

class RoutineMenu extends StatelessWidget {
  const RoutineMenu({
    super.key,
    required this.onClose,
    required this.routine,
    required this.popup,
  });
  final void Function() onClose;
  final void Function(MenuItem) popup;
  final RoutineSummary routine;

  @override
  build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        spacing: 10,
        children: [
          _MenuItem(
            icon: routine.running ? Icons.stop_circle : Icons.play_circle,
            label: routine.running ? "Stop" : "Start",
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.star,
            label: "Set goal",
            onTap: () {
              popup(MenuItem.setGoal);
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final void Function() onTap;
  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          splashColor: colorScheme.onPrimaryContainer,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: colorScheme.primaryContainer,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
                Icon(icon, color: colorScheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
