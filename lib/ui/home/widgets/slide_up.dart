import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/themes/dimens.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/routines_list.dart';
import 'package:too_many_tabs/ui/home/widgets/slideup_panel.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class SlideUp extends StatefulWidget {
  const SlideUp({
    super.key,
    required this.viewModel,
    required this.notesModel,
    required this.onRoutineTapped,
    required this.onPanelClosed,
    required this.tappedRoutine,
    required this.notifyPanelState,
    required this.pc,
    required this.minHeight,
    required this.maxHeight,
  });

  final HomeViewmodel viewModel;
  final NotesViewmodel notesModel;
  final void Function(int) onRoutineTapped;
  final void Function() onPanelClosed;
  final RoutineSummary? tappedRoutine;
  final void Function(bool) notifyPanelState;
  final Function(PanelController Function()) pc;
  final double minHeight, maxHeight;

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
      maxHeight: widget.maxHeight,
      minHeight: widget.minHeight,
      collapsed: Collapsed(viewModel: widget.viewModel),
      panel: SlideUpPanel(
        viewModel: widget.viewModel,
        isOpen: isPanelOpened,
        pc: pc,
        tappedRoutine: widget.tappedRoutine,
      ),
      body: RoutinesList(
        onPopup: () {
          return (_) {};
        },
        notesModel: widget.notesModel,
        homeModel: widget.viewModel,
        onTap: widget.onRoutineTapped,
      ),
    );
  }
}
