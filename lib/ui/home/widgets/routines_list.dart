import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/routine.dart';

class RoutinesList extends StatelessWidget {
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
  build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final routinesControllers = List<_ControlledRoutine?>.filled(
          viewModel.routines.length,
          null,
        );
        return CustomScrollView(
          slivers: [
            SliverList.builder(
              itemCount: viewModel.routines.length,
              itemBuilder: (_, index) {
                routinesControllers[index] = _ControlledRoutine(
                  routine: Routine(
                    key: ValueKey(viewModel.routines[index].id),
                    routine: viewModel.routines[index],
                    closeAll: (sc) {
                      routinesControllers[index]!.newController = sc();
                      debugPrint('closeAll...');
                      for (final rc in routinesControllers) {
                        if (rc != null) {
                          debugPrint(
                            'closeAll: routine controller ${rc.routine}',
                          );
                          if (rc.controller != null) {
                            rc.controller!.close();
                          }
                        }
                      }
                    },
                    onTap: () {
                      onTap(index);
                      pc.open();
                    },
                    onSwitch: (_) async {
                      await viewModel.startOrStopRoutine.execute(
                        viewModel.routines[index].id,
                      );
                      return viewModel.startOrStopRoutine.completed;
                    },
                    archive: (_) async {
                      await viewModel.archiveOrBinRoutine.execute((
                        viewModel.routines[index].id,
                        false, // archive (bin=false)
                      ));
                    },
                    bin: (_) async {
                      await viewModel.archiveOrBinRoutine.execute((
                        viewModel.routines[index].id,
                        true, // set bin=true
                      ));
                    },
                  ),
                );
                return routinesControllers[index]!.routine;
              },
            ),
          ],
        );
      },
    );
  }
}

class _ControlledRoutine {
  _ControlledRoutine({required this.routine});
  final Routine routine;
  late SlidableController? _controller;

  set newController(SlidableController controller) {
    _controller = controller;
  }

  SlidableController? get controller => _controller;
}
