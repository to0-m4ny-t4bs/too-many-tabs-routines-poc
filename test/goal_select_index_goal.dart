import 'package:flutter_test/flutter_test.dart';
import 'package:too_many_tabs/ui/home/widgets/slideup_panel.dart';

void main() {
  group('Test _GoalSelect: indexGoal', () {
    for (final (goal, expectedIndexHours, expectedIndexMinutes)
        in <(Duration, int, int)>[
          (Duration(), 0, 1),
          (Duration(minutes: 30), 0, 1),
          (Duration(hours: 1), 1, 0),
          (Duration(hours: 1, minutes: 30), 1, 1),
        ]) {
      test(
        'Expected (indexHours=$expectedIndexHours, indexMinutes=$expectedIndexMinutes) for goal=$goal)',
        () {
          expect(indexGoal(goal), (expectedIndexHours, expectedIndexMinutes));
        },
      );
    }
  });
}
