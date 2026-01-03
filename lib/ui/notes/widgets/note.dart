import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';

class Note extends StatelessWidget {
  const Note({
    super.key,
    required this.note,
    required this.index,
    required this.count,
    required this.onDismiss,
  });
  final NoteSummary note;
  final int index, count;
  final void Function() onDismiss;
  @override
  build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = 10 ^ (math.log(count) / math.ln10).ceil();
    final uid = base + note.id!;
    debugPrint(
      'note ${note.id} dismissed=${note.dismissed} idx=$index uid=$uid',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        note.dismissed
            ? _Note(text: note.text, dismissed: true, top: index == 0)
            : Dismissible(
                key: ValueKey(uid),
                direction: DismissDirection.endToStart,
                background: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [Icon(Icons.layers_clear)],
                  ),
                ),
                onDismissed: (_) async {
                  onDismiss();
                },
                child: _Note(text: note.text, top: index == 0),
              ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: index + 1 == count
              ? SizedBox.shrink()
              : Container(color: cs.primary, height: .2),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, bool? dismissed, required this.top})
    : _dismissed = dismissed ?? false;
  final String text;
  final bool _dismissed;
  final bool top;
  @override
  build(BuildContext context) {
    return Padding(
      padding: top
          ? EdgeInsets.only(top: 20, bottom: 5, left: 30, right: 30)
          : EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      child: Text(
        text,
        style: _dismissed ? TextStyle(fontWeight: FontWeight.w200) : null,
      ),
    );
  }
}
