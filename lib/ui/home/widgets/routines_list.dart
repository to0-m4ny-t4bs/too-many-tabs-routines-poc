import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/view_models/destination_bucket.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_item.dart';
import 'package:too_many_tabs/ui/home/widgets/menu_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/routine.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_menu.dart';

class RoutinesList extends StatefulWidget {
  const RoutinesList({super.key, required this.viewModel, required this.onTap});

  final HomeViewmodel viewModel;
  final void Function(int) onTap;

  @override
  createState() => _RoutinesListState();
}

class _RoutinesListState extends State<RoutinesList> {
  RoutineSummary? tappedRoutine;
  MenuItem? popup;
  late int runningIndex;

  final itemScrollController = ItemScrollController();
  final scrollOffsetController = ScrollOffsetController();

  @override
  build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 100, top: 0),
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.9, 1.0], // Adjust stops for fade intensity
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Stack(
              children: [
                ScrollablePositionedList.builder(
                  padding: EdgeInsets.only(bottom: 50),
                  itemCount: widget.viewModel.routines.length,
                  itemScrollController: itemScrollController,
                  scrollOffsetController: scrollOffsetController,
                  itemBuilder: (_, index) {
                    final routineId = widget.viewModel.routines[index].id;
                    final routine = widget.viewModel.routines[index];
                    if (routine.running) {
                      runningIndex = index;
                    }
                    return Column(
                      children: [
                        Routine(
                          key: ValueKey(routineId),
                          routine: routine,
                          onTap: () {
                            widget.onTap(index);
                            setState(() {
                              if (tappedRoutine == null ||
                                  (tappedRoutine != null &&
                                      tappedRoutine!.id != routineId)) {
                                tappedRoutine =
                                    widget.viewModel.routines[index];
                              } else {
                                tappedRoutine = null;
                              }
                            });
                          },
                          startStopSwitch: () async {
                            await widget.viewModel.startOrStopRoutine.execute(
                              routineId,
                            );
                            return widget
                                .viewModel
                                .startOrStopRoutine
                                .completed;
                          },
                          archive: () async {
                            await widget.viewModel.archiveOrBinRoutine.execute((
                              routineId,
                              DestinationBucket.backlog,
                            ));
                          },
                        ),
                        tappedRoutine != null &&
                                tappedRoutine!.id == routineId &&
                                popup == null
                            ? RoutineMenu(
                                onClose: () {
                                  setState(() {
                                    popup = null;
                                  });
                                },
                                popup: (item) {
                                  setState(() {
                                    popup = item;
                                  });
                                },
                                routine: tappedRoutine!,
                              )
                            : SizedBox.shrink(),
                      ],
                    );
                  },
                ),
                MenuPopup(
                  routine: tappedRoutine,
                  viewModel: widget.viewModel,
                  menu: popup,
                  close: () {
                    setState(() {
                      popup = null;
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
