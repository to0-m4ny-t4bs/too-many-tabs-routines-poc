import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/notifications.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/notification_code.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timezone/timezone.dart' as tz;

class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel({
    required RoutinesRepository routinesRepository,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
  }) : _routinesRepository = routinesRepository,
       _notificationsPlugin = notificationsPlugin {
    load = Command0(_load)..execute();
    startOrStopRoutine = Command1(_startOrStopRoutine);
    updateRoutineGoal = Command1(_updateRoutineGoal);
    addRoutine = Command1(_createRoutine);
    archiveOrBinRoutine = Command1(_archiveOrBinRoutine);
  }

  final RoutinesRepository _routinesRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final _log = Logger('HomeViewmodel');
  List<RoutineSummary> _routines = [];
  RoutineSummary? _pinnedRoutine;
  int? _lastCreatedRoutineID;

  late Command0 load;
  late Command1<void, int> startOrStopRoutine;
  late Command1<void, GoalUpdate> updateRoutineGoal;
  late Command1<void, String> addRoutine;
  late Command1<void, (int, bool)> archiveOrBinRoutine;
  late Command1<void, int> trashRoutine;

  List<RoutineSummary> get routines => _routines;
  RoutineSummary? get pinnedRoutine => _pinnedRoutine;
  int? get lastCreatedRoutineID => _lastCreatedRoutineID;

  Future<Result> _load() async {
    try {
      final result = await _routinesRepository.getRoutinesList(
        archived: false,
        binned: false,
      );
      switch (result) {
        case Error<List<RoutineSummary>>():
          _log.warning('Failed to load routines', result.error);
          return result;
        case Ok<List<RoutineSummary>>():
          _routines = result.value;
          for (final routine in _routines) {
            if (routine.running) {
              _pinnedRoutine = routine;
              _log.fine(
                'running routine (pinned routine) id=${_pinnedRoutine!.id} "${_pinnedRoutine!.name}"',
              );
              break;
            }
          }
          _log.fine('Loaded routines');
      }

      await _updateNotifications();

      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _archiveOrBinRoutine((int, bool) archiveOrBin) async {
    final id = archiveOrBin.$1;
    final bin = archiveOrBin.$2;
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
      if (bin) {
        resultAction = await _routinesRepository.binRoutine(id);
      } else {
        resultAction = await _routinesRepository.archiveRoutine(id);
      }
      switch (resultAction) {
        case Error<void>():
          _log.warning(
            '_archiveOrBinRoutine: action(bin=$bin) $id: ${resultAction.error}',
          );
          return resultAction;
        case Ok<void>():
          _log.fine('_archiveOrBinRoutine: action(bin=$bin) $id');
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

  Future<void> _updateNotifications() async {
    try {
      _log.fine('_updateNotifications: tz.local: ${tz.local}');
      for (final code in [
        NotificationCode.routineCompletedGoal,
        NotificationCode.routineHalfGoal,
        NotificationCode.routineGoalIn10Minutes,
        NotificationCode.routineGoalIn5Minutes,
        NotificationCode.routineSettleCheck,
      ]) {
        await _notificationsPlugin.cancel(code.code);
      }
      _log.fine(
        '_updateNotifications: cancelled routineHalfGoal, routineCompletedGoal',
      );
      _log.fine('_updateNotifications: pinnedRoutine: $_pinnedRoutine');
      if (_pinnedRoutine == null) return;
      final left = _pinnedRoutine!.goal - _pinnedRoutine!.spent;
      final untilHalfWay = Duration(minutes: left.inMinutes ~/ 2);
      final roundedLastStarted = _pinnedRoutine!.lastStarted!.add(
        // e.g. if started at 12:00:40 rounded would be 12:01:00
        // and therefore notification is delayed by 20 seconds
        Duration(seconds: 60 - _pinnedRoutine!.lastStarted!.second),
      );
      final halfWay = roundedLastStarted.add(untilHalfWay);
      final scheduleHalfWay =
          untilHalfWay.inMinutes >= 20 && halfWay.isAfter(DateTime.now());
      _log.fine(
        '_updateNotifications: routineHalfGoal: $halfWay schedule: $scheduleHalfWay',
      );
      if (scheduleHalfWay) {
        try {
          final sched = await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: "Halfway there! ${untilHalfWay.inMinutes}min left.",
            id: NotificationCode.routineHalfGoal,
            schedule: halfWay,
          );
          _log.fine(
            '_updateNotifications: scheduled routineHalfGoal at $sched',
          );
        } catch (e) {
          _log.warning('_updateNotifications: schedule routineHalfGoal: $e');
        }
      }
      if (!scheduleHalfWay && left.inMinutes >= 27) {
        // worst case: 27 minutes left we have at least 7 min between notifications
        try {
          final t = DateTime.now().add(Duration(minutes: 10));
          final sched = await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: "Settle in! ${left.inMinutes - 10}m left.",
            id: NotificationCode.routineSettleCheck,
            schedule: t,
          );
          _log.fine(
            '_updateNotifications: routineSettleCheck at $sched (${left.inMinutes - 10})',
          );
        } catch (e) {
          _log.warning('_updateNotifications: routineSettleCheck: $e');
        }
      }

      final done = roundedLastStarted.add(
        _pinnedRoutine!.goal - _pinnedRoutine!.spent,
      );
      final scheduleDone = done.isAfter(DateTime.now());
      _log.fine(
        '_updateNotifications: routineCompletedGoal: $done schedule: $scheduleDone',
      );
      if (scheduleDone) {
        try {
          final sched = await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: 'We\'re Done!',
            id: NotificationCode.routineCompletedGoal,
            schedule: done,
          );
          _log.fine(
            '_updateNotifications: scheduled routineHalfGoal at $sched',
          );
        } catch (e) {
          _log.warning(
            '_updateNotifications: schedule routineCompletedGoalz: $e',
          );
        }
      }

      final goalIn10 = roundedLastStarted.add(
        _pinnedRoutine!.goal - Duration(minutes: 10) - _pinnedRoutine!.spent,
      );
      final scheduleGoalIn10 = goalIn10.isAfter(DateTime.now());
      _log.fine(
        '_updateNotifications: routineGoalIn10Minutes: $goalIn10 schedule: $scheduleGoalIn10',
      );
      if (scheduleGoalIn10) {
        try {
          final sched = await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: 'Time to wrap up! 10 mins left.',
            id: NotificationCode.routineGoalIn10Minutes,
            schedule: goalIn10,
          );
          _log.fine(
            '_updateNotifications: scheduled routineGoalIn10Minutes at $sched',
          );
        } catch (e) {
          _log.warning(
            '_updateNotifications: schedule routineGoalIn10Minutes: $e',
          );
        }
      }
    } on Exception catch (e) {
      _log.severe('_updateNotifications: $e');
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

      await _updateNotifications();

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<RoutineSummary?>> _updateRunningRoutine() async {
    final resultRunning = await _routinesRepository.getRunningRoutine();
    switch (resultRunning) {
      case Error<RoutineSummary?>():
        _log.warning('_load get running routine: ${resultRunning.error}');
      case Ok<RoutineSummary?>():
        _pinnedRoutine = resultRunning.value;
        await _updateNotifications();
    }
    return resultRunning;
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

      final Result<void> resultSwitch;
      final String action;
      if (resultRoutine.value.running) {
        resultSwitch = await _routinesRepository.logStop(id, DateTime.now());
        action = 'Stopped';
      } else {
        resultSwitch = await _routinesRepository.logStart(id, DateTime.now());
        action = 'Started';
      }

      switch (resultSwitch) {
        case Error<void>():
          _log.warning('$action failed routine[id=$id]', resultSwitch.error);
          return resultSwitch;
        case Ok<void>():
          _log.fine('$action routine [id=$id]');
      }

      final resultRefresh = await _routinesRepository.getRoutinesList(
        archived: false,
        binned: false,
      );
      switch (resultRefresh) {
        case Error<List<RoutineSummary>>():
          _log.warning('Failed to load routines', resultRefresh.error);
          return resultRefresh;
        case Ok<List<RoutineSummary>>():
          _routines = resultRefresh.value;
          _log.fine('Loaded routines');
          for (final routine in resultRefresh.value) {
            _log.fine('_startOrStopRoutine: resultRefresh: $routine');
          }
      }

      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }
}
