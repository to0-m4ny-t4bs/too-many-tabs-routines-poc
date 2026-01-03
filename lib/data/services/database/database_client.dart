import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/utils/result.dart';

class DatabaseClient {
  DatabaseClient({required Database db}) : _database = db;

  final Database _database;
  final _log = Logger('DatabaseClient');

  Future<Result<void>> updateRoutineStore({
    required int routineId,
    required bool archives,
    required bool bin,
  }) async {
    try {
      await _database.update(
        'routines',
        {'archived': archives ? 1 : 0, 'binned': bin ? 1 : 0},
        where: 'id = ?',
        whereArgs: [routineId],
      );
      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('archiveRoutine: $e');
      return Result.error(e);
    }
  }

  Future<Result<int>> createRoutine(String name) async {
    try {
      var id = 0;
      await _database.transaction((tx) async {
        id = await tx.insert('routines', {
          'name': name,
          'goal_30m': 0,
          'spent_1s': 0,
          'running': 0,
        });
        await tx.insert('routines_logs', {
          'routine_id': id,
          'state': RoutineState.created.code,
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
      return Result.ok(id);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<void> log({
    required String level,
    required String message,
    required DateTime time,
    required String logger,
  }) {
    return _database.insert('logs', {
      'level': level,
      'message': message,
      'timestamp': time.toIso8601String(),
      'loggerName': logger,
    });
  }

  Future<Result<List<RoutineSummary>>> getRoutines({
    required bool archived,
    required bool binned,
  }) async {
    final List<Map<String, Object?>> rows;

    try {
      rows = await _database.query(
        'routines',
        orderBy: 'name',
        where: 'archived = ? AND binned = ?',
        whereArgs: [archived ? 1 : 0, binned ? 1 : 0],
      );
    } on Exception catch (e) {
      _log.warning('query routines', e.toString());
      return Result.error(e);
    }

    final List<RoutineSummary> routines = [];

    for (final row in rows) {
      final rowResult = await _extractRoutineSummary(row);
      switch (rowResult) {
        case Error<RoutineSummary>():
          _log.warning(
            'getRoutines: _extractRoutineSummary: ${rowResult.error}',
          );
          return Result.error(rowResult.error);
        case Ok<RoutineSummary>():
          routines.add(rowResult.value);
      }
    }

    return Result.ok(routines);
  }

  Future<Result<RoutineSummary>> _extractRoutineSummary(
    Map<String, Object?> row,
  ) async {
    final {
      'id': id as int,
      'name': name as String,
      'goal_30m': goal as int,
      'spent_1s': spent as int,
      'running': running as int,
    } = row;
    final DateTime? lastStarted;

    final resultLog = await lastLog(id, RoutineState.started);
    switch (resultLog) {
      case Error<DateTime?>():
        return Result.error(resultLog.error);
      case Ok<DateTime?>():
        lastStarted = resultLog.value;
    }

    final summary = RoutineSummary(
      id: id,
      name: name,
      goal: goal,
      spent: Duration(seconds: spent),
      running: running == 0 ? false : true,
      lastStarted: lastStarted,
    );
    _log.fine('_extractRoutineSummary: $summary');

    return Result.ok(summary);
  }

  Future<Result<RoutineSummary>> getRoutine(int id) async {
    try {
      final rows = await _database.query(
        'routines',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rows.length != 1) {
        Result.error(Exception('Routine not found'));
      }

      return _extractRoutineSummary(rows[0]);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<RoutineSummary?>> getRunningRoutine() async {
    final List<Map<String, Object?>> running;
    try {
      running = await _database.query('routines', where: 'running = 1');
    } on Exception catch (e) {
      return Result.error(e);
    }

    if (running.isEmpty) {
      return Result.ok(null);
    }

    if (running.length > 1) {
      return Result.error(Exception("Multiple routines are running"));
    }

    final {
      'id': id as int,
      'name': name as String,
      'goal_30m': goal as int,
      'spent_1s': spent as int,
    } = running[0];

    final DateTime? routineLastLog;

    final resultLast = await lastLog(id, RoutineState.started);
    switch (resultLast) {
      case Ok<DateTime?>():
        routineLastLog = resultLast.value;
        break;
      case Error<DateTime?>():
        return Result.error(resultLast.error);
    }

    return Result.ok(
      RoutineSummary(
        id: id,
        name: name,
        goal: goal,
        spent: Duration(seconds: spent),
        running: true,
        lastStarted: routineLastLog,
      ),
    );
  }

  Future<Result<void>> updateRoutineRunning(int routineID, bool running) async {
    try {
      await _database.update(
        'routines',
        {'running': running ? 1 : 0},
        where: 'id = ?',
        whereArgs: [routineID],
      );

      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateRoutineLog(
    int routineID,
    RoutineState state,
    DateTime timestamp,
  ) async {
    try {
      await _database.insert('routines_logs', {
        'updated_at': timestamp.toIso8601String(),
        'state': state.code,
        'routine_id': routineID,
      });
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateRoutineSpent(int routineID, Duration d) async {
    try {
      await _database.update(
        'routines',
        {'spent_1s': d.inSeconds},
        where: 'id = ?',
        whereArgs: [routineID],
      );
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<DateTime?>> lastLog(int routineID, RoutineState state) async {
    try {
      final rows = await _database.query(
        'routines_logs',
        where: 'routine_id = ? AND state = ?',
        whereArgs: [routineID, state.code],
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        return Result.ok(null);
      }

      final {'updated_at': t as String} = rows[0];
      return Result.ok(DateTime.parse(t));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> udpateGoal(int routineID, int newGoal) async {
    try {
      final t = DateTime.now().toIso8601String();
      await _database.transaction((tx) async {
        final rows = await tx.query(
          'routines',
          where: 'id = ?',
          whereArgs: [routineID],
        );
        if (rows.isEmpty) {
          return Result.error(Exception('no such routine: id=$routineID'));
        }
        final {'goal_30m': oldGoal as int} = rows[0];
        await tx.update(
          'routines',
          {'goal_30m': newGoal},
          where: 'id = ?',
          whereArgs: [routineID],
        );
        await tx.insert('goal_logs', {
          'routine_id': routineID,
          'old_goal': oldGoal,
          'new_goal': newGoal,
          'updated_at': t,
        });
        await tx.insert('routines_logs', {
          'routine_id': routineID,
          'updated_at': t,
          'state': RoutineState.goalUpdated.code,
        });
      });

      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setSettingOverwriteDatabase(bool setting) async {
    try {
      await _database.update('app_settings', {
        'overwrite_database': setting ? 1 : 0,
      });
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<SettingsSummary>> getSettings() async {
    try {
      final rows = await _database.query('app_settings', limit: 1);
      if (rows.isEmpty) {
        return Result.error(Exception('app settings unavailables'));
      }
      final {
        'overwrite_database': overwriteDatabase as int,
        'sit_back_goal': sitBackGoal as int,
        'stoke_goal': stokeGoal as int,
        'start_slow_goal': startSlowGoal as int,
        'slow_down_goal': slowDownGoal as int,
      } = rows[0];
      return Result.ok(
        SettingsSummary(
          overwriteDatabase: overwriteDatabase == 1,
          specialGoals: SpecialGoals(
            sitBack: Duration(minutes: 30 * sitBackGoal),
            stoke: Duration(minutes: 30 * stokeGoal),
            startSlow: Duration(minutes: 30 * startSlowGoal),
            slowDown: Duration(minutes: 30 * slowDownGoal),
          ),
        ),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateSpecialGoalSetting(
    SpecialGoal setting,
    Duration goal,
  ) async {
    try {
      await _database.transaction((tx) async {
        final Map<String, Object?> values = {};
        final goalFactor = goal.inMinutes ~/ 30;
        values[setting.column] = goalFactor;
        await tx.insert('special_goals_log', {
          'special_goal': setting.code,
          'goal': goalFactor,
        });
        await tx.update('app_settings', values);
      });
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<NoteSummary>>> getNotes(int routineId) async {
    try {
      final rows = await _database.query(
        'notes',
        orderBy: 'created_at DESC',
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );
      final List<NoteSummary> notes = [];
      for (final {
            'id': id as int,
            'created_at': createdAt3339 as String,
            'note': note as String?,
            'dismissed': dismissed as int,
          }
          in rows) {
        final createdAt = DateTime.parse(createdAt3339);
        if (note == null) continue;
        notes.add(
          NoteSummary(
            routineId: routineId,
            createdAt: createdAt,
            id: id,
            note: note,
            dismissed: dismissed == 1,
          ),
        );
      }
      return Result.ok(notes);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> addNote(NoteSummary note) async {
    try {
      await _database.insert('notes', {
        'routine_id': note.routineId,
        'created_at': note.createdAt.toIso8601String(),
        'note': note.text,
      });
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateNoteDismissed(int noteId, bool dismissed) async {
    try {
      await _database.update(
        'notes',
        {'dismissed': dismissed ? 1 : 0},
        where: 'id = ?',
        whereArgs: [noteId],
      );
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}

enum RoutineState {
  started(1),
  stopped(0),
  goalUpdated(2),
  created(3),
  movedToArchives(4),
  restoredFromArchives(5),
  restoredFromBin(6),
  movedToBin(7);

  const RoutineState(this.code);

  final int code;
}
