import 'package:flutter/material.dart';
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
        return CustomScrollView(
          slivers: [
            SliverList.builder(
              itemCount: viewModel.routines.length,
              itemBuilder: (_, index) => Routine(
                key: ValueKey(viewModel.routines[index].id),
                routine: viewModel.routines[index],
                setGoal: () {
                  onTap(index);
                  pc.open();
                },
                startStopSwitch: () async {
                  await viewModel.startOrStopRoutine.execute(
                    viewModel.routines[index].id,
                  );
                  return viewModel.startOrStopRoutine.completed;
                },
                archive: () async {
                  await viewModel.archiveOrBinRoutine.execute((
                    viewModel.routines[index].id,
                    false, // archive (bin=false)
                  ));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
