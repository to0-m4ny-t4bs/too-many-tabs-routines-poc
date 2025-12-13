import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class ArchivesViewmodel extends ChangeNotifier {
  ArchivesViewmodel({required RoutinesRepository routinesRepository})
    : _routinesRepository = routinesRepository {
    load = Command0(_load)..execute();
    restore = Command1(_restore);
    bin = Command1(_bin);
  }

  final RoutinesRepository _routinesRepository;
  final _log = Logger('ArchivesViewmodel');
  List<RoutineSummary> _routines = [];

  late Command0 load;
  late Command1<void, int> restore;
  late Command1<void, int> bin;

  List<RoutineSummary> get routines => _routines;

  Future<Result> _load() async {
    try {
      final resultGet = await _routinesRepository.getRoutinesList(
        archived: true,
        binned: false,
      );
      switch (resultGet) {
        case Error<List<RoutineSummary>>():
          _log.warning('_load: getRoutinesList: ${resultGet.error}');
          return Result.error(resultGet.error);
        case Ok<List<RoutineSummary>>():
          _log.fine(
            '_load: getRoutinesList: ${resultGet.value.length} archived routines',
          );
          _routines = resultGet.value;
      }

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _restore(int id) async {
    try {
      final result = await _routinesRepository.scheduleRoutine(id);
      switch (result) {
        case Error<void>():
          _log.warning('_restore: restoreRoutine($id): ${result.error}');
          return result;
        case Ok<void>():
          _log.fine('_restore: restored routine $id');
      }

      await _load();

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _bin(int id) async {
    try {
      final resultBin = await _routinesRepository.binRoutine(id);
      switch (resultBin) {
        case Error<void>():
          _log.warning('_bin: binRoutine $id: ${resultBin.error}');
          return resultBin;
        case Ok<void>():
          _log.fine('_bin: binned routine $id');
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
