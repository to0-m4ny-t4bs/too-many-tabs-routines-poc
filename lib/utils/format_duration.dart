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
  final hours = left.inHours.remainder(60);
  final singleDigitHour = hours == 0 ? "" : '${hours.toString()}h';
  final minutes = left.inSeconds <= 0
      ? left.inMinutes.remainder(60)
      : (left.inMinutes + (left.inSeconds.remainder(60) > 0 ? 1 : 0)).remainder(
          60,
        );
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
