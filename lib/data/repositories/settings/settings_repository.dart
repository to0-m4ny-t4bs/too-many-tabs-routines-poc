import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/utils/result.dart';

abstract class SettingsRepository {
  Future<Result<SettingsSummary>> getSettings();
  Future<Result<void>> setOverwriteDatabase(bool setting);
}
