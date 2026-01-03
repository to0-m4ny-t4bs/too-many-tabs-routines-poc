class NoteSummary {
  NoteSummary({
    int? id,
    required int routineId,
    required String note,
    required DateTime createdAt,
    required bool dismissed,
  }) : _id = id,
       _note = note,
       _createdAt = createdAt,
       _routineId = routineId,
       _dismissed = dismissed;

  final int? _id;
  final DateTime _createdAt;
  final String _note;
  final int _routineId;
  final bool _dismissed;

  int? get id => _id;
  int get routineId => _routineId;
  DateTime get createdAt => _createdAt;
  String get text => _note;
  bool get dismissed => _dismissed;

  @override
  String toString() {
    return [
      'NoteSummary',
      [
        'createdAt=$_createdAt',
        'id=$_id',
        'note=$_note',
        'routineId=$_routineId',
        'dismissed=$_dismissed',
      ].join(' '),
    ].join(' ');
  }
}
