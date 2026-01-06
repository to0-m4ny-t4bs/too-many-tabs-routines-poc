import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_bin.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal_session.dart';
import 'package:too_many_tabs/ui/home/view_models/destination_bucket.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel({
    required RoutinesRepository routinesRepository,
    required SettingsRepository settingsRepository,
  }) : _routinesRepository = routinesRepository,
       _settingsRepository = settingsRepository {
    load = Command0(_load)..execute();
    startOrStopRoutine = Command1(_startOrStopRoutine);
    updateRoutineGoal = Command1(_updateRoutineGoal);
    addRoutine = Command1(_createRoutine);
    archiveOrBinRoutine = Command1(_archiveOrBinRoutine);
    updateSpecialSessionStatus = Command1(_updateSpecialSessionStatus);
    toggleSpecialSession = Command1(_toggleSpecialSession);
  }

  final RoutinesRepository _routinesRepository;
  final _log = Logger('HomeViewmodel');
  List<RoutineSummary> _routines = [];
  RoutineSummary? _pinnedRoutine;
  int? _lastCreatedRoutineID;

  late Command0 load;
  late Command1<void, int> startOrStopRoutine;
  late Command1<void, GoalUpdate> updateRoutineGoal;
  late Command1<void, String> addRoutine;
  late Command1<void, (int, DestinationBucket)> archiveOrBinRoutine;
  late Command1<void, int> trashRoutine;
  late Command1<void, DateTime> updateSpecialSessionStatus;
  late Command1<void, SpecialGoal> toggleSpecialSession;

  List<RoutineSummary> get routines => _routines;
  RoutineSummary? get pinnedRoutine => _pinnedRoutine;
  int? get lastCreatedRoutineID => _lastCreatedRoutineID;

  bool _newDay = true;
  bool get newDay => _newDay;

  final SettingsRepository _settingsRepository;

  Future<Result> _load() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final bin in [
        RoutineBin.today,
        RoutineBin.archives,
        RoutineBin.backlog,
      ]) {
        final result = await _routinesRepository.getRoutinesList(bin);
        switch (result) {
          case Error<List<RoutineSummary>>():
            _log.warning(
              '_load: getRoutinesList(${bin.toStringValue()}) ${result.error}',
            );
            return result;
          case Ok<List<RoutineSummary>>():
            for (final routine in result.value) {
              if (routine.lastStarted != null &&
                  routine.lastStarted!.isAfter(today)) {
                _newDay = false;
              }
            }
            _log.fine(
              '_load: getRoutinesList(${bin.toStringValue()}): ${result.value.length} routines loaded',
            );
            if (bin == RoutineBin.today) {
              _routines = _listRoutines(result.value);
            }
        }
      }

      await _updateSpecialSessionStatus(DateTime.now());

      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _archiveOrBinRoutine(
    (int, DestinationBucket) archiveOrBin,
  ) async {
    final id = archiveOrBin.$1;
    final destination = archiveOrBin.$2;
    try {
      final resultRunning = await _routinesRepository.getRunningRoutine();
      switch (resultRunning) {
        case Error<RoutineSummary?>():
          _log.warning(
            '_archiveOrBinRoutine: failed to get running routine: ${resultRunning.error}',
          );
        case Ok<RoutineSummary?>():
          if (resultRunning.value != null && resultRunning.value!.id == id) {
            final resultStop = await _routinesRepository.logStop(
              resultRunning.value!.id,
              DateTime.now(),
            );
            switch (resultStop) {
              case Error<void>():
                _log.warning(
                  '_archiveOrBinRoutine: failed to stop $id: ${resultStop.error}',
                );
                return resultStop;
              case Ok<void>():
                _log.fine('_archiveOrBinRoutine: stopped $id');
                _pinnedRoutine = null;
            }
          }
      }

      final Result<void> resultAction;
      if (destination == DestinationBucket.archives) {
        resultAction = await _routinesRepository.binRoutine(id);
      } else {
        resultAction = await _routinesRepository.archiveRoutine(id);
      }
      switch (resultAction) {
        case Error<void>():
          _log.warning(
            '_archiveOrBinRoutine: action(${destination.destination}) $id: ${resultAction.error}',
          );
          return resultAction;
        case Ok<void>():
          _log.fine(
            '_archiveOrBinRoutine: action(${destination.destination}) $id',
          );
      }

      await _load();

      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('_archiveOrBinRoutine: $e');
      return Result.error(e);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _createRoutine(String name) async {
    try {
      final resultAdd = await _routinesRepository.addRoutine(name);
      switch (resultAdd) {
        case Error<int>():
          _log.warning('_createRoutine add routine: ${resultAdd.error}');
          return Result.error(resultAdd.error);
        case Ok<int>():
          _lastCreatedRoutineID = resultAdd.value;
          _log.fine(
            '_createRoutine added routine $name id=$_lastCreatedRoutineID',
          );
      }

      return _load();
    } on Exception catch (e) {
      _log.warning('_createRoutine: _load: $e');
      return Result.error(e);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _updateRoutineGoal(GoalUpdate request) async {
    try {
      final goal30 = request.goal.inMinutes ~/ 30;

      final resultSetGoal = await _routinesRepository.setGoal(
        request.routineID,
        goal30,
      );
      switch (resultSetGoal) {
        case Error<void>():
          _log.warning(
            'set goal routine ${request.routineID}: ${resultSetGoal.error}',
          );
          return Result.error(resultSetGoal.error);
        case Ok<void>():
          _log.fine('_updateRoutineGoal: goal set for ${request.routineID}');
      }

      final resultGetRoutine = await _routinesRepository.getRoutineSummary(
        request.routineID,
      );
      switch (resultGetRoutine) {
        case Error<RoutineSummary>():
          _log.warning(
            '_updateRoutineGoal: get summary of routine ${request.routineID}: ${resultGetRoutine.error}',
          );
          return Result.error(resultGetRoutine.error);
        case Ok<RoutineSummary>():
          _log.fine(
            '_updateRoutineGoal: resultGetRoutine: ${resultGetRoutine.value}',
          );
          final resultRunning = await _routinesRepository.getRunningRoutine();
          switch (resultRunning) {
            case Error<RoutineSummary?>():
              _log.warning(
                '_updateRoutineGoal: getRunningRoutine: ${resultRunning.error}',
              );
              return Result.error(resultRunning.error);
            case Ok<RoutineSummary?>():
              _pinnedRoutine = resultRunning.value;
              _log.fine('_updateRoutineGoal: _pinnedRoutine: $_pinnedRoutine');
          }
          _routines = _routines.map((routine) {
            if (routine.id == request.routineID) {
              return resultGetRoutine.value;
            }
            return routine;
          }).toList();
      }

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<RoutineSummary?>> _updateRunningRoutine() async {
    try {
      final resultRunning = await _routinesRepository.getRunningRoutine();
      switch (resultRunning) {
        case Error<RoutineSummary?>():
          _log.warning('_load get running routine: ${resultRunning.error}');
        case Ok<RoutineSummary?>():
          _pinnedRoutine = resultRunning.value;
      }
      return resultRunning;
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _startOrStopRoutine(int id) async {
    try {
      final resultRoutine = await _routinesRepository.getRoutineSummary(id);
      switch (resultRoutine) {
        case Error<RoutineSummary>():
          _log.warning(
            'Failed to get summary of routine $id',
            resultRoutine.error,
          );
          return resultRoutine;
        case Ok<RoutineSummary>():
      }

      _log.fine('_startOrStopRoutine: routine ${resultRoutine.value}');

      final now = DateTime.now();

      final Result<void> resultSwitch;
      final String action;

      bool started = false;

      if (resultRoutine.value.running) {
        resultSwitch = await _routinesRepository.logStop(id, now);
        action = 'Stopped';
      } else {
        resultSwitch = await _routinesRepository.logStart(id, now);
        action = 'Started';
        started = true;
      }

      switch (resultSwitch) {
        case Error<void>():
          _log.warning('$action failed routine[id=$id]', resultSwitch.error);
          return resultSwitch;
        case Ok<void>():
          _log.fine('$action routine $id');
      }

      if (started && _runningSpecialSession != null) {
        _toggleSpecialSession(_runningSpecialSession!);
      }

      // _routines = _listRoutines(
      //   _routines.map((routine) {
      //     if (routine.id == id) {
      //       return routine.from(
      //         setRunning: started,
      //         setLastStarted: started ? now : null,
      //       );
      //     }
      //     if (routine.running) {
      //       return routine.from(setRunning: false);
      //     }
      //     return routine;
      //   }).toList(),
      // );
      //
      // Can't do this as repository getRoutinesList does more than listing routines
      // especially "daily check".
      final resultList = await _routinesRepository.getRoutinesList(
        RoutineBin.today,
      );
      switch (resultList) {
        case Error<List<RoutineSummary>>():
          _log.warning(
            '_startOrStopRoutine: getRoutinesList: ${resultList.error}',
          );
          return Result.error(resultList.error);
        case Ok<List<RoutineSummary>>():
          _routines = _listRoutines(resultList.value);
      }

      await _updateSpecialSessionStatus(DateTime.now());
      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }

  List<RoutineSummary> _listRoutines(List<RoutineSummary> routines) {
    final List<RoutineSummary> sortedRoutines = [];
    final List<RoutineSummary> completedRoutines = [];
    final List<RoutineSummary> remainingRoutines = [];
    for (final routine in routines) {
      final completed = routine.goal <= routine.spent;
      if (routine.running) {
        _pinnedRoutine = routine;
        sortedRoutines.add(routine);
        _log.fine('running $_pinnedRoutine');
        continue;
      }
      if (completed) {
        completedRoutines.add(routine);
      } else {
        remainingRoutines.add(routine);
      }
    }
    sortedRoutines.addAll(remainingRoutines);
    sortedRoutines.addAll(completedRoutines);
    return sortedRoutines;
  }

  SpecialSessionDuration? _specialSessionStatus;
  SpecialSessionDuration? get specialSessionStatus => _specialSessionStatus;

  final Map<SpecialGoal, SpecialSessionDuration> _specialSessionAllStatum = {};
  Map<SpecialGoal, SpecialSessionDuration> get specialSessionAllStatum =>
      _specialSessionAllStatum;

  Future<Result<void>> _updateSpecialSessionStatus(DateTime day) async {
    try {
      final resultCurrent = await _routinesRepository.currentSpecialSession();
      switch (resultCurrent) {
        case Error<SpecialGoalSession?>():
          _log.warning(
            '_updateSpecialSessionStatus: currentSpecialSession: ${resultCurrent.error}',
          );
          return Result.error(resultCurrent.error);
        case Ok<SpecialGoalSession?>():
          _log.fine(
            '_updateSpecialSessionStatus: currentSpecialSession: ${resultCurrent.value}',
          );
      }

      _runningSpecialSession = resultCurrent.value?.goal;
      {
        final result = await _settingsRepository.getSettings();
        switch (result) {
          case Error<SettingsSummary>():
            _log.warning(
              '_updateSpecialSessionStatus: getSettings: ${result.error}',
            );
            return Result.error(result.error);
          case Ok<SettingsSummary>():
        }
      }

      final result = await _routinesRepository.sumSpecialSessionDurations(day);
      switch (result) {
        case Error<SpecialSessionDuration>():
          _log.warning(
            '_updateSpecialSessionStatus: sumSpecialSessionDurations: ${result.error}',
          );
          return Result.error(result.error);
        case Ok<SpecialSessionDuration>():
          _log.fine('_updateSpecialSessionStatus: ${result.value}');
          _specialSessionStatus = result.value;
      }

      if (resultCurrent.value != null) {
        final result = await _routinesRepository
            .currentSpecialSessionDuration();
        switch (result) {
          case Error<SpecialSessionDuration?>():
            _log.warning(
              '_updateSpecialSessionStatus: currentSpecialSessionDuration: ${result.error}',
            );
            return Result.error(result.error);
          case Ok<SpecialSessionDuration?>():
            _log.fine(
              '_updateSpecialSessionStatus: currentSpecialSessionDuration: ${result.value}',
            );
            _specialSessionAllStatum[resultCurrent.value!.goal] = result.value!;
        }
      }

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  SpecialGoal? _runningSpecialSession;
  SpecialGoal? get runningSpecialSession => _runningSpecialSession;

  RoutineSummary? _lastPinnedRoutine;

  Future<Result<void>> _toggleSpecialSession(SpecialGoal goal) async {
    try {
      final now = DateTime.now();
      final resultToggle = await _routinesRepository.toggleSpecialSession(
        goal,
        now,
      );
      switch (resultToggle) {
        case Error<(SpecialGoalSession?, SpecialGoalSession?)>():
          _log.warning(
            '_toggleSpecialSession: toggleSpecialSession: ${resultToggle.error}',
          );
          return Result.error(resultToggle.error);
        case Ok<(SpecialGoalSession?, SpecialGoalSession?)>():
      }

      final started = resultToggle.value.$2, stopped = resultToggle.value.$1;

      if (started != null) {
        _log.fine('started $started');
      }
      if (stopped != null) {
        _log.fine('stopped $stopped');
      }

      _updateSpecialSessionStatus(now);

      _log.fine(
        '_toggleSpecialSession: _runningSpecialSession: $_runningSpecialSession',
      );

      if (stopped != null && _lastPinnedRoutine != null) {
        final id = _lastPinnedRoutine!.id;
        _startOrStopRoutine(id);
        _lastPinnedRoutine = null;
        _log.fine(
          '_toggleSpecialSession: ${goal.column} started: _startOrStopRoutine($id) _lastPinnedRoutine<-null',
        );
      } else if (started != null && _pinnedRoutine != null) {
        _lastPinnedRoutine = _pinnedRoutine;
        final id = _pinnedRoutine!.id;
        _startOrStopRoutine(id);
        _log.fine(
          '_toggleSpecialSession: ${goal.column} started: refresh _lastPinnedRoutine then _startOrStopRoutine($id)',
        );
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
