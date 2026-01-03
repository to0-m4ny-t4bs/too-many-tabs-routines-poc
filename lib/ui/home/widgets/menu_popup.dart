import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/add_note_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class MenuPopup extends StatelessWidget {
  const MenuPopup({
    super.key,
    required this.routine,
    required this.homeModel,
    required this.notesModel,
    required this.menu,
    required this.close,
  });

  final RoutineSummary? routine;
  final HomeViewmodel homeModel;
  final NotesViewmodel notesModel;
  final MenuItem? menu;
  final void Function() close;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (routine == null || menu == null) {
      return SizedBox.shrink();
    }

    final List<_PopupAction> actions = [];

    final Widget? popup;
    switch (menu!) {
      case MenuItem.setGoal:
        popup = GoalPopup(
          routineID: routine!.id,
          routineName: routine!.name,
          routineGoal: routine!.goal,
          running: routine!.running,
          viewModel: homeModel,
          onCancel: close,
          onGoalSet: close,
        );
        break;
      case MenuItem.addNote:
        popup = AddNotePopup(
          onClose: close,
          routineId: routine!.id,
          viewModel: notesModel,
        );
        popup as AddNotePopup;
        actions.add(
          _PopupAction(
            alignment: Alignment.bottomRight,
            action: popup.commitNote,
            icon: Icons.check,
            applicationAction: ApplicationAction.addNote,
          ),
        );
        actions.add(
          _PopupAction(
            alignment: Alignment.bottomLeft,
            action: popup.cancelNote,
            icon: Icons.cancel,
            applicationAction: ApplicationAction.cancelAddNote,
          ),
        );
        break;
    }

    final popupContainer = Stack(
      children: [
        Column(
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
        ),
        ...actions,
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

class _PopupAction extends StatelessWidget {
  const _PopupAction({
    required this.alignment,
    required this.icon,
    required this.action,
    required this.applicationAction,
  });
  final Alignment alignment;
  final IconData icon;
  final ApplicationAction applicationAction;
  final Function() action;
  @override
  build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FloatingAction(
        onPressed: action,
        icon: icon,
        colorComposition: colorCompositionFromAction(
          context,
          applicationAction,
        ),
        verticalOffset: 0,
      ),
    );
  }
}
