**Input:**

**Scope:** *None*

**Git Log:** *None*

**Diff:**
```diff
diff --git a/lib/routing/router.dart b/lib/routing/router.dart
index 218f1b6..05df80a 100644
--- a/lib/routing/router.dart
+++ b/lib/routing/router.dart
@@ -12,7 +12,7 @@ import 'package:too_many_tabs/ui/settings/widgets/settings_screen.dart';
 
 GoRouter router() => GoRouter(
   restorationScopeId: 'router',
-  initialLocation: Routes.settings,
+  initialLocation: Routes.home,
   debugLogDiagnostics: true,
   routes: [
     GoRoute(


----------------

git status -s

M  lib/routing/router.dart

```


-------------------------------------------------
-------- NEXT STEPS AND WORK IN PROGRESS --------
-------------------------------------------------


**WIP Context:** *None*