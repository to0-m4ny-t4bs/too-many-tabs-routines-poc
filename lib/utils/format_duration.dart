String formatSpentDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitsMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitsSeconds = twoDigits(d.inSeconds.remainder(60));
  String twoDigitsMilliseconds = twoDigits(
    d.inMilliseconds.remainder(1000) ~/ 10,
  );
  return '${twoDigits(d.inHours)}:$twoDigitsMinutes:$twoDigitsSeconds.$twoDigitsMilliseconds';
}

String formatUntilGoal(Duration goal, Duration spent, {bool? forceSuffix}) {
  final left = goal - spent;
  final seconds = left.inSeconds.remainder(3600);
  var minutes = seconds ~/ 60;
  final carryMinutes = seconds.remainder(60) > 0 ? 1 : 0;
  minutes += carryMinutes;
  final carryHours = minutes == 60 ? 1 : 0;
  minutes = minutes.remainder(60);
  final hours = left.inHours.remainder(60) + carryHours;
  final singleDigitHour = hours == 0 ? "" : '${hours.toString()}h';
  final twoDigitsMinutes = minutes == 0
      ? ""
      : (hours == 0
            ? minutes.toString().replaceFirst('-', '+')
            : minutes.toString().padLeft(2, "0"));
  var suffix = hours == 0 ? "min" : "";
  if (forceSuffix != null && minutes > 0 && forceSuffix) {
    suffix = "min";
  }
  return hours == 0 && minutes == 0
      ? 'done'
      : '$singleDigitHour$twoDigitsMinutes$suffix';
}
