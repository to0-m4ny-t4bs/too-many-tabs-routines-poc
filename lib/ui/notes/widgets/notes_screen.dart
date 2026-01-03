import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.viewModel});

  final NotesViewmodel viewModel;

  @override
  createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: widget.viewModel.load,
      builder: (context, child) {
        final running = widget.viewModel.load.running,
            error = widget.viewModel.load.error;
        return Loader(
          running: running,
          error: error,
          onError: widget.viewModel.load.execute,
          child: child!,
        );
      },
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  backgroundColor: darkMode
                      ? colorScheme.primaryContainer
                      : colorScheme.primaryFixed,
                  title: Text(
                    (widget.viewModel.routine == null)
                        ? ""
                        : widget.viewModel.routine!.name,
                  ),
                ),
                body: ScrollablePositionedList.builder(
                  itemCount: widget.viewModel.notes.length,
                  padding: EdgeInsets.only(),
                  itemBuilder: (_, index) {
                    final note = widget.viewModel.notes[index];
                    return Text(note.text);
                  },
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
