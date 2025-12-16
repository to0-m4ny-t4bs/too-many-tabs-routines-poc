**Input:**

**Scope:** `feat`

**Git Log:** *None*

**Diff:**
```diff
diff --git a/lib/data/repositories/settings/settings_repository.dart b/lib/data/repositories/settings/settings_repository.dart
new file mode 100644
index 0000000..f35eb69
--- /dev/null
+++ b/lib/data/repositories/settings/settings_repository.dart
@@ -0,0 +1,7 @@
+import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
+import 'package:too_many_tabs/utils/result.dart';
+
+abstract class SettingsRepository {
+  Future<Result<SettingsSummary>> getSettings();
+  Future<Result<void>> setOverwriteDatabase(bool setting);
+}
diff --git a/lib/data/repositories/settings/settings_repository_sqlite.dart b/lib/data/repositories/settings/settings_repository_sqlite.dart
new file mode 100644
index 0000000..73e2561
--- /dev/null
+++ b/lib/data/repositories/settings/settings_repository_sqlite.dart
@@ -0,0 +1,19 @@
+import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
+import 'package:too_many_tabs/data/services/database/database_client.dart';
+import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
+import 'package:too_many_tabs/utils/result.dart';
+
+class SettingsRepositorySqlite implements SettingsRepository {
+  SettingsRepositorySqlite({required DatabaseClient db}) : _db = db;
+  final DatabaseClient _db;
+
+  @override
+  Future<Result<void>> setOverwriteDatabase(bool setting) {
+    return _db.setSettingOverwriteDatabase(setting);
+  }
+
+  @override
+  Future<Result<SettingsSummary>> getSettings() {
+    return _db.getSettings();
+  }
+}
diff --git a/lib/data/services/database/database_client.dart b/lib/data/services/database/database_client.dart
index 763b4b4..330abd5 100644
--- a/lib/data/services/database/database_client.dart
+++ b/lib/data/services/database/database_client.dart
@@ -1,6 +1,7 @@
 import 'package:logging/logging.dart';
 import 'package:sqflite/sqflite.dart';
 import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
+import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
 import 'package:too_many_tabs/utils/result.dart';
 
 class DatabaseClient {
@@ -285,6 +286,32 @@ class DatabaseClient {
       return Result.error(e);
     }
   }
+
+  Future<Result<void>> setSettingOverwriteDatabase(bool setting) async {
+    try {
+      await _database.update('app_settings', {
+        'overwrite_database': setting ? 1 : 0,
+      });
+      return Result.ok(null);
+    } on Exception catch (e) {
+      return Result.error(e);
+    }
+  }
+
+  Future<Result<SettingsSummary>> getSettings() async {
+    try {
+      final rows = await _database.query('app_settings', limit: 1);
+      if (rows.isEmpty) {
+        return Result.error(Exception('app settings unavailables'));
+      }
+      final {'overwrite_database': overwriteDatabase as int} = rows[0];
+      return Result.ok(
+        SettingsSummary(overwriteDatabase: overwriteDatabase == 1),
+      );
+    } on Exception catch (e) {
+      return Result.error(e);
+    }
+  }
 }
 
 enum RoutineState {
diff --git a/lib/domain/models/settings/settings_summary.dart b/lib/domain/models/settings/settings_summary.dart
new file mode 100644
index 0000000..6a858db
--- /dev/null
+++ b/lib/domain/models/settings/settings_summary.dart
@@ -0,0 +1,6 @@
+class SettingsSummary {
+  const SettingsSummary({required bool overwriteDatabase})
+    : _overwriteDatabase = overwriteDatabase;
+  final bool _overwriteDatabase;
+  bool get overwriteDatabase => _overwriteDatabase;
+}
diff --git a/lib/routing/router.dart b/lib/routing/router.dart
index 063edb4..a9d23d6 100644
--- a/lib/routing/router.dart
+++ b/lib/routing/router.dart
@@ -10,7 +10,7 @@ import 'package:too_many_tabs/ui/home/widgets/home_screen.dart';
 
 GoRouter router() => GoRouter(
   restorationScopeId: 'router',
-  initialLocation: Routes.home,
+  initialLocation: Routes.settings,
   debugLogDiagnostics: true,
   routes: [
     GoRoute(
@@ -37,5 +37,12 @@ GoRouter router() => GoRouter(
         return BinScreen(viewModel: viewModel);
       },
     ),
+    GoRoute(
+      path: Routes.settings,
+      builder: (context, state) {
+        final viewModel = SettingsViewModel(settingsRepository: context.read());
+        return BinScreen(viewModel: viewModel);
+      },
+    ),
   ],
 );
diff --git a/lib/routing/routes.dart b/lib/routing/routes.dart
index 5a3112c..03971a8 100644
--- a/lib/routing/routes.dart
+++ b/lib/routing/routes.dart
@@ -2,4 +2,5 @@ abstract final class Routes {
   static const home = '/';
   static const archives = '/archives';
   static const bin = '/bin';
+  static const settings = '/settings';
 }
diff --git a/lib/ui/settings/view_models/settings_viewmodel.dart b/lib/ui/settings/view_models/settings_viewmodel.dart
new file mode 100644
index 0000000..d29fa94
--- /dev/null
+++ b/lib/ui/settings/view_models/settings_viewmodel.dart
@@ -0,0 +1,58 @@
+import 'package:flutter/material.dart';
+import 'package:logging/logging.dart';
+import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
+import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
+import 'package:too_many_tabs/utils/command.dart';
+import 'package:too_many_tabs/utils/result.dart';
+
+class SettingsViewmodel extends ChangeNotifier {
+  SettingsViewmodel({required SettingsRepository repository})
+    : _repository = repository {
+    load = Command0(_load)..execute();
+    switchOverwriteDatabase = Command0(_switchOverwriteDatabase);
+  }
+  final SettingsRepository _repository;
+  SettingsSummary? _settings;
+  SettingsSummary get settings => _settings!;
+  final _log = Logger('SettingsViewmodel');
+
+  late Command0 load;
+  late Command0 switchOverwriteDatabase;
+
+  Future<Result> _load() async {
+    try {
+      final resultGet = await _repository.getSettings();
+      switch (resultGet) {
+        case Error<SettingsSummary>():
+          _log.warning('_repository: getSettings: ${resultGet.error}');
+          return Result.error(resultGet.error);
+        case Ok<SettingsSummary>():
+          _settings = resultGet.value;
+          _log.fine(
+            'loaded settings (overwrite = ${settings.overwriteDatabase}',
+          );
+      }
+      return Result.ok(null);
+    } finally {
+      notifyListeners();
+    }
+  }
+
+  Future<Result<void>> _switchOverwriteDatabase() async {
+    try {
+      final resultSet = await _repository.setOverwriteDatabase(
+        !_settings!.overwriteDatabase,
+      );
+      switch (resultSet) {
+        case Error<void>():
+          _log.warning('_switchOverwriteDatabase: ${resultSet.error}');
+          return Result.error(resultSet.error);
+        case Ok<void>():
+      }
+      await _load();
+      return Result.ok(null);
+    } finally {
+      notifyListeners();
+    }
+  }
+}
diff --git a/migrations/20251216220121.sql b/migrations/20251216220121.sql
new file mode 100644
index 0000000..ce66043
--- /dev/null
+++ b/migrations/20251216220121.sql
@@ -0,0 +1,3 @@
+CREATE TABLE app_settings (
+  overwrite_database BOOLEAN NOT NULL
+);
diff --git a/migrations/atlas.sum b/migrations/atlas.sum
index b550058..9372762 100644
--- a/migrations/atlas.sum
+++ b/migrations/atlas.sum
@@ -1,6 +1,7 @@
-h1:ABi+/ELyW/Q15PPCF1yTLOSFzOCtWyTGj9uBDIHD5fU=
+h1:8hdx9iOtquP4B7xIdDRkC2EnDX/bBrnoOIJwR+32avE=
 20251128090519.sql h1:Vq9pU0BhID5J2tkEDGRM9jY5j02fZ4ztBSKmSG2V2eE=
 20251204104303.sql h1:qs5EfX02yTi2XWrEWo4pv15v/u9fad1Uz5lZuQfzi4Y=
 20251204105119.sql h1:DJ2o6FLPxmmtNj+yPkXnei0K6XIDavH7C70PPDO+8Jg=
 20251205144303.sql h1:ZlGWqd9GDxYdmmjkr/Y4O2+zPzQO9itg3LyYG/J6iRg=
 20251209194042.sql h1:8/zqBQWNW0ac/5kG4eTi4I5QowOrU7inSBBl+btMRgA=
+20251216220121.sql h1:ciqAlFUXyBugMMjFynySSqowpuIBbztWr6AQQ041Phw=


----------------

git status -s

A  lib/data/repositories/settings/settings_repository.dart
A  lib/data/repositories/settings/settings_repository_sqlite.dart
M  lib/data/services/database/database_client.dart
A  lib/domain/models/settings/settings_summary.dart
M  lib/routing/router.dart
M  lib/routing/routes.dart
A  lib/ui/settings/view_models/settings_viewmodel.dart
A  migrations/20251216220121.sql
M  migrations/atlas.sum

```


-------------------------------------------------
-------- NEXT STEPS AND WORK IN PROGRESS --------
-------------------------------------------------


**WIP Context:** *None*