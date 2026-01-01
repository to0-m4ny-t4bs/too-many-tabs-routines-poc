import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class NotesViewmodel extends ChangeNotifier {
  NotesViewmodel(RoutinesRepository repo, int routineId)
    : _repo = repo,
      _routineId = routineId {
    load = Command0(_load)..execute();
  }

  final RoutinesRepository _repo;
  final int _routineId;
  final _log = Logger('NotesViewmodel');

  late Command0 load;

  RoutineSummary? _routine;

  RoutineSummary get routine => _routine!;

  Future<Result> _load() async {
    try {
      final result = await _repo.getRoutineSummary(_routineId);
      switch (result) {
        case Error<RoutineSummary>():
          _log.warning('_load: getRoutineSummary: ${result.error}');
        case Ok<RoutineSummary>():
          _routine = result.value;
          _log.fine('_load: getRoutineSummary: $_routine');
      }
      return result;
    } finally {
      notifyListeners();
    }
  }
}
