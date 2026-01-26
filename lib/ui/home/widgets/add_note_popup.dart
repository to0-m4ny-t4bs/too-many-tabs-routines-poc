import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class AddNotePopup extends StatefulWidget {
  AddNotePopup({
    super.key,
    required this.onClose,
    required this.viewModel,
    required this.routineId,
  });

  final void Function() onClose;
  final NotesViewmodel viewModel;
  final int routineId;

  // Expose a method that forwards the call to the State via a GlobalKey.
  // This follows the Flutter best‑practice of keeping the State private
  // while still allowing the widget to be interacted with from the outside.
  final GlobalKey<AddNotePopupState> _stateKey = GlobalKey<AddNotePopupState>();

  void commitNote() => _stateKey.currentState?.commitNote();
  void cancelNote() => _stateKey.currentState?.cancelNote();

  @override
  State<AddNotePopup> createState() => AddNotePopupState();

  // Provide the key to the State when it is created.
  @override
  GlobalKey<AddNotePopupState> get key => _stateKey;
}

class AddNotePopupState extends State<AddNotePopup> {
  final noteTextController = TextEditingController();

  void commitNote() {
    final trimmed = noteTextController.text.trim();
    if (trimmed.isEmpty) return;
    widget.viewModel.addNote.execute(
      NoteSummary(
        note: noteTextController.text,
        createdAt: DateTime.now(),
        routineId: widget.routineId,
        dismissed: false,
      ),
    );
    widget.onClose();
  }

  void cancelNote() {
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: noteTextController,
      maxLines: null,
      decoration: InputDecoration(
        hintText: "Add note... 🖊️",
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
