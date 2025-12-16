import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/utils/result.dart';

class SettingsRepositorySqlite implements SettingsRepository {
  SettingsRepositorySqlite({required DatabaseClient db}) : _db = db;
  final DatabaseClient _db;

  @override
  Future<Result<void>> setOverwriteDatabase(bool setting) {
    return _db.setSettingOverwriteDatabase(setting);
  }

  @override
  Future<Result<SettingsSummary>> getSettings() {
    return _db.getSettings();
  }
}
