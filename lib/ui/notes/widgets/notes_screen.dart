import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/notes/widgets/note.dart';

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
                    itemCount: widget.viewModel.notes.length,
                    padding: EdgeInsets.only(bottom: 140, top: 20),
                    itemBuilder: (_, index) {
                      final note = widget.viewModel.notes[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Note(text: note.text),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: index + 1 == widget.viewModel.notes.length
                                ? SizedBox.shrink()
                                : Container(
                                    color: colorScheme.primary,
                                    height: .2,
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
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
            ],
          );
        },
      ),
    );
  }
}
