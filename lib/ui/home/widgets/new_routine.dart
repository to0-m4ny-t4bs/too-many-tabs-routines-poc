import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';

class NewRoutine extends StatefulWidget {
  const NewRoutine({
    super.key,
    required this.viewModel,
    required this.closeCancel,
    required this.closeCompleted,
  });

  final HomeViewmodel viewModel;
  final void Function(int) closeCompleted;
  final void Function() closeCancel;

  @override
  createState() => _NewRoutineState();
}

class _NewRoutineState extends State<NewRoutine> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    final addComp = colorCompositionFromAction(
      context,
      ApplicationAction.addRoutine,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width * .88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainer,
        boxShadow: List<BoxShadow>.generate(4, (index) {
          var i = 1, j = 1;
          if (index == 1) i = -1;
          if (index == 2) j = -1;
          if (index == 3) {
            i = -1;
            j = -1;
          }
          final double offset = 10;
          return BoxShadow(
            color: colorScheme.surfaceDim,
            offset: Offset(i * offset, j * offset),
            blurRadius: 10,
          );
        }),
        //BoxShadow(
        //  color: colorScheme.surfaceDim,
        //  offset: Offset(30, 30),
        //  blurRadius: 20,
        //),
      ),
      padding: EdgeInsets.all(22),
      child: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              hintText: "Name your planned routine",
            ),
            controller: textController,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: widget.closeCancel,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.viewModel.addRoutine.execute(
                    textController.text.trim(),
                  );
                  if (widget.viewModel.addRoutine.error) return;
                  if (widget.viewModel.addRoutine.completed) {
                    widget.closeCompleted(
                      widget.viewModel.lastCreatedRoutineID!,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: addComp.background,
                  foregroundColor: addComp.foreground,
                ),
                child: const Text('Add routine'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
