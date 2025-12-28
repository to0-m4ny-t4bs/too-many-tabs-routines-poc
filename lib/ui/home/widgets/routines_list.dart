import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/routine.dart';

class RoutinesList extends StatefulWidget {
  const RoutinesList({
    super.key,
    required this.viewModel,
    required this.onTap,
    required this.pc,
  });

  final HomeViewmodel viewModel;
  final void Function(int) onTap;
  final PanelController pc;

  @override
  createState() => _RoutinesListState();
}

class _RoutinesListState extends State<RoutinesList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 150, top: 10),
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return FadingEdgeScrollView.fromScrollView(
            gradientFractionOnEnd: 0.8,
            gradientFractionOnStart: 0,
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                SliverSafeArea(
                  minimum: EdgeInsets.only(bottom: 180),
                  sliver: SliverList.builder(
                    itemCount: widget.viewModel.routines.length,
                    itemBuilder: (_, index) => Routine(
                      key: ValueKey(widget.viewModel.routines[index].id),
                      routine: widget.viewModel.routines[index],
                      setGoal: () {
                        widget.onTap(index);
                        widget.pc.open();
                      },
                      startStopSwitch: () async {
                        await widget.viewModel.startOrStopRoutine.execute(
                          widget.viewModel.routines[index].id,
                        );
                        return widget.viewModel.startOrStopRoutine.completed;
                      },
                      archive: () async {
                        await widget.viewModel.archiveOrBinRoutine.execute((
                          widget.viewModel.routines[index].id,
                          false, // archive (bin=false)
                        ));
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
