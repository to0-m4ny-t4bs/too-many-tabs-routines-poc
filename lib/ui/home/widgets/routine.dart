import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_goal_label.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_spent_dynamic_label.dart';

class Routine extends StatefulWidget {
  const Routine({
    super.key,
    required this.routine,
    required this.onTap,
    required this.onSwitch,
    required this.archive,
    required this.bin,
    required this.closeAll,
  });

  final RoutineSummary routine;
  final GestureTapCallback onTap;
  final Function(BuildContext) onSwitch, archive, bin;
  final void Function(SlidableController Function()) closeAll;

  @override
  createState() => _RoutineState();
}

class _RoutineState extends State<Routine> with SingleTickerProviderStateMixin {
  late SlidableController _controller;

  @override
  initState() {
    super.initState();
    _controller = SlidableController(this);
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Slidable(
      controller: _controller,
      key: ValueKey(widget.routine.id),
      endActionPane: ActionPane(
        motion: BehindMotion(),
        children: [
          RoutineAction(
            icon: widget.routine.running ? Icons.stop : Icons.timer,
            state: widget.routine.running
                ? RoutineActionState.toStop
                : RoutineActionState.toStart,
            label: widget.routine.running ? 'Stop' : 'Start',
            onPressed: widget.onSwitch,
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          RoutineAction(
            icon: Icons.delete,
            state: RoutineActionState.toTrash,
            label: 'Trash',
            onPressed: widget.archive,
          ),
          RoutineAction(
            icon: Icons.archive,
            state: RoutineActionState.toArchive,
            label: 'Backlog',
            onPressed: widget.archive,
          ),
        ],
      ),
      child: InkWell(
        splashColor: colorScheme.primaryContainer,
        onTap: () {
          widget.closeAll(() => _controller);
          widget.onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * .5 + 20,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: widget.routine.running
                              ? (darkMode
                                    ? colorScheme.primary
                                    : colorScheme.primary)
                              : (darkMode
                                    ? colorScheme.primaryContainer
                                    : colorScheme.primaryFixed),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.routine.name.trim(),
                                style: TextStyle(fontSize: 16),
                                // overflow: TextOverflow.fade,
                                softWrap: false,
                              ),
                            ),
                            widget.routine.running
                                ? RoutineSpentDynamicLabel(
                                    restorationId:
                                        'routine_spent_dynamic_label_${widget.routine.id}',
                                    key: ValueKey(widget.routine.id),
                                    spent: widget.routine.spent,
                                    lastStarted: widget.routine.lastStarted!,
                                  )
                                : RoutineSpentLabel(
                                    spent: widget.routine.spent,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: widget.routine.running
                    ? RoutineGoalDynamicLabel(
                        restorationId:
                            'routine_goal_dynamic_label_${widget.routine.id}',
                        key: ValueKey(widget.routine.id),
                        spent: widget.routine.spent,
                        goal: widget.routine.goal,
                        running: widget.routine.running,
                        lastStarted: widget.routine.lastStarted!,
                      )
                    : RoutineGoalLabel(
                        spent: widget.routine.spent,
                        goal: widget.routine.goal,
                        running: widget.routine.running,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
