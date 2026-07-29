import 'package:flutter_test/flutter_test.dart';

import 'package:curling_companion/main.dart';

void main() {
  final signup = DateTime(2030, 1, 1);
  final start = DateTime(2030, 1, 10);
  final end = DateTime(2030, 1, 12);

  test('accepts signup deadline before start before end', () {
    expect(
      validateTournamentDateOrder(
        signupDeadline: signup,
        startDate: start,
        endDate: end,
      ),
      isNull,
    );
  });

  test('rejects signup deadline on or after start date', () {
    expect(
      validateTournamentDateOrder(
        signupDeadline: start,
        startDate: start,
        endDate: end,
      ),
      isNotNull,
    );
    expect(
      validateTournamentDateOrder(
        signupDeadline: end,
        startDate: start,
        endDate: end,
      ),
      isNotNull,
    );
  });

  test('rejects start date on or after end date', () {
    expect(
      validateTournamentDateOrder(
        signupDeadline: signup,
        startDate: end,
        endDate: start,
      ),
      isNotNull,
    );
  });

  test('rejects tournaments longer than five days', () {
    expect(
      validateTournamentDateOrder(
        signupDeadline: signup,
        startDate: start,
        endDate: DateTime(2030, 1, 16),
      ),
      'durationTooLong',
    );
  });

  test('allows an optional signup deadline', () {
    expect(validateTournamentDateOrder(startDate: start, endDate: end), isNull);
  });
}
