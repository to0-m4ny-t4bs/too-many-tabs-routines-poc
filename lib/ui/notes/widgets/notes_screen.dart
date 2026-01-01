import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
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
      child: Scaffold(
        appBar: AppBar(title: Text(widget.viewModel.routine.name)),
      ),
    );
  }
}
