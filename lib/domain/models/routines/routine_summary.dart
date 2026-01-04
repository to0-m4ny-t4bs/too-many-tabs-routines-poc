class RoutineSummary {
  RoutineSummary({
    required int id,
    required String name,
    required int goal, // expected daily duration as multiple of 30m
    required Duration spent,
    required bool running,
    required DateTime? lastStarted, // last time the routine was started
  }) : _id = id,
       _goal = goal,
       _name = name,
       _spent = spent,
       _running = running,
       _lastStarted = lastStarted;

  final int _id, _goal;
  final String _name;
  final Duration _spent;
  final bool _running;
  final DateTime? _lastStarted;

  int get id => _id;
  String get name => _name;
  Duration get goal => Duration(minutes: 30) * _goal;
  Duration get spent => _spent;
  bool get running => _running;
  DateTime? get lastStarted => _lastStarted;

  @override
  String toString() {
    return [
      'RoutineSummary(',
      [
        'name="$_name"',
        'id=$_id',
        'goal=${Duration(minutes: _goal * 30)}',
        'spent=$_spent',
        'running=$_running',
        'lastStarted=$_lastStarted',
      ].join(' '),
      ')',
    ].join('');
  }

  RoutineSummary from({bool? setRunning, DateTime? setLastStarted}) {
    return RoutineSummary(
      id: id,
      name: name,
      goal: goal.inMinutes ~/ 30,
      spent: spent,
      running: setRunning ?? running,
      lastStarted: setLastStarted ?? lastStarted,
    );
  }
}
