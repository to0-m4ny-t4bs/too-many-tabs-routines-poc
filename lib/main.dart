import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/config/dependencies.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/themes/theme.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final resultDatabase = await prepareDatabase();
  final Database db;
  switch (resultDatabase) {
    case Error<Database>():
      return;
    case Ok<Database>():
  }
  db = resultDatabase.value;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    debugPrint(
      [
        'level=${record.level}',
        'time=${record.time}',
        'logger=${record.loggerName}',
        'msg=${record.message}',
      ].join(' '),
    );
    final client = DatabaseClient(db: db);
    if (record.level >= Level.INFO) {
      client.log(
        level: record.level.name,
        time: record.time,
        logger: record.loggerName,
        message: record.message,
      );
    }
  });

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final notificationsPluginDarwinSettings = DarwinInitializationSettings();
  final notificationsInitializationSettings = InitializationSettings(
    iOS: notificationsPluginDarwinSettings,
  );
  await notificationsPlugin.initialize(
    notificationsInitializationSettings,
    onDidReceiveNotificationResponse: (notification) {},
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // await notificationsPlugin.show(
  //   0,
  //   'Routines',
  //   'Update',
  //   NotificationDetails(iOS: DarwinNotificationDetails(presentAlert: true)),
  //   payload: 'item',
  // );

  await _configureLocalTimeZone();
  //await notificationsPlugin.zonedSchedule(
  //  0,
  //  'Routines',
  //  'Scheduled',
  //  tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
  //  NotificationDetails(iOS: DarwinNotificationDetails(presentAlert: true)),
  //  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //);

  runApp(
    MultiProvider(
      providers: providerLocal(
        db: db,
        notificationsPlugin: notificationsPlugin,
      ),
      child: const RootRestorationScope(
        restorationId: 'root',
        child: MainApp(),
      ),
    ),
  );
}

// https://github.com/MaikuB/flutter_local_notifications/blob/30813e25acd2557a923506958ec26afd49a7e808/flutter_local_notifications/example/lib/main.dart#L189
Future<void> _configureLocalTimeZone() async {
  final log = Logger('_configureLocalTimeZone');
  tz.initializeTimeZones();
  //final timeZoneInfo = await FlutterTimezone.getLocalTimezone('UTC+1');
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));
  log.fine('timeZoneInfo: ${tz.local}');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scrollBehavior: AppCustomScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router(),
      restorationScopeId: 'app',
    );
  }
}
