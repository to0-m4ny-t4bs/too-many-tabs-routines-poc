import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';

class MenuPopup extends StatelessWidget {
  const MenuPopup({
    super.key,
    required this.routine,
    required this.viewModel,
    required this.menu,
    required this.close,
  });

  final RoutineSummary? routine;
  final HomeViewmodel viewModel;
  final MenuItem? menu;
  final void Function() close;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (routine == null || menu == null) {
      return SizedBox.shrink();
    }

    final Widget? popup;
    switch (menu!) {
      case MenuItem.setGoal:
        popup = GoalPopup(
          routineID: routine!.id,
          routineName: routine!.name,
          routineGoal: routine!.goal,
          running: routine!.running,
          viewModel: viewModel,
          onCancel: close,
          onGoalSet: close,
        );
        break;
    }

    final popupContainer = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ), // Shadow color with opacity
                blurRadius: 15.0, // Controls the blurriness
                spreadRadius: 2.0, // Controls how much the shadow spreads
                offset: const Offset(
                  0.0,
                  0.0,
                ), // Key for symmetry: centers the shadow
              ),
            ],
          ),
          child: popup,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withValues(alpha: .6),
            colorScheme.surfaceContainer.withValues(alpha: .8),
            colorScheme.surface.withValues(alpha: .8),
          ],
        ),
      ),
      child: Column(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: popupContainer,
            ),
          ),
        ],
      ),
    );
  }
}
