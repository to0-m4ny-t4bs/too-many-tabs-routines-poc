**Input:**

**Scope:** *None*

**Git Log:** *None*

**Diff:**
```diff
diff --git a/lib/config/dependencies.dart b/lib/config/dependencies.dart
index b12b3d3..fe34a33 100644
--- a/lib/config/dependencies.dart
+++ b/lib/config/dependencies.dart
@@ -4,6 +4,8 @@ import 'package:provider/single_child_widget.dart';
 import 'package:sqflite/sqlite_api.dart';
 import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
 import 'package:too_many_tabs/data/repositories/routines/routines_repository_local.dart';
+import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
+import 'package:too_many_tabs/data/repositories/settings/settings_repository_sqlite.dart';
 import 'package:too_many_tabs/data/services/database/database_client.dart';
 
 List<SingleChildWidget> providerLocal({
@@ -13,6 +15,10 @@ List<SingleChildWidget> providerLocal({
   return [
     Provider(create: (context) => notificationsPlugin),
     Provider(create: (context) => DatabaseClient(db: db)),
+    Provider(
+      create: (context) =>
+          SettingsRepositorySqlite(db: context.read()) as SettingsRepository,
+    ),
     Provider(
       create: (context) =>
           RoutinesRepositoryLocal(databaseClient: context.read())
diff --git a/lib/data/services/database/database_prepare.dart b/lib/data/services/database/database_prepare.dart
index c593d71..ddb9468 100644
--- a/lib/data/services/database/database_prepare.dart
+++ b/lib/data/services/database/database_prepare.dart
@@ -4,6 +4,8 @@ import 'package:flutter/services.dart';
 import 'package:logging/logging.dart';
 import 'package:path/path.dart';
 import 'package:sqflite/sqflite.dart';
+import 'package:too_many_tabs/data/services/database/database_client.dart';
+import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
 import 'package:too_many_tabs/utils/result.dart';
 
 Future<Result<Database>> prepareDatabase() async {
@@ -11,15 +13,34 @@ Future<Result<Database>> prepareDatabase() async {
   final path = join(databasePath, 'state.db');
   final log = Logger('prepareDatabase');
 
-  // try {
-  //   await deleteDatabase(path);
-  //   log.warning('[DEV] deleted database');
-  // } on Exception catch (e) {
-  //   Result.error(e);
-  // }
-
   final exists = await databaseExists(path);
-  if (!exists) {
+  log.fine('database ${exists ? "" : "does not"} exist${exists ? "s" : ""}');
+  var reset = false;
+  if (exists) {
+    log.fine('Opening existing database');
+    final client = DatabaseClient(db: await openDatabase(path));
+    final resultSettings = await client.getSettings();
+    switch (resultSettings) {
+      case Error<SettingsSummary>():
+        log.severe('unable to load settings');
+        return Result.error(
+          Exception('unable to get settings: ${resultSettings.error}'),
+        );
+      case Ok<SettingsSummary>():
+        log.fine("loaded settings: ${resultSettings.value}");
+        if (resultSettings.value.overwriteDatabase) {
+          try {
+            log.warning('overwriting database as in settings');
+            await deleteDatabase(path);
+            log.warning('[DEV] deleted database');
+          } on Exception catch (e) {
+            return Result.error(e);
+          }
+          reset = true;
+        }
+    }
+  }
+  if (reset || !exists) {
     log.info('Creating new copy of state.db from asset');
 
     try {
@@ -36,8 +57,6 @@ Future<Result<Database>> prepareDatabase() async {
     );
 
     await File(path).writeAsBytes(bytes, flush: true);
-  } else {
-    log.fine('Opening existing database');
   }
 
   return Result.ok(await openDatabase(path));
diff --git a/lib/domain/models/settings/settings_summary.dart b/lib/domain/models/settings/settings_summary.dart
index 6a858db..5888fd8 100644
--- a/lib/domain/models/settings/settings_summary.dart
+++ b/lib/domain/models/settings/settings_summary.dart
@@ -3,4 +3,9 @@ class SettingsSummary {
     : _overwriteDatabase = overwriteDatabase;
   final bool _overwriteDatabase;
   bool get overwriteDatabase => _overwriteDatabase;
+  @override
+  toString() {
+    final settings = ['overwriteDatabase: $overwriteDatabase'].join(", ");
+    return '{$settings}';
+  }
 }
diff --git a/lib/main.dart b/lib/main.dart
index 84f3dbe..916d6c3 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -18,6 +18,18 @@ import 'package:timezone/data/latest_all.dart' as tz;
 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
 
+  Logger.root.level = Level.ALL;
+  Logger.root.onRecord.listen((record) async {
+    debugPrint(
+      [
+        'level=${record.level}',
+        'time=${record.time}',
+        'logger=${record.loggerName}',
+        'msg=${record.message}',
+      ].join(' '),
+    );
+  });
+
   final resultDatabase = await prepareDatabase();
   final Database db;
   switch (resultDatabase) {
@@ -29,14 +41,6 @@ void main() async {
 
   Logger.root.level = Level.ALL;
   Logger.root.onRecord.listen((record) async {
-    debugPrint(
-      [
-        'level=${record.level}',
-        'time=${record.time}',
-        'logger=${record.loggerName}',
-        'msg=${record.message}',
-      ].join(' '),
-    );
     final client = DatabaseClient(db: db);
     if (record.level >= Level.INFO) {
       client.log(
diff --git a/lib/routing/router.dart b/lib/routing/router.dart
index a9d23d6..218f1b6 100644
--- a/lib/routing/router.dart
+++ b/lib/routing/router.dart
@@ -7,6 +7,8 @@ import 'package:too_many_tabs/ui/bin/view_models/bin_viewmodel.dart';
 import 'package:too_many_tabs/ui/bin/widgets/bin_screen.dart';
 import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
 import 'package:too_many_tabs/ui/home/widgets/home_screen.dart';
+import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
+import 'package:too_many_tabs/ui/settings/widgets/settings_screen.dart';
 
 GoRouter router() => GoRouter(
   restorationScopeId: 'router',
@@ -40,8 +42,8 @@ GoRouter router() => GoRouter(
     GoRoute(
       path: Routes.settings,
       builder: (context, state) {
-        final viewModel = SettingsViewModel(settingsRepository: context.read());
-        return BinScreen(viewModel: viewModel);
+        final viewModel = SettingsViewmodel(repository: context.read());
+        return SettingsScreen(viewModel: viewModel);
       },
     ),
   ],
diff --git a/lib/ui/core/ui/routine_action.dart b/lib/ui/core/ui/routine_action.dart
index 2539bcd..1462704 100644
--- a/lib/ui/core/ui/routine_action.dart
+++ b/lib/ui/core/ui/routine_action.dart
@@ -49,6 +49,7 @@ ColorComposition colorCompositionFromAction(
       foreground = colorScheme.primary;
       background = colorScheme.surface;
       break;
+    case ApplicationAction.downloadBackup:
     case ApplicationAction.addRoutine:
       background = darkMode
           ? colorScheme.primaryContainer
@@ -102,7 +103,8 @@ enum ApplicationAction {
   addRoutine(6),
   toHome(7),
   toBacklog(8),
-  toArchive(9);
+  toArchive(9),
+  downloadBackup(10);
 
   const ApplicationAction(this.code);
 
diff --git a/lib/ui/home/widgets/home_screen.dart b/lib/ui/home/widgets/home_screen.dart
index 7336004..3beaedc 100644
--- a/lib/ui/home/widgets/home_screen.dart
+++ b/lib/ui/home/widgets/home_screen.dart
@@ -2,10 +2,7 @@ import 'package:flutter/services.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_local_notifications/flutter_local_notifications.dart';
 import 'package:go_router/go_router.dart';
-import 'package:path/path.dart';
-import 'package:share_plus/share_plus.dart';
 import 'package:sliding_up_panel/sliding_up_panel.dart';
-import 'package:sqflite/sqflite.dart';
 import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
 import 'package:too_many_tabs/notifications.dart';
 import 'package:too_many_tabs/routing/routes.dart';
@@ -145,16 +142,8 @@ class HomeScreenState extends State<HomeScreen> {
         ),
         actions: [
           HeaderAction(
-            onPressed: () async {
-              final path = await getDatabasesPath();
-              await SharePlus.instance.share(
-                ShareParams(
-                  files: [XFile(join(path, "state.db"))],
-                  title: 'Save state.db',
-                ),
-              );
-            },
-            icon: Icons.download,
+            icon: Icons.settings,
+            onPressed: () => context.go(Routes.settings),
           ),
         ],
       ),
diff --git a/lib/ui/home/widgets/new_routine.dart b/lib/ui/home/widgets/new_routine.dart
index 4e4ee24..f4a6bf7 100644
--- a/lib/ui/home/widgets/new_routine.dart
+++ b/lib/ui/home/widgets/new_routine.dart
@@ -1,4 +1,5 @@
 import 'package:flutter/material.dart';
+import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
 import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
 
 class NewRoutine extends StatefulWidget {
@@ -28,6 +29,10 @@ class _NewRoutineState extends State<NewRoutine> {
 
   @override
   build(BuildContext context) {
+    final addComp = colorCompositionFromAction(
+      context,
+      ApplicationAction.addRoutine,
+    );
     final colorScheme = Theme.of(context).colorScheme;
 
     return Container(
@@ -90,8 +95,8 @@ class _NewRoutineState extends State<NewRoutine> {
                   }
                 },
                 style: ElevatedButton.styleFrom(
-                  backgroundColor: colorScheme.primary,
-                  foregroundColor: colorScheme.onPrimary,
+                  backgroundColor: addComp.background,
+                  foregroundColor: addComp.foreground,
                 ),
                 child: const Text('Add routine'),
               ),
diff --git a/lib/ui/settings/view_models/settings_viewmodel.dart b/lib/ui/settings/view_models/settings_viewmodel.dart
index d29fa94..ee80d30 100644
--- a/lib/ui/settings/view_models/settings_viewmodel.dart
+++ b/lib/ui/settings/view_models/settings_viewmodel.dart
@@ -28,9 +28,7 @@ class SettingsViewmodel extends ChangeNotifier {
           return Result.error(resultGet.error);
         case Ok<SettingsSummary>():
           _settings = resultGet.value;
-          _log.fine(
-            'loaded settings (overwrite = ${settings.overwriteDatabase}',
-          );
+          _log.fine('loaded settings $settings');
       }
       return Result.ok(null);
     } finally {
diff --git a/lib/ui/settings/widgets/overwrite_database_switch.dart b/lib/ui/settings/widgets/overwrite_database_switch.dart
new file mode 100644
index 0000000..6501c03
--- /dev/null
+++ b/lib/ui/settings/widgets/overwrite_database_switch.dart
@@ -0,0 +1,45 @@
+import 'package:flutter/material.dart';
+import 'package:logging/logging.dart';
+import 'package:too_many_tabs/utils/result.dart';
+
+class OverwriteDatabaseSwitch extends StatefulWidget {
+  const OverwriteDatabaseSwitch({
+    super.key,
+    required this.onSwitch,
+    required this.initialState,
+  });
+  final Future<Result<void>> Function() onSwitch;
+  final bool initialState;
+  @override
+  createState() => _OverwriteDatabaseSwitchState();
+}
+
+class _OverwriteDatabaseSwitchState extends State<OverwriteDatabaseSwitch> {
+  late bool _state;
+  final _log = Logger("_OverwriteDatabaseSwitchState");
+
+  @override
+  initState() {
+    super.initState();
+    _state = widget.initialState;
+  }
+
+  @override
+  build(BuildContext context) {
+    return Switch(
+      value: _state,
+      onChanged: (bool value) async {
+        final resultSwitch = await widget.onSwitch();
+        switch (resultSwitch) {
+          case Error<void>():
+            _log.warning('onSwitch callback: ${resultSwitch.error}');
+            return;
+          case Ok<void>():
+        }
+        setState(() {
+          _state = value;
+        });
+      },
+    );
+  }
+}
diff --git a/lib/ui/settings/widgets/settings_screen.dart b/lib/ui/settings/widgets/settings_screen.dart
new file mode 100644
index 0000000..d411c82
--- /dev/null
+++ b/lib/ui/settings/widgets/settings_screen.dart
@@ -0,0 +1,263 @@
+import 'package:flutter/material.dart';
+import 'package:go_router/go_router.dart';
+import 'package:path/path.dart';
+import 'package:share_plus/share_plus.dart';
+import 'package:sqflite/sqflite.dart';
+import 'package:too_many_tabs/routing/routes.dart';
+import 'package:too_many_tabs/ui/core/loader.dart';
+import 'package:too_many_tabs/ui/core/ui/header_action.dart';
+import 'package:too_many_tabs/ui/core/ui/routine_action.dart';
+import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
+import 'package:too_many_tabs/ui/settings/widgets/overwrite_database_switch.dart';
+import 'package:too_many_tabs/utils/result.dart';
+
+class SettingsScreen extends StatefulWidget {
+  const SettingsScreen({super.key, required this.viewModel});
+  final SettingsViewmodel viewModel;
+
+  @override
+  createState() => _SettingsScreenState();
+}
+
+class _SettingsScreenState extends State<SettingsScreen> {
+  late AppLifecycleListener _listener;
+
+  @override
+  initState() {
+    super.initState();
+    _listener = AppLifecycleListener(
+      onResume: () {
+        widget.viewModel.load.execute();
+      },
+    );
+  }
+
+  @override
+  dispose() {
+    _listener.dispose();
+    super.dispose();
+  }
+
+  @override
+  build(BuildContext context) {
+    final colorScheme = Theme.of(context).colorScheme;
+    final darkMode = Theme.of(context).brightness == Brightness.dark;
+    return Scaffold(
+      appBar: AppBar(
+        backgroundColor: darkMode
+            ? colorScheme.primaryContainer
+            : colorScheme.primaryFixed,
+        title: Padding(
+          padding: EdgeInsets.only(left: 5),
+          child: Row(
+            children: [
+              Text(
+                'Settings',
+                style: TextStyle(
+                  fontWeight: FontWeight.w300,
+                  fontSize: 18,
+                  color: darkMode
+                      ? colorScheme.onPrimaryContainer
+                      : colorScheme.onPrimaryFixed,
+                ),
+              ),
+            ],
+          ),
+        ),
+        actions: [
+          HeaderAction(
+            icon: Icons.home,
+            onPressed: () => context.go(Routes.home),
+          ),
+        ],
+      ),
+      body: Padding(
+        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
+        child: ListenableBuilder(
+          listenable: widget.viewModel.load,
+          builder: (context, child) {
+            final running = widget.viewModel.load.running,
+                error = widget.viewModel.load.error;
+            return Loader(
+              error: error,
+              running: running,
+              onError: widget.viewModel.load.execute,
+              child: child!,
+            );
+          },
+          child: ListenableBuilder(
+            listenable: widget.viewModel,
+            builder: (context, _) {
+              return Stack(
+                children: [
+                  Column(
+                    children: [
+                      Row(
+                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
+                        children: [
+                          const Text("Overwrite Database"),
+                          OverwriteDatabaseSwitch(
+                            initialState:
+                                widget.viewModel.settings.overwriteDatabase,
+                            onSwitch: () async {
+                              await widget.viewModel.switchOverwriteDatabase
+                                  .execute();
+                              if (widget
+                                  .viewModel
+                                  .switchOverwriteDatabase
+                                  .error) {
+                                return Result.error(
+                                  Exception('unable to update state'),
+                                );
+                              }
+                              if (context.mounted &&
+                                  widget.viewModel.settings.overwriteDatabase) {
+                                _backupDialog(context);
+                              }
+                              return Result.ok(null);
+                            },
+                          ),
+                        ],
+                      ),
+                    ],
+                  ),
+                  Align(
+                    alignment: Alignment.bottomCenter,
+                    child: Padding(
+                      padding: EdgeInsets.all(10),
+                      child: Row(
+                        mainAxisAlignment: MainAxisAlignment.center,
+                        children: [
+                          ElevatedButton(
+                            style: ElevatedButton.styleFrom(
+                              backgroundColor: colorCompositionFromAction(
+                                context,
+                                ApplicationAction.downloadBackup,
+                              ).background,
+                              foregroundColor: colorCompositionFromAction(
+                                context,
+                                ApplicationAction.downloadBackup,
+                              ).foreground,
+                            ),
+                            onPressed: _shareBackup,
+                            child: Padding(
+                              padding: EdgeInsets.symmetric(vertical: 10),
+                              child: Row(
+                                spacing: 10,
+                                children: [
+                                  Icon(Icons.download, size: 23),
+                                  const Text('Backup state.db'),
+                                ],
+                              ),
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ),
+                ],
+              );
+            },
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+void _shareBackup() async {
+  final path = await getDatabasesPath();
+  await SharePlus.instance.share(
+    ShareParams(files: [XFile(join(path, "state.db"))], title: 'Save state.db'),
+  );
+}
+
+void _backupDialog(BuildContext context) {
+  final backupComp = colorCompositionFromAction(
+    context,
+    ApplicationAction.downloadBackup,
+  );
+  showDialog(
+    context: context,
+    builder: (context) {
+      final colorScheme = Theme.of(context).colorScheme;
+      final screeWidth = MediaQuery.of(context).size.width;
+      return Center(
+        child: Container(
+          padding: EdgeInsets.only(bottom: 10),
+          decoration: BoxDecoration(
+            borderRadius: BorderRadius.circular(30),
+            boxShadow: List<BoxShadow>.generate(4, (index) {
+              var i = 1, j = 1;
+              if (index == 1) i = -1;
+              if (index == 2) j = -1;
+              if (index == 3) {
+                i = -1;
+                j = -1;
+              }
+              final double offset = .5;
+              return BoxShadow(
+                color: colorScheme.surfaceDim,
+                offset: Offset(i * offset, j * offset),
+                blurRadius: 4,
+              );
+            }),
+            color: colorScheme.surface,
+          ),
+          width: screeWidth * .8,
+          child: Padding(
+            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
+            child: Column(
+              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Padding(
+                  padding: EdgeInsets.symmetric(vertical: 20),
+                  child: Row(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    spacing: 20,
+                    children: [
+                      Icon(size: 40, Icons.warning),
+                      Flexible(child: const Text(_warning1)),
+                    ],
+                  ),
+                ),
+                const Padding(
+                  padding: EdgeInsets.only(bottom: 20),
+                  child: Text(_warning2),
+                ),
+                Row(
+                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
+                  children: [
+                    ElevatedButton(
+                      onPressed: () {
+                        Navigator.of(context).pop();
+                      },
+                      child: const Text('Backed up'),
+                    ),
+                    ElevatedButton(
+                      onPressed: () async {
+                        _shareBackup();
+                        Navigator.of(context).pop();
+                      },
+                      style: ElevatedButton.styleFrom(
+                        foregroundColor: backupComp.foreground,
+                        backgroundColor: backupComp.background,
+                      ),
+                      child: const Text('Backup'),
+                    ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ),
+      );
+    },
+  );
+}
+
+const _warning1 =
+    'With this setting, the database will be reset from assets then next time app restart.';
+const _warning2 =
+    'Make sure you saved a backup of state.db before you restart the application. The option will be set back to false after restart.';
diff --git a/migrations/20251217071137.sql b/migrations/20251217071137.sql
new file mode 100644
index 0000000..214d788
--- /dev/null
+++ b/migrations/20251217071137.sql
@@ -0,0 +1 @@
+INSERT INTO app_settings (overwrite_database) VALUES(0);
diff --git a/migrations/atlas.sum b/migrations/atlas.sum
index 9372762..59c519c 100644
--- a/migrations/atlas.sum
+++ b/migrations/atlas.sum
@@ -1,7 +1,8 @@
-h1:8hdx9iOtquP4B7xIdDRkC2EnDX/bBrnoOIJwR+32avE=
+h1:msyCtXYbFMuRvrjx0aKlNBKfM5MxuWv9/kNX9SrRJ3Y=
 20251128090519.sql h1:Vq9pU0BhID5J2tkEDGRM9jY5j02fZ4ztBSKmSG2V2eE=
 20251204104303.sql h1:qs5EfX02yTi2XWrEWo4pv15v/u9fad1Uz5lZuQfzi4Y=
 20251204105119.sql h1:DJ2o6FLPxmmtNj+yPkXnei0K6XIDavH7C70PPDO+8Jg=
 20251205144303.sql h1:ZlGWqd9GDxYdmmjkr/Y4O2+zPzQO9itg3LyYG/J6iRg=
 20251209194042.sql h1:8/zqBQWNW0ac/5kG4eTi4I5QowOrU7inSBBl+btMRgA=
 20251216220121.sql h1:ciqAlFUXyBugMMjFynySSqowpuIBbztWr6AQQ041Phw=
+20251217071137.sql h1:ZqycoqgH3CldMO7Snxz9n91VUsPwiJPBsb+gMX1cp8U=


----------------

git status -s

M  lib/config/dependencies.dart
M  lib/data/services/database/database_prepare.dart
M  lib/domain/models/settings/settings_summary.dart
M  lib/main.dart
M  lib/routing/router.dart
M  lib/ui/core/ui/routine_action.dart
M  lib/ui/home/widgets/home_screen.dart
M  lib/ui/home/widgets/new_routine.dart
M  lib/ui/settings/view_models/settings_viewmodel.dart
A  lib/ui/settings/widgets/overwrite_database_switch.dart
A  lib/ui/settings/widgets/settings_screen.dart
A  migrations/20251217071137.sql
M  migrations/atlas.sum

```


-------------------------------------------------
-------- NEXT STEPS AND WORK IN PROGRESS --------
-------------------------------------------------


**WIP Context:** *None*