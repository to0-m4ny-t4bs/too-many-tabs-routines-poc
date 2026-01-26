import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/add_note_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_popup.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/notes/widgets/note.dart';
import 'package:too_many_tabs/utils/format_duration.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.notesViewmodel,
    required this.homeViewmodel,
  });

  final NotesViewmodel notesViewmodel;
  final HomeViewmodel homeViewmodel;

  @override
  createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool showActionButtons = true;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: widget.notesViewmodel.load,
      builder: (context, child) {
        final running = widget.notesViewmodel.load.running,
            error = widget.notesViewmodel.load.error;
        return Loader(
          running: running,
          error: error,
          onError: widget.notesViewmodel.load.execute,
          child: child!,
        );
      },
      child: ListenableBuilder(
        listenable: widget.notesViewmodel,
        builder: (context, child) {
          final count = widget.notesViewmodel.notes.length;
          final routine = widget.notesViewmodel.routine;
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  backgroundColor: darkMode
                      ? colorScheme.primaryContainer
                      : colorScheme.primaryFixed,
                  title: widget.notesViewmodel.routine == null
                      ? SizedBox.shrink()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(routine!.name),
                            GestureDetector(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Symbols.trophy),
                                  ListenableBuilder(
                                    listenable: widget.homeViewmodel,
                                    builder: (context, _) {
                                      final routineId = routine.id;
                                      RoutineSummary? routineUpdate;
                                      for (final routineCandidate
                                          in widget.homeViewmodel.routines) {
                                        if (routineCandidate.$1.id ==
                                            routineId) {
                                          routineUpdate = routineCandidate.$1;
                                          break;
                                        }
                                      }
                                      return Text(
                                        formatUntilGoal(
                                          routineUpdate!.goal,
                                          Duration.zero,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ), // Row
                              onTap: () {
                                _goalPopup();
                              },
                            ), // GestureDetector
                          ],
                        ), // Row
                ),
                body: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .8, 1],
                      colors: [Colors.black, Colors.black, Colors.transparent],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ScrollablePositionedList.builder(
                    itemCount: count,
                    padding: EdgeInsets.only(bottom: 140),
                    itemBuilder: (_, index) {
                      final note = widget.notesViewmodel.notes[index];
                      return Note(
                        count: count,
                        index: index,
                        note: note,
                        onDismiss: () {
                          widget.notesViewmodel.dismissNote.execute(note.id!);
                        },
                      );
                    },
                  ),
                ),
              ),
              ..._actionButtons(context),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _actionButtons(BuildContext context) {
    return showActionButtons
        ? [
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingAction(
                onPressed: _notePopup,
                icon: Icons.add,
                colorComposition: colorCompositionFromAction(
                  context,
                  ApplicationAction.addNote,
                ),
                verticalOffset: 40,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: FloatingAction(
                onPressed: () => context.go(Routes.home),
                icon: Icons.home,
                colorComposition: colorCompositionFromAction(
                  context,
                  ApplicationAction.toHome,
                ),
                verticalOffset: 40,
              ),
            ),
          ]
        : [];
  }

  void _toggleActionButtons() {
    setState(() {
      showActionButtons = !showActionButtons;
    });
  }

  void _goalPopup() async {
    final routine = widget.notesViewmodel.routine!;
    final popup = GoalPopup(
      routineName: routine.name,
      running: routine.running,
      viewModel: widget.homeViewmodel,
      routineID: routine.id,
      routineGoal: routine.goal,
      close: () {},
    );
    _toggleActionButtons();
    final colors = colorCompositionFromAction(
      context,
      ApplicationAction.setGoal,
    );
    await showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            appBar: AppBar(title: const Text("Set daily goal")),
            backgroundColor: Colors.black.withValues(alpha: 0),
            body: Stack(
              children: [
                popup,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Material(
                      borderRadius: BorderRadius.circular(100),
                      color: colors.background,
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          popup.commit();
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Update',
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _toggleActionButtons();
  }

  void _notePopup() {
    final popup = AddNotePopup(
      onClose: () {},
      viewModel: widget.notesViewmodel,
      routineId: widget.notesViewmodel.routine!.id,
    );
    _toggleActionButtons();
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  popup,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FloatingAction(
                        onPressed: () {
                          _toggleActionButtons();
                          Navigator.pop(context);
                        },
                        icon: Icons.close,
                        colorComposition: colorCompositionFromAction(
                          context,
                          ApplicationAction.cancelAddNote,
                        ),
                      ),
                      FloatingAction(
                        onPressed: () {
                          popup.commitNote();
                          widget.notesViewmodel.load.execute();
                          _toggleActionButtons();
                          Navigator.pop(context);
                        },
                        icon: Icons.add,
                        colorComposition: colorCompositionFromAction(
                          context,
                          ApplicationAction.addNote,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
