import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class BinViewmodel extends ChangeNotifier {
  BinViewmodel({required RoutinesRepository routinesRepository})
    : _routinesRepository = routinesRepository {
    load = Command0(_load)..execute();
    restore = Command1(_restore);
  }

  final RoutinesRepository _routinesRepository;
  final _log = Logger('BinViewmodel');

  List<RoutineSummary> _routines = [];

  List<RoutineSummary> get routines => _routines;

  late Command0 load;
  late Command1<void, int> restore;

  Future<Result> _load() async {
    try {
      final resultGet = await _routinesRepository.getRoutinesList(
        archived: false,
        binned: true,
      );
      switch (resultGet) {
        case Error<List<RoutineSummary>>():
          _log.warning('_load: resultGet: ${resultGet.error}');
          return resultGet;
        case Ok<List<RoutineSummary>>():
          _routines = resultGet.value;
          _log.fine(
            '_load: resultGet: loaded ${resultGet.value.length} binned routines',
          );
      }

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _restore(int id) async {
    try {
      final resultRestore = await _routinesRepository.archiveRoutine(id);
      switch (resultRestore) {
        case Error<void>():
          _log.warning('_restore: archiveRoutine $id: ${resultRestore.error}');
          return resultRestore;
        case Ok<void>():
          _log.fine('_restore: archiveRoutine $id');
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
