import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/header_action.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/action_button.dart';
import 'package:too_many_tabs/ui/home/widgets/expandable_fab.dart';
import 'package:too_many_tabs/ui/home/widgets/header_eta.dart';
import 'package:too_many_tabs/ui/home/widgets/new_routine.dart';
import 'package:too_many_tabs/ui/home/widgets/routines_list.dart';
import 'package:too_many_tabs/ui/home/widgets/special_goal_action.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.homeModel,
    required this.notesModel,
    required this.settingsModel,
  });

  final HomeViewmodel homeModel;
  final NotesViewmodel notesModel;
  final SettingsViewmodel settingsModel;

  @override
  createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isSomePopupShown = false;
  bool showNewRoutinePopup = false;
  RoutineSummary? tappedRoutine;
  PanelController? pc;

  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () async {
        await widget.homeModel.load.execute();
      },
    );

    const MethodChannel(
      'com.example.tooManyTabs/settings',
    ).setMethodCallHandler((MethodCall call) async {
      debugPrint(call.method);
    });
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

    const double actionVerticalOffset = 40;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkMode
            ? colorScheme.primaryContainer
            : colorScheme.primaryFixed,
        title: Padding(
          padding: EdgeInsets.all(0),
          child: ListenableBuilder(
            listenable: widget.homeModel,
            builder: (context, _) {
              final specialSession = widget.homeModel.runningSpecialSession;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListenableBuilder(
                    listenable: widget.settingsModel.load,
                    builder: (context, child) {
                      return Loader(
                        error: widget.settingsModel.load.error,
                        running: widget.settingsModel.load.running,
                        onError: widget.settingsModel.load.execute,
                        child: child!,
                      );
                    },
                    child: ListenableBuilder(
                      listenable: widget.settingsModel,
                      builder: (context, _) {
                        return Row(
                          spacing: 6,
                          children: [
                            ..._buildAppTitle(
                              context: context,
                              session: specialSession,
                              settings:
                                  widget.settingsModel.settings.specialGoals,
                              state: widget
                                  .homeModel
                                  .specialSessionAllStatum[specialSession],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  ListenableBuilder(
                    listenable: widget.settingsModel.load,
                    builder: (context, child) {
                      final running = widget.settingsModel.load.running,
                          error = widget.settingsModel.load.error;
                      return Loader(
                        error: error,
                        running: running,
                        onError: widget.settingsModel.load.execute,
                        child: child!,
                      );
                    },
                    child: ListenableBuilder(
                      listenable: widget.settingsModel,
                      builder: (context, _) {
                        return Row(
                          children: [
                            HeaderEta(
                              routines: widget.homeModel.routines,
                              specialGoals:
                                  widget.settingsModel.settings.specialGoals,
                              specialSessionState:
                                  widget.homeModel.specialSessionStatus ??
                                  SpecialSessionDuration(
                                    current: null,
                                    duration: Duration(),
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          HeaderAction(
            icon: Icons.settings,
            onPressed: () => context.go(Routes.settings),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.homeModel.load,
              builder: (context, child) {
                final running = widget.homeModel.load.running,
                    error = widget.homeModel.load.error;
                return Loader(
                  running: running,
                  error: error,
                  onError: widget.homeModel.load.execute,
                  child: child!,
                );
              },
              child: RoutinesList(
                homeModel: widget.homeModel,
                notesModel: widget.notesModel,
                onTap: (index) {
                  setState(() {
                    tappedRoutine = widget.homeModel.routines[index];
                  });
                },
                onPopup: () {
                  return (popup) {
                    setState(() {
                      isSomePopupShown = popup;
                    });
                  };
                },
              ),
              //child: SlideUp(
              //  minHeight: slideUpPanelMinHeight,
              //  maxHeight: slideUpPanelMaxHeight,
              //  pc: (pcfn) {
              //    pc = pcfn();
              //  },
              //  notifyPanelState: (open) {
              //    setState(() {
              //      isPanelOpen = open;
              //    });
              //  },
              //  tappedRoutine: tappedRoutine,
              //  viewModel: widget.viewModel,
              //  onRoutineTapped: (index) {
              //    setState(() {
              //      tappedRoutine = widget.viewModel.routines[index];
              //    });
              //  },
              //  onPanelClosed: () {
              //    setState(() {
              //      tappedRoutine = null;
              //    });
              //  },
              //),
            ),
            showNewRoutinePopup
                ? ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.01, .7, 1],
                      colors: [Colors.black, Colors.black, Colors.transparent],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, .4],
                          colors: [
                            colorScheme.surface,
                            darkMode
                                ? colorScheme.primaryContainer
                                : colorScheme.primaryFixed,
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
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
                          for (final routine in widget.homeModel.routines) {
                            if (routine.id == id) {
                              tappedRoutine = routine;
                            }
                          }
                          showNewRoutinePopup = false;
                        });
                        pc!.open();
                      },
                      viewModel: widget.homeModel,
                    ),
                  )
                : Container(),
            isSomePopupShown || showNewRoutinePopup
                ? SizedBox.shrink()
                : ListenableBuilder(
                    listenable: widget.homeModel,
                    builder: (context, _) =>
                        _buildExpandableFab(widget.homeModel.newDay),
                  ),
            // Align(
            //     alignment: Alignment.bottomRight,
            //     child: FloatingAction(
            //       icon: Icons.add,
            //       onPressed: () => setState(() {
            //         showNewRoutinePopup = true;
            //       }),
            //       colorComposition: colorCompositionFromAction(
            //         context,
            //         ApplicationAction.addRoutine,
            //       ),
            //       verticalOffset: actionVerticalOffset,
            //     ),
            //   ),
            isSomePopupShown || showNewRoutinePopup
                ? Container()
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: FloatingAction(
                      icon: Icons.menu,
                      onPressed: () {
                        context.go(Routes.archives);
                      },
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.backlogRoutine,
                      ),
                      verticalOffset: actionVerticalOffset,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppTitle({
    required BuildContext context,
    required SpecialGoal? session,
    required SpecialGoals settings,
    required SpecialSessionDuration? state,
  }) {
    if (session == null) {
      return [
        Text(
          '${widget.homeModel.routines.length}',
          style: TextStyle(
            color: labelColor(context, Label.homeScreenNumberOfPlannedRoutines),
            fontWeight: FontWeight.w400,
            fontSize: 20,
          ),
        ),
        Text(
          'routine${widget.homeModel.routines.length <= 1 ? '' : 's'} planned today',
          style: TextStyle(
            color: labelColor(context, Label.homeScreenRoutinesPlannedToday),
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
      ];
    }

    final Duration goal;
    switch (session) {
      case SpecialGoal.startSlow:
        goal = settings.startSlow;
        break;
      case SpecialGoal.slowDown:
        goal = settings.slowDown;
        break;
      case SpecialGoal.sitBack:
        goal = settings.sitBack;
        break;
      case SpecialGoal.stoke:
        goal = settings.stoke;
        break;
    }
    final diff = goal - state!.duration;
    debugPrint('eta left $goal $state!.duration $state $diff');
    final left = diff < Duration() ? Duration() : diff;
    final eta = state.current!.add(left);

    return [
          (
            SpecialGoal.startSlow,
            'Slow start, strong finish',
            Symbols.wb_twilight_rounded,
          ),
          (
            SpecialGoal.sitBack,
            'It\'s ok to have a break',
            Symbols.beach_access_rounded,
          ),
          (SpecialGoal.stoke, 'Time to refill', Symbols.fork_spoon_rounded),
          (
            SpecialGoal.slowDown,
            'It\'s almost bed time',
            Symbols.airline_seat_flat_rounded,
          ),
        ]
        .map((item) {
          final goal = item.$1;
          final label = item.$2;
          final icon = item.$3;

          return (
            [
              Icon(
                icon,
                color: labelColor(context, Label.homeScreenSpecialGoalTitle),
              ),
              Text(
                label,
                style: TextStyle(
                  color: labelColor(context, Label.homeScreenSpecialGoalTitle),
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                ),
              ),
              Text(
                '[${DateFormat.jm().format(eta)}]',
                style: TextStyle(
                  color: labelColor(context, Label.homeScreenSpecialGoalTitle),
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                ),
              ),
            ],
            goal,
          );
        })
        .where((item) => item.$2 == session)
        .toList()[0]
        .$1;
  }

  Widget _buildExpandableFab(bool newDay) {
    debugPrint('_buildExpandableFab: $newDay');
    return ExpandableFab(
      initialOpen: false,
      distance: newDay ? 80 : 90,
      spreadAngle: newDay ? 90 : 135,
      children: [
        ...[
              ...newDay
                  ? []
                  : [
                      SpecialGoalAction(
                        goal: SpecialGoal.slowDown,
                        symbol: Symbols.bedtime,
                      ),
                      SpecialGoalAction(
                        goal: SpecialGoal.stoke,
                        symbol: Symbols.fork_spoon,
                      ),
                      SpecialGoalAction(
                        goal: SpecialGoal.sitBack,
                        symbol: Symbols.beach_access,
                      ),
                    ],
              newDay
                  ? SpecialGoalAction(
                      goal: SpecialGoal.startSlow,
                      symbol: Symbols.wb_twilight,
                    )
                  : null,
            ]
            .map(
              (action) => action != null
                  ? ActionButton(
                      onPressed: () {
                        widget.homeModel.toggleSpecialSession.execute(
                          action.goal,
                        );
                      },
                      icon: action.symbol,
                      highlight:
                          widget.homeModel.runningSpecialSession == action.goal,
                    )
                  : null,
            )
            .where((widget) => widget != null)
            .cast(),
        ActionButton(
          onPressed: () => setState(() {
            showNewRoutinePopup = true;
          }),
          icon: Symbols.add,
          secondary: newDay,
        ),
      ],
    );
  }
}
