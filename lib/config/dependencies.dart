import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository_local.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository_sqlite.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';

List<SingleChildWidget> providerLocal({
  required Database db,
  required FlutterLocalNotificationsPlugin notificationsPlugin,
}) {
  return [
    Provider(create: (context) => notificationsPlugin),
    Provider(create: (context) => DatabaseClient(db: db)),
    Provider(
      create: (context) =>
          SettingsRepositorySqlite(db: context.read()) as SettingsRepository,
    ),
    Provider(
      create: (context) =>
          RoutinesRepositoryLocal(databaseClient: context.read())
              as RoutinesRepository,
    ),
  ];
}
