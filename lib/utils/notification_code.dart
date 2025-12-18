enum NotificationCode {
  routineHalfGoal(0),
  routineCompletedGoal(1),
  routineGoalIn10Minutes(2),
  routineGoalIn5Minutes(3),
  routineSettleCheck(4);

  const NotificationCode(this.code);

  final int code;
}
