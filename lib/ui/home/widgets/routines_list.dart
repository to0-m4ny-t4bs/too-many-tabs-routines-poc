import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/view_models/destination_bucket.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/routine.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_menu.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class RoutinesList extends StatefulWidget {
  const RoutinesList({
    super.key,
    required this.homeModel,
    required this.notesModel,
    required this.onTap,
    required this.onPopup,
  });

  final HomeViewmodel homeModel;
  final NotesViewmodel notesModel;
  final void Function(int) onTap;
  final Function(bool) Function() onPopup;

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
                    final routine = widget.homeModel.routines[index];
                    if (routine.running) {
                      runningIndex = index;
                    }
                    return _ListItem(
                      index: index,
                      routine: routine,
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
                      },
                      onMoveToBacklog: () async {
                        await widget.homeModel.archiveOrBinRoutine.execute((
                          routine.id,
                          DestinationBucket.backlog,
                        ));
                      },
                      menu: () {
                        if (tappedRoutine != null &&
                            tappedRoutine!.routineSummary.id == routine.id &&
                            popup == null) {
                          return RoutineMenu(
                            homeViewmodel: widget.homeModel,
                            close: (scrollTo) {
                              widget.onPopup()(false);
                              setState(() {
                                popup = null;
                                tappedRoutine = null;
                              });
                              itemScrollController.scrollTo(
                                index: scrollTo,
                                duration: Duration(milliseconds: 250),
                              );
                            },
                            popup: (item) {
                              widget.onPopup()(true);
                              setState(() {
                                popup = item;
                              });
                            },
                            routine: tappedRoutine!.routineSummary,
                          );
                        }
                        return SizedBox.shrink();
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
                MenuPopup(
                  routine: tappedRoutine?.routineSummary,
                  homeModel: widget.homeModel,
                  notesModel: widget.notesModel,
                  menu: popup,
                  close: () {
                    widget.onPopup()(false);
                    setState(() {
                      popup = null;
                      tappedRoutine = null;
                    });
                  },
                ),
                // Align(
                //   alignment: Alignment.topCenter,
                //   child: ElevatedButton.icon(
                //     onPressed: () {
                //       itemScrollController.jumpTo(index: runningIndex);
                //     },
                //     icon: Icon(Icons.refresh),
                //     label: const Text('Running'),
                //   ),
                // ),
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
    required this.onTap,
    required this.onStartOrStop,
    required this.onMoveToBacklog,
    required this.onRedraw,
    required this.menu,
  });
  final int index;
  final RoutineSummary routine;
  final void Function(int) onTap;
  final void Function() onStartOrStop, onMoveToBacklog;
  final Widget Function() menu;
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
          onTap: () {
            widget.onTap(widget.index);
          },
          startStopSwitch: widget.onStartOrStop,
          archive: widget.onMoveToBacklog,
        ),
        widget.menu(),
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
