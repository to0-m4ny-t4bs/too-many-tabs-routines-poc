enum RoutineState {
  goalReached,
  notStarted,
  isRunning,
  inProgress,
  overRun;

  const RoutineState();

  @override
  String toString() {
    switch (this) {
      case RoutineState.goalReached:
        return 'Goal Reached';
      case RoutineState.notStarted:
        return 'Not Started';
      case RoutineState.isRunning:
        return 'Is Running';
      case RoutineState.inProgress:
        return 'In Progress';
      case RoutineState.overRun:
        return 'Over Run';
    }
  }
}
