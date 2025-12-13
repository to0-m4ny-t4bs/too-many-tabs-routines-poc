import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/utils/result.dart';

Future<Result<Database>> prepareDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'state.db');
  final log = Logger('prepareDatabase');

  // try {
  //   await deleteDatabase(path);
  //   log.warning('[DEV] deleted database');
  // } on Exception catch (e) {
  //   Result.error(e);
  // }

  final exists = await databaseExists(path);
  if (!exists) {
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
  } else {
    log.fine('Opening existing database');
  }

  return Result.ok(await openDatabase(path));
}
