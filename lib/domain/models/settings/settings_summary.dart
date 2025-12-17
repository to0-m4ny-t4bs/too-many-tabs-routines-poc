class SettingsSummary {
  const SettingsSummary({required bool overwriteDatabase})
    : _overwriteDatabase = overwriteDatabase;
  final bool _overwriteDatabase;
  bool get overwriteDatabase => _overwriteDatabase;
  @override
  toString() {
    final settings = ['overwriteDatabase: $overwriteDatabase'].join(", ");
    return '{$settings}';
  }
}
