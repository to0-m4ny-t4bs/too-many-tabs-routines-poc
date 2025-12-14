import 'package:test/test.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

void main() {
  group('Test formatUntilGoal', () {
    for (final (goal, spent, forceSuffix, expected)
        in <(Duration, Duration, bool, String)>[
          (Duration(minutes: 30), Duration(minutes: 5), false, '25min'),
          (
            Duration(hours: 1, minutes: 30),
            Duration(minutes: 5),
            false,
            '1h25',
          ),
          (
            Duration(hours: 1, minutes: 30),
            Duration(minutes: 25),
            false,
            '1h05',
          ),
          (Duration(hours: 1, minutes: 30), Duration(minutes: 30), false, '1h'),
          (
            Duration(hours: 0, minutes: 10),
            Duration(minutes: 5),
            false,
            '5min',
          ),
          (
            Duration(hours: 1, minutes: 30),
            Duration(minutes: 5),
            true,
            '1h25min',
          ),
          (Duration(hours: 1, minutes: 30), Duration(minutes: 30), true, '1h'),
          (Duration(), Duration(), false, 'done'),
          (Duration(), Duration(), true, 'done'),
          (Duration(minutes: 1), Duration(minutes: 2), false, '+1min'),
          (Duration(minutes: 5), Duration(seconds: 30), false, "5min"),
          (Duration(minutes: 1), Duration(seconds: 30), false, "1min"),
          (Duration(minutes: 1), Duration(seconds: 60), false, "done"),
          (Duration(hours: 2), Duration(seconds: 5), false, "2h"),
          (Duration(hours: 2), Duration(seconds: 65), false, "1h59"),
        ]) {
      test(
        'Expected "$expected" with formatUntilGoal(goal=$goal, spent=$spent, forceSuffix=$forceSuffix)',
        () {
          expect(
            formatUntilGoal(goal, spent, forceSuffix: forceSuffix),
            expected,
          );
        },
      );
    }
  });
}
