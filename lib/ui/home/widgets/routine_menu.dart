import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';

class RoutineMenu extends StatelessWidget {
  const RoutineMenu({
    super.key,
    required this.close,
    required this.routine,
    required this.popup,
    required this.homeViewmodel,
  });
  final void Function(int) close;
  final void Function(MenuItem) popup;
  final RoutineSummary routine;
  final HomeViewmodel homeViewmodel;

  @override
  build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        spacing: 10,
        children: [
          ListenableBuilder(
            listenable: homeViewmodel,
            builder: (context, _) {
              final running =
                  homeViewmodel.pinnedRoutine != null &&
                  routine.id == homeViewmodel.pinnedRoutine!.id;
              return _MenuItem(
                icon: running ? Icons.stop_circle : Icons.play_circle,
                label: running ? "Stop" : "Start",
                onTap: () {
                  homeViewmodel.startOrStopRoutine.execute(routine.id);
                  close(0);
                },
              );
            },
          ),
          _MenuItem(
            icon: Icons.star,
            label: "Set goal",
            onTap: () {
              popup(MenuItem.setGoal);
            },
          ),
          _MenuItem(
            icon: Icons.note_add,
            label: "Add note",
            onTap: () {
              popup(MenuItem.addNote);
            },
          ),
          _MenuItem(
            icon: Icons.notes,
            label: "Notes",
            onTap: () {
              context.go('${Routes.notes}/${routine.id}');
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
