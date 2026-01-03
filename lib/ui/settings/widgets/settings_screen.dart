import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/header_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/settings/widgets/goal_popup.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/widgets/overwrite_database_switch.dart';
import 'package:too_many_tabs/ui/settings/widgets/goal_setting.dart';
import 'package:too_many_tabs/utils/result.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.viewModel});
  final SettingsViewmodel viewModel;

  @override
  createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLifecycleListener _listener;

  Widget? popupWidget;

  Widget? _popup({
    SpecialGoal? goalSetting,
    Duration? currentGoal,
    required void Function() close,
  }) {
    if (goalSetting == null || currentGoal == null) return SizedBox.shrink();
    return GoalPopup(
      viewModel: widget.viewModel,
      goalSetting: goalSetting,
      currentGoal: currentGoal,
      onCancel: close,
      onGoalSet: close,
    );
  }

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        widget.viewModel.load.execute();
      },
    );
  }

  @override
  dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkMode
            ? colorScheme.primaryContainer
            : colorScheme.primaryFixed,
        title: Padding(
          padding: EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  color: darkMode
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onPrimaryFixed,
                ),
              ),
            ],
          ),
        ),
        actions: [
          HeaderAction(
            icon: Icons.home,
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: ListenableBuilder(
              listenable: widget.viewModel.load,
              builder: (context, child) {
                final running = widget.viewModel.load.running,
                    error = widget.viewModel.load.error;
                return Loader(
                  error: error,
                  running: running,
                  onError: widget.viewModel.load.execute,
                  child: child!,
                );
              },
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Column(
                        spacing: 20,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Overwrite Database"),
                              OverwriteDatabaseSwitch(
                                initialState:
                                    widget.viewModel.settings.overwriteDatabase,
                                onSwitch: () async {
                                  await widget.viewModel.switchOverwriteDatabase
                                      .execute();
                                  if (widget
                                      .viewModel
                                      .switchOverwriteDatabase
                                      .error) {
                                    return Result.error(
                                      Exception('unable to update state'),
                                    );
                                  }
                                  if (context.mounted &&
                                      widget
                                          .viewModel
                                          .settings
                                          .overwriteDatabase) {
                                    _backupDialog(context);
                                  }
                                  return Result.ok(null);
                                },
                              ),
                            ],
                          ),
                          ListenableBuilder(
                            listenable: widget.viewModel,
                            builder: (context, _) {
                              return GoalSetting(
                                label: 'Sit back goal',
                                goal: widget
                                    .viewModel
                                    .settings
                                    .specialGoals
                                    .sitBack,
                                onTap: () {
                                  setState(() {
                                    popupWidget = _popup(
                                      close: () {
                                        setState(() {
                                          popupWidget = null;
                                        });
                                      },
                                      goalSetting: SpecialGoal.sitBack,
                                      currentGoal: widget
                                          .viewModel
                                          .settings
                                          .specialGoals
                                          .sitBack,
                                    );
                                  });
                                },
                              );
                            },
                          ),
                          GoalSetting(
                            label: 'Start slow goal',
                            goal: widget
                                .viewModel
                                .settings
                                .specialGoals
                                .startSlow,
                            onTap: () {
                              setState(() {
                                popupWidget = _popup(
                                  close: () {
                                    setState(() {
                                      popupWidget = null;
                                    });
                                  },
                                  goalSetting: SpecialGoal.startSlow,
                                  currentGoal: widget
                                      .viewModel
                                      .settings
                                      .specialGoals
                                      .startSlow,
                                );
                              });
                            },
                          ),
                          GoalSetting(
                            label: 'Slow down goal',
                            goal:
                                widget.viewModel.settings.specialGoals.slowDown,
                            onTap: () {
                              setState(() {
                                popupWidget = _popup(
                                  close: () {
                                    setState(() {
                                      popupWidget = null;
                                    });
                                  },
                                  goalSetting: SpecialGoal.slowDown,
                                  currentGoal: widget
                                      .viewModel
                                      .settings
                                      .specialGoals
                                      .slowDown,
                                );
                              });
                            },
                          ),
                          GoalSetting(
                            label: 'Stoke goal',
                            goal: widget.viewModel.settings.specialGoals.stoke,
                            onTap: () {
                              setState(() {
                                popupWidget = _popup(
                                  close: () {
                                    setState(() {
                                      popupWidget = null;
                                    });
                                  },
                                  goalSetting: SpecialGoal.stoke,
                                  currentGoal: widget
                                      .viewModel
                                      .settings
                                      .specialGoals
                                      .stoke,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorCompositionFromAction(
                                    context,
                                    ApplicationAction.downloadBackup,
                                  ).background,
                                  foregroundColor: colorCompositionFromAction(
                                    context,
                                    ApplicationAction.downloadBackup,
                                  ).foreground,
                                ),
                                onPressed: _shareBackup,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    spacing: 10,
                                    children: [
                                      Icon(Icons.download, size: 23),
                                      const Text('Backup state.db'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          popupWidget ?? SizedBox.shrink(),
        ],
      ),
    );
  }
}

void _shareBackup() async {
  final path = await getDatabasesPath();
  await SharePlus.instance.share(
    ShareParams(files: [XFile(join(path, "state.db"))], title: 'Save state.db'),
  );
}

void _backupDialog(BuildContext context) {
  final backupComp = colorCompositionFromAction(
    context,
    ApplicationAction.downloadBackup,
  );
  showDialog(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final screeWidth = MediaQuery.of(context).size.width;
      return Center(
        child: Container(
          padding: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: List<BoxShadow>.generate(4, (index) {
              var i = 1, j = 1;
              if (index == 1) i = -1;
              if (index == 2) j = -1;
              if (index == 3) {
                i = -1;
                j = -1;
              }
              final double offset = .5;
              return BoxShadow(
                color: colorScheme.surfaceDim,
                offset: Offset(i * offset, j * offset),
                blurRadius: 4,
              );
            }),
            color: colorScheme.surface,
          ),
          width: screeWidth * .8,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 20,
                    children: [
                      Icon(size: 40, Icons.warning),
                      Flexible(child: const Text(_warning1)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(_warning2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Backed up'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        _shareBackup();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: backupComp.foreground,
                        backgroundColor: backupComp.background,
                      ),
                      child: const Text('Backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

const _warning1 =
    'With this setting, the database will be reset from assets then next time app restart.';
const _warning2 =
    'Make sure you saved a backup of state.db before you restart the application. The option will be set back to false after restart.';
