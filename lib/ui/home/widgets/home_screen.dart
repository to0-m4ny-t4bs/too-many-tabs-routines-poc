import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/notifications.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/header_action.dart';
import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/header_routines_dynamic_goal_label.dart';
import 'package:too_many_tabs/ui/home/widgets/new_routine.dart';
import 'package:too_many_tabs/ui/home/widgets/slide_up.dart';

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
    _requestPermissions();
    _configureSelectNotificationSubject();

    const MethodChannel(
      'com.example.tooManyTabs/settings',
    ).setMethodCallHandler((MethodCall call) async {
      debugPrint(call.method);
    });
  }

  Future<void> isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
      debugPrint('isAndroidPermissionGranted: $granted');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final grantedNotificationsPermission = await androidImplementation
          ?.requestNotificationsPermission();
      debugPrint(
        'android: grantedNotificationsPermission: $grantedNotificationsPermission',
      );
      final grantedExactAlarmsPermission = await androidImplementation
          ?.requestExactAlarmsPermission();
      debugPrint(
        'android: grantedExactAlarmsPermission: $grantedExactAlarmsPermission',
      );
    }
  }

  void _configureSelectNotificationSubject() {
    selectNotificationStream.stream.listen((
      NotificationResponse? response,
    ) async {
      debugPrint(
        'notification response payload ${response?.payload} data ${response?.data}',
      );
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

    const verticalOffset = 110.0;
    const slideUpPanelMinHeight = 100.0;
    const slideUpPanelMaxHeight = 340.0;

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
                minHeight: slideUpPanelMinHeight,
                maxHeight: slideUpPanelMaxHeight,
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
            isPanelOpen || showNewRoutinePopup
                ? Container()
                : Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingAction(
                      icon: Icons.add,
                      onPressed: () => setState(() {
                        showNewRoutinePopup = true;
                      }),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.addRoutine,
                      ),
                      verticalOffset: verticalOffset,
                    ),
                  ),
            isPanelOpen || showNewRoutinePopup
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
                      verticalOffset: verticalOffset,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
