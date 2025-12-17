import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class SettingsViewmodel extends ChangeNotifier {
  SettingsViewmodel({required SettingsRepository repository})
    : _repository = repository {
    load = Command0(_load)..execute();
    switchOverwriteDatabase = Command0(_switchOverwriteDatabase);
  }
  final SettingsRepository _repository;
  SettingsSummary? _settings;
  SettingsSummary get settings => _settings!;
  final _log = Logger('SettingsViewmodel');

  late Command0 load;
  late Command0 switchOverwriteDatabase;

  Future<Result> _load() async {
    try {
      final resultGet = await _repository.getSettings();
      switch (resultGet) {
        case Error<SettingsSummary>():
          _log.warning('_repository: getSettings: ${resultGet.error}');
          return Result.error(resultGet.error);
        case Ok<SettingsSummary>():
          _settings = resultGet.value;
          _log.fine('loaded settings $settings');
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _switchOverwriteDatabase() async {
    try {
      final resultSet = await _repository.setOverwriteDatabase(
        !_settings!.overwriteDatabase,
      );
      switch (resultSet) {
        case Error<void>():
          _log.warning('_switchOverwriteDatabase: ${resultSet.error}');
          return Result.error(resultSet.error);
        case Ok<void>():
      }
      await _load();
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
