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

  /// Returns a list of pairs where the first element is the original text
  /// fragment and the second element indicates whether that fragment could be
  /// parsed as a valid absolute [Uri].
  ///
  /// The note is first split by whitespace. Each fragment is then tested with
  /// `Uri.tryParse`. A fragment is considered a URI only when the parsing
  /// succeeds **and** the resulting `Uri` is absolute (i.e. it has a scheme).
  List<(String fragment, bool isUri)> get fragments {
    // Split on any amount of whitespace, discarding empty parts.
    final parts = _note.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final result = <(String, bool)>[];

    for (final part in parts) {
      final uri = Uri.tryParse(part);
      result.add((part, uri != null && uri.scheme == 'https'));
    }

    return result;
  }

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
