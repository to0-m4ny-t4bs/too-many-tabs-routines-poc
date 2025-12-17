import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/config/dependencies.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:too_many_tabs/notifications.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/themes/theme.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  });

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

  final List<DarwinNotificationCategory> darwinNotificationCategories = [];

  final initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );

  final initializationSettings = InitializationSettings(
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
  );

  // final notificationAppLaunchDetails = await flutterLocalNotificationsPlugin
  //     .getNotificationAppLaunchDetails();

  await _configureLocalTimeZone();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: providerLocal(
        db: db,
        notificationsPlugin: flutterLocalNotificationsPlugin,
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
