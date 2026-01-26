import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/view_models/destination_bucket.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/view_models/routine_state.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';
import 'package:too_many_tabs/ui/home/widgets/routine.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class RoutinesList extends StatefulWidget {
  const RoutinesList({
    super.key,
    required this.homeModel,
    required this.notesModel,
    required this.onTap,
  });

  final HomeViewmodel homeModel;
  final NotesViewmodel notesModel;
  final void Function(int) onTap;

  @override
  createState() => _RoutinesListState();
}

class _RoutinesListState extends State<RoutinesList> {
  _TappedRoutine? tappedRoutine;
  MenuItem? popup;
  late int runningIndex;

  final itemScrollController = ItemScrollController();
  final scrollOffsetController = ScrollOffsetController();
  final itemPositionListener = ItemPositionsListener.create();

  bool _isVisible(int index) {
    return itemPositionListener.itemPositions.value.any((item) {
      final leading = item.itemLeadingEdge;
      final trailing = item.itemTrailingEdge;
      if (index == item.index) {
        // debugPrint('index=${item.index} leading=$leading trailing=$trailing');
        return leading >= 0 && trailing <= 1;
      }
      return false;
    });
  }

  @override
  build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 100, top: 0),
      child: ListenableBuilder(
        listenable: widget.homeModel,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: popup != null
                    ? [1, 1, 1]
                    : [0.0, 0.9, 1.0], // Adjust stops for fade intensity
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Stack(
              children: [
                ScrollablePositionedList.builder(
                  padding: EdgeInsets.only(bottom: 50, top: 20),
                  itemCount: widget.homeModel.routines.length,
                  itemScrollController: itemScrollController,
                  scrollOffsetController: scrollOffsetController,
                  itemPositionsListener: itemPositionListener,
                  itemBuilder: (_, index) {
                    final rs = widget.homeModel.routines[index];
                    final routine = rs.$1;
                    final state = rs.$2;
                    if (routine.running) {
                      runningIndex = index;
                    }
                    return _ListItem(
                      index: index,
                      routine: routine,
                      state: state,
                      onTap: (index) {
                        setState(() {
                          if (tappedRoutine == null ||
                              (tappedRoutine != null &&
                                  tappedRoutine!.routineSummary.id !=
                                      routine.id)) {
                            tappedRoutine = _TappedRoutine(
                              routineSummary: routine,
                              index: index,
                            );
                          } else {
                            tappedRoutine = null;
                          }
                        });
                      },
                      onStartOrStop: () async {
                        await widget.homeModel.startOrStopRoutine.execute(
                          routine.id,
                        );
                        if (widget.homeModel.pinnedRoutine != null) {
                          await widget.homeModel.load.execute();
                        }
                      },
                      onMoveToBacklog: () async {
                        await widget.homeModel.archiveOrBinRoutine.execute((
                          routine.id,
                          DestinationBucket.backlog,
                        ));
                      },
                      onRedraw: (index) {
                        if (tappedRoutine != null &&
                            tappedRoutine!.index == index &&
                            !_isVisible(index)) {
                          itemScrollController.scrollTo(
                            index: index,
                            curve: Curves.linear,
                            duration: Duration(milliseconds: 200),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ListItem extends StatefulWidget {
  const _ListItem({
    required this.index,
    required this.routine,
    required this.state,
    required this.onTap,
    required this.onStartOrStop,
    required this.onMoveToBacklog,
    required this.onRedraw,
  });
  final int index;
  final RoutineSummary routine;
  final RoutineState state;
  final void Function(int) onTap;
  final void Function() onStartOrStop, onMoveToBacklog;
  final Function(int) onRedraw;

  @override
  createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRedraw(widget.index);
    });
  }

  @override
  build(BuildContext context) {
    return Column(
      key: _key,
      children: [
        Routine(
          key: ValueKey(widget.routine.id),
          routine: widget.routine,
          state: widget.state,
          onTap: () {
            widget.onTap(widget.index);
          },
          startStopSwitch: widget.onStartOrStop,
          archive: widget.onMoveToBacklog,
        ),
      ],
    );
  }
}

class _TappedRoutine {
  final RoutineSummary routineSummary;
  final int index;

  const _TappedRoutine({required this.routineSummary, required this.index});

  @override
  String toString() =>
      '_TappedRoutine(routineSummary: $routineSummary, index: $index)';
}
