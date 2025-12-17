import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/utils/result.dart';

Future<Result<Database>> prepareDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'state.db');
  final log = Logger('prepareDatabase');

  final exists = await databaseExists(path);
  log.fine('database ${exists ? "" : "does not"} exist${exists ? "s" : ""}');
  var reset = false;
  if (exists) {
    log.fine('Opening existing database');
    final client = DatabaseClient(db: await openDatabase(path));
    final resultSettings = await client.getSettings();
    switch (resultSettings) {
      case Error<SettingsSummary>():
        log.severe('unable to load settings');
        return Result.error(
          Exception('unable to get settings: ${resultSettings.error}'),
        );
      case Ok<SettingsSummary>():
        log.fine("loaded settings: ${resultSettings.value}");
        if (resultSettings.value.overwriteDatabase) {
          try {
            log.warning('overwriting database as in settings');
            await deleteDatabase(path);
            log.warning('[DEV] deleted database');
          } on Exception catch (e) {
            return Result.error(e);
          }
          reset = true;
        }
    }
  }
  if (reset || !exists) {
    log.info('Creating new copy of state.db from asset');

    try {
      await Directory(dirname(path)).create(recursive: true);
    } on Exception catch (e) {
      log.severe('Cannot create state.db copy destination directory $path');
      return Result.error(e);
    }

    ByteData data = await rootBundle.load(url.join("assets", "state.db"));
    List<int> bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await File(path).writeAsBytes(bytes, flush: true);
  }

  return Result.ok(await openDatabase(path));
}
