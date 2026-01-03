import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/result.dart';

class RoutinesRepositoryLocal implements RoutinesRepository {
  RoutinesRepositoryLocal({required DatabaseClient databaseClient})
    : _databaseClient = databaseClient;

  final DatabaseClient _databaseClient;
  final _log = Logger('RoutinesRepositoryLocal');

  @override
  Future<Result<int>> addRoutine(String name) async {
    return _databaseClient.createRoutine(name);
  }

  @override
  Future<Result<void>> restoreRoutine(int id) async {
    final resultLog = await _databaseClient.updateRoutineLog(
      id,
      RoutineState.restoredFromBin,
      DateTime.now(),
    );
    switch (resultLog) {
      case Error<void>():
        _log.warning('restoreRoutine: updateRoutineLog: ${resultLog.error}');
        return resultLog;
      case Ok<void>():
        _log.fine('restoreRoutine: updated routine log: restoredFromBin');
    }
    return _databaseClient.updateRoutineStore(
      routineId: id,
      archives: true,
      bin: false,
    );
  }

  @override
  Future<Result<void>> scheduleRoutine(int id) async {
    final resultLog = await _databaseClient.updateRoutineLog(
      id,
      RoutineState.restoredFromArchives,
      DateTime.now(),
    );
    switch (resultLog) {
      case Error<void>():
        _log.warning('scheduleRoutine: updateRoutineLog: ${resultLog.error}');
        return resultLog;
      case Ok<void>():
        _log.fine('scheduleRoutine: updated routine log: restoredFromArchives');
    }
    return _databaseClient.updateRoutineStore(
      routineId: id,
      archives: false,
      bin: false,
    );
  }

  @override
  Future<Result<void>> binRoutine(int id) async {
    final resultLog = await _databaseClient.updateRoutineLog(
      id,
      RoutineState.movedToBin,
      DateTime.now(),
    );
    switch (resultLog) {
      case Error<void>():
        _log.warning('binRoutine: updateRoutineLog: ${resultLog.error}');
        return resultLog;
      case Ok<void>():
        _log.fine('binRoutine: updated routine log movedToBin');
    }
    return _databaseClient.updateRoutineStore(
      routineId: id,
      archives: false,
      bin: true,
    );
  }

  @override
  Future<Result<void>> archiveRoutine(int id) async {
    final resultLog = await _databaseClient.updateRoutineLog(
      id,
      RoutineState.movedToArchives,
      DateTime.now(),
    );
    switch (resultLog) {
      case Error<void>():
        _log.warning('archiveRoutine: updateRoutineLog: ${resultLog.error}');
        return resultLog;
      case Ok<void>():
        _log.fine('archiveRoutine: updated routine log movedToArchives');
    }
    return _databaseClient.updateRoutineStore(
      routineId: id,
      archives: true,
      bin: false,
    );
  }

  @override
  Future<Result<List<RoutineSummary>>> getRoutinesList({
    required bool archived,
    required bool binned,
  }) async {
    final resultGet = await _databaseClient.getRoutines(
      archived: archived,
      binned: binned,
    );
    switch (resultGet) {
      case Error<List<RoutineSummary>>():
        _log.warning('db client get routines: ${resultGet.error}');
        return resultGet;
      case Ok<List<RoutineSummary>>():
    }

    List<RoutineSummary> routines = [];
    for (final routine in resultGet.value) {
      _log.fine('_dailyCheck ${routine.id}');
      final resultCheck = await _dailyCheck(routine.id);
      switch (resultCheck) {
        case Error<RoutineSummary>():
          _log.warning(
            '_dailyCheck failed on routine ${routine.id}: ${resultCheck.error}',
          );
          return Result.error(resultCheck.error);
        case Ok<RoutineSummary>():
          routines.add(resultCheck.value);
      }
    }

    return Result.ok(routines);
  }

  Future<Result<RoutineSummary>> _dailyCheck(int routineID) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _log.fine('_dailyCheck $routineID: last log started');
    final resultStarted = await _databaseClient.lastLog(
      routineID,
      RoutineState.started,
    );
    switch (resultStarted) {
      case Error<DateTime?>():
        _log.warning(
          'lastLog started routine $routineID: ${resultStarted.error}',
        );
        return Result.error(resultStarted.error);
      case Ok<DateTime?>():
        bool needSpentReset = false;
        bool needLogStop = false;
        if (resultStarted.value != null) {
          // last time routine was started was before today
          if (resultStarted.value!.isBefore(today)) {
            // therefore we need to reset routine "spent" attribute
            needSpentReset = true;
            _log.fine('_dailyCheck $routineID: last log stopped');
            final resultStopped = await _databaseClient.lastLog(
              routineID,
              RoutineState.stopped,
            );
            switch (resultStopped) {
              case Error<DateTime?>():
                _log.warning(
                  'lastLog stopped routine $routineID: ${resultStopped.error}',
                );
                return Result.error(resultStopped.error);
              case Ok<DateTime?>():
                // We need to clear time spent for the day if
                // 1) Last time routine stopped was before last time it started
                //    the routine has to be stopped.
                // 2) The routine was started but never stopped
                needLogStop =
                    resultStopped.value == null ||
                    (resultStopped.value != null &&
                        resultStopped.value!.isBefore(resultStarted.value!));
            }
          }
        }
        if (needLogStop) {
          _log.fine('_dailyCheck $routineID: logStop');
          final resultStop = await logStop(routineID, now);
          switch (resultStop) {
            case Error<void>():
              _log.warning('stop routine $routineID: ${resultStop.error}');
              return Result.error(resultStop.error);
            case Ok<void>():
          }
        }
        if (needSpentReset) {
          _log.fine('_dailyCheck $routineID: spent reset');
          final resultUpdateSpent = await _databaseClient.updateRoutineSpent(
            routineID,
            Duration(),
          );
          switch (resultUpdateSpent) {
            case Error<void>():
              _log.warning(
                'update routine."spent" $routineID: ${resultUpdateSpent.error}',
              );
              return Result.error(resultUpdateSpent.error);
            case Ok<void>():
          }

          _log.fine('_dailyCheck $routineID: running reset');
          final resultUpdateRunning = await _databaseClient
              .updateRoutineRunning(routineID, false);
          switch (resultUpdateRunning) {
            case Error<void>():
              _log.warning(
                'update routine."running" $routineID: ${resultUpdateRunning.error}',
              );
              return Result.error(resultUpdateRunning.error);
            case Ok<void>():
          }
        }
    }

    return getRoutineSummary(routineID);
  }

  @override
  Future<Result<RoutineSummary>> getRoutineSummary(int id) async {
    return _databaseClient.getRoutine(id);
  }

  @override
  Future<Result<RoutineSummary?>> getRunningRoutine() async {
    return _databaseClient.getRunningRoutine();
  }

  @override
  Future<Result<void>> logStart(int routineID, DateTime startedAt) async {
    final resultUpdateLog = await _databaseClient.updateRoutineLog(
      routineID,
      RoutineState.started,
      startedAt,
    );
    switch (resultUpdateLog) {
      case Error<void>():
        _log.warning(
          'Failed to log that routine started [id=$routineID]: ${resultUpdateLog.error}',
        );
        return resultUpdateLog;
      case Ok<void>():
        _log.fine('Logged routine started [id=$routineID]');
    }

    final runningResult = await _databaseClient.getRunningRoutine();
    switch (runningResult) {
      case Error<RoutineSummary?>():
        _log.warning('Failed to get running routine: ${runningResult.error}');
        return runningResult;
      case Ok<RoutineSummary?>():
        if (runningResult.value != null) {
          // Stop running routine if there is one
          final resultStop = await logStop(runningResult.value!.id, startedAt);
          switch (resultStop) {
            case Error<void>():
              _log.warning(
                'Failed to stop running routine [id=${runningResult.value!.id}]: ${resultStop.error}',
              );
              return resultStop;
            case Ok<void>():
          }
        }
    }

    return _databaseClient.updateRoutineRunning(routineID, true);
  }

  @override
  Future<Result<void>> logStop(int routineID, DateTime stoppedAt) async {
    final DateTime startedAt;

    final resultStart = await _databaseClient.lastLog(
      routineID,
      RoutineState.started,
    );
    switch (resultStart) {
      case Error<DateTime?>():
        _log.warning(
          'lastLog failed: routine [id=$routineID]: ${resultStart.error}',
        );
        return Result.error(resultStart.error);
      case Ok<DateTime?>():
        if (resultStart.value == null) {
          _log.warning('logStop: routine [id=$routineID] never started');
          return Result.error(Exception('routine $routineID never started'));
        }
        startedAt = resultStart.value!;
    }

    final resultLog = await _databaseClient.updateRoutineLog(
      routineID,
      RoutineState.stopped,
      stoppedAt,
    );
    switch (resultLog) {
      case Error<void>():
        _log.warning(
          'Failed to log that routine stopped [id=$routineID]: ${resultLog.error}',
        );
        return resultLog;
      case Ok<void>():
    }

    final resultRoutine = await _databaseClient.getRoutine(routineID);
    final Duration alreadySpent;
    switch (resultRoutine) {
      case Error<RoutineSummary>():
        _log.warning(
          'Failed to get routine summary [id=$routineID]: ${resultRoutine.error}',
        );
        return Result.error(resultRoutine.error);
      case Ok<RoutineSummary>():
        alreadySpent = resultRoutine.value.spent;
    }

    final addedSpent = stoppedAt.difference(startedAt);
    final resultUpdateSpent = await _databaseClient.updateRoutineSpent(
      routineID,
      addedSpent + alreadySpent,
    );
    switch (resultUpdateSpent) {
      case Error<void>():
        return resultUpdateSpent;
      case Ok<void>():
        _log.fine(
          'Stopped routine [id=$routineID alreadySpent=${alreadySpent.toString()} addedSpent=${addedSpent.toString()}]',
        );
    }

    final resultUpdate = await _databaseClient.updateRoutineRunning(
      routineID,
      false,
    );
    switch (resultUpdate) {
      case Error<void>():
        _log.warning(
          'Failed to update routine state to not running [id=$routineID]: ${resultUpdate.error}',
        );
      case Ok<void>():
        _log.fine('Stopped routine (updated state) [id=$routineID]');
    }

    return Result.ok(null);
  }

  @override
  Future<Result<void>> setGoal(int routineID, int goal30) async {
    return _databaseClient.udpateGoal(routineID, goal30);
  }

  @override
  Future<Result<List<NoteSummary>>> getNotes(int routineId) async {
    return _databaseClient.getNotes(routineId);
  }

  @override
  Future<Result<void>> addNote({
    required String note,
    required DateTime createdAt,
    required int routineId,
  }) {
    return _databaseClient.addNote(
      NoteSummary(
        routineId: routineId,
        createdAt: createdAt,
        note: note,
        dismissed: false,
      ),
    );
  }

  @override
  Future<Result<void>> dismissNote(int noteId) async {
    return _databaseClient.updateNoteDismissed(noteId, true);
  }
}
