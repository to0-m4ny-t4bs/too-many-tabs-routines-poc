import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/header_routines_dynamic_goal_label.dart';
import 'package:too_many_tabs/ui/home/widgets/slide_up.dart';
import 'package:too_many_tabs/ui/home/widgets/new_routine.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewmodel viewModel;

  @override
  createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isPanelOpen = false;
  bool showNewRoutinePopup = false;
  RoutineSummary? tappedRoutine;
  PanelController? pc;

  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () async {
        await widget.viewModel.load.execute();
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkMode
            ? colorScheme.primaryContainer
            : colorScheme.primaryFixed,
        title: Padding(
          padding: EdgeInsets.only(left: 5),
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Text(
                        'You\'ve',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: darkMode
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onPrimaryFixed,
                        ),
                      ),
                      Text(
                        '${widget.viewModel.routines.length}',
                        style: TextStyle(
                          color: darkMode
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onPrimaryFixed,
                          fontWeight: FontWeight.w400,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'routine${widget.viewModel.routines.length <= 1 ? '' : 's'} planned today.',
                        style: TextStyle(
                          color: darkMode
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onPrimaryFixed,
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  HeaderRoutinesDynamicGoalLabel(
                    routines: widget.viewModel.routines,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.go(Routes.archives);
            },
            icon: Icon(Icons.archive),
            color: darkMode
                ? colorScheme.onPrimaryContainer
                : colorScheme.primary,
          ),
          IconButton(
            onPressed: () async {
              final path = await getDatabasesPath();
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(join(path, "state.db"))],
                  title: 'Save state.db',
                ),
              );
            },
            icon: Icon(Icons.download),
            color: darkMode
                ? colorScheme.onPrimaryContainer
                : colorScheme.primary,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel.load,
              builder: (context, child) {
                final running = widget.viewModel.load.running,
                    error = widget.viewModel.load.error;
                return Loader(
                  running: running,
                  error: error,
                  onError: widget.viewModel.load.execute,
                  child: child!,
                );
              },
              child: SlideUp(
                pc: (pcfn) {
                  pc = pcfn();
                },
                notifyPanelState: (open) {
                  setState(() {
                    isPanelOpen = open;
                  });
                },
                tappedRoutine: tappedRoutine,
                viewModel: widget.viewModel,
                onRoutineTapped: (index) {
                  setState(() {
                    tappedRoutine = widget.viewModel.routines[index];
                  });
                },
                onPanelClosed: () {
                  setState(() {
                    tappedRoutine = null;
                  });
                },
              ),
            ),
            showNewRoutinePopup
                ? Center(
                    child: NewRoutine(
                      closeCancel: () {
                        setState(() {
                          showNewRoutinePopup = false;
                        });
                      },
                      closeCompleted: (id) {
                        setState(() {
                          for (final routine in widget.viewModel.routines) {
                            if (routine.id == id) {
                              tappedRoutine = routine;
                            }
                          }
                          showNewRoutinePopup = false;
                        });
                        pc!.open();
                      },
                      viewModel: widget.viewModel,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      floatingActionButton: isPanelOpen || showNewRoutinePopup
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                backgroundColor: darkMode
                    ? colorScheme.primaryContainer
                    : colorScheme.primary,
                foregroundColor: darkMode
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onPrimary,
                shape: CircleBorder(),
                child: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    showNewRoutinePopup = true;
                  });
                },
              ),
            ),
    );
  }
}
