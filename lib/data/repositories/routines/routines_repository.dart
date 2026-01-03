import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/result.dart';

abstract class RoutinesRepository {
  Future<Result<List<RoutineSummary>>> getRoutinesList({
    required bool archived,
    required bool binned,
  });
  Future<Result<RoutineSummary>> getRoutineSummary(int id);
  Future<Result<RoutineSummary?>> getRunningRoutine();
  Future<Result<void>> logStart(int routineID, DateTime time);
  Future<Result<void>> logStop(int routineID, DateTime time);
  Future<Result<void>> setGoal(int routineID, int goal30);
  Future<Result<int>> addRoutine(String name);
  Future<Result<void>> archiveRoutine(int id);
  Future<Result<void>> scheduleRoutine(int id);
  Future<Result<void>> restoreRoutine(int id);
  Future<Result<void>> binRoutine(int id);
  Future<Result<List<NoteSummary>>> getNotes(int routineId);
  Future<Result<void>> addNote({
    required String note,
    required DateTime createdAt,
    required int routineId,
  });
  Future<Result<void>> dismissNote(int noteId);
}
