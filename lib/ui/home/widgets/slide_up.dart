import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/routines_list.dart';
import 'package:too_many_tabs/ui/home/widgets/slideup_panel.dart';

class SlideUp extends StatefulWidget {
  const SlideUp({
    super.key,
    required this.viewModel,
    required this.onRoutineTapped,
    required this.onPanelClosed,
    required this.tappedRoutine,
    required this.notifyPanelState,
    required this.pc,
  });

  final HomeViewmodel viewModel;
  final void Function(int) onRoutineTapped;
  final void Function() onPanelClosed;
  final RoutineSummary? tappedRoutine;
  final void Function(bool) notifyPanelState;
  final Function(PanelController Function()) pc;

  @override
  createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> {
  bool isPanelOpened = false;
  bool isPanelOpen = false;

  final pc = PanelController();

  @override
  build(BuildContext context) {
    widget.pc(() {
      return pc;
    });

    final dimens = Dimens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return SlidingUpPanel(
      controller: pc,
      borderRadius: BorderRadius.vertical(top: Radius.elliptical(30, 20)),
      padding: EdgeInsets.only(
        top: isPanelOpened ? dimens.paddingScreenVertical : 16,
      ),
      //   left: dimens.paddingScreenHorizontal,
      //   right: dimens.paddingScreenHorizontal,
      backdropEnabled: true,
      backdropTapClosesPanel: true,
      backdropOpacity: darkMode ? .1 : .7,
      backdropColor: colorScheme.primaryFixed,
      color: darkMode
          ? (isPanelOpen ? colorScheme.primary : colorScheme.primaryContainer)
          : colorScheme.surfaceBright,
      onPanelSlide: (pos) {
        setState(() {
          if (pos > 0 && !isPanelOpened) isPanelOpen = true;
          if (pos < .01 && isPanelOpened) isPanelOpen = false;
        });
        widget.notifyPanelState(isPanelOpen);
      },
      onPanelOpened: () {
        setState(() {
          isPanelOpened = true;
        });
      },
      onPanelClosed: () {
        widget.onPanelClosed();
        setState(() {
          isPanelOpened = false;
        });
      },
      isDraggable: !(isPanelOpened && widget.tappedRoutine != null),
      maxHeight: 340,
      collapsed: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final running = widget.viewModel.pinnedRoutine;
          if (running != null) {
            final eta = running.lastStarted!.add(running.goal - running.spent);
            return Collapsed(runningRoutine: running, eta: eta);
          }
          return Collapsed();
        },
      ),
      panel: SlideUpPanel(
        viewModel: widget.viewModel,
        isOpen: isPanelOpened,
        pc: pc,
        tappedRoutine: widget.tappedRoutine,
      ),
      body: RoutinesList(
        viewModel: widget.viewModel,
        onTap: widget.onRoutineTapped,
        pc: pc,
      ),
    );
  }
}
