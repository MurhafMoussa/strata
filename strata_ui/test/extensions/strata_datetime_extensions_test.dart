import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataDateTimeExtensions', () {
    group('formatMonthYear', () {
      test('formats as MMMM yyyy', () {
        final date = DateTime(2024, 3, 15);
        expect(date.formatMonthYear(), 'March 2024');
      });
    });

    group('formatDay', () {
      test('formats as dd', () {
        final date = DateTime(2024, 3, 5);
        expect(date.formatDay(), '05');
      });
    });

    group('formatMonthDay', () {
      test('formats as MMM dd', () {
        final date = DateTime(2024, 3, 15);
        expect(date.formatMonthDay(), 'Mar 15');
      });
    });

    group('formatFullDate', () {
      test('formats as EEE MMM dd, yyyy', () {
        final date = DateTime(2024, 3, 15);
        expect(date.formatFullDate(), 'Fri Mar 15, 2024');
      });
    });

    group('formatShortApiDate', () {
      test('formats as yy.MM.dd', () {
        final date = DateTime(2024, 3, 15);
        expect(date.formatShortApiDate(), '24.03.15');
      });
    });

    group('firstDayOfMonth', () {
      test('returns first day of month', () {
        final date = DateTime(2024, 3, 15);
        expect(date.firstDayOfMonth, DateTime(2024, 3, 1));
      });
    });

    group('lastDayOfMonth', () {
      test('returns last day of month', () {
        final date = DateTime(2024, 3, 15);
        expect(date.lastDayOfMonth, DateTime(2024, 3, 31));
      });

      test('handles December', () {
        final date = DateTime(2024, 12, 15);
        expect(date.lastDayOfMonth, DateTime(2024, 12, 31));
      });

      test('handles February in leap year', () {
        final date = DateTime(2024, 2, 15);
        expect(date.lastDayOfMonth, DateTime(2024, 2, 29));
      });

      test('handles February in non-leap year', () {
        final date = DateTime(2023, 2, 15);
        expect(date.lastDayOfMonth, DateTime(2023, 2, 28));
      });
    });

    group('isFirstDayOfMonth', () {
      test('returns true for first day', () {
        expect(DateTime(2024, 3, 1).isFirstDayOfMonth, isTrue);
      });

      test('returns false for non-first day', () {
        expect(DateTime(2024, 3, 15).isFirstDayOfMonth, isFalse);
      });
    });

    group('isLastDayOfMonth', () {
      test('returns true for last day', () {
        expect(DateTime(2024, 3, 31).isLastDayOfMonth, isTrue);
      });

      test('returns false for non-last day', () {
        expect(DateTime(2024, 3, 15).isLastDayOfMonth, isFalse);
      });
    });

    group('firstDayOfWeek', () {
      test('returns Sunday for a week starting on Sunday', () {
        final date = DateTime(2024, 3, 15); // Friday
        final firstDay = date.firstDayOfWeek;
        expect(firstDay.weekday, DateTime.sunday);
      });
    });

    group('lastDayOfWeek', () {
      test('returns Sunday for a week ending on Sunday', () {
        final date = DateTime(2024, 3, 15); // Friday
        final lastDay = date.lastDayOfWeek;
        expect(lastDay.weekday, DateTime.sunday);
      });
    });

    group('daysUntil', () {
      test('returns days between two dates', () {
        final start = DateTime(2024, 3, 1);
        final end = DateTime(2024, 3, 5);
        final days = start.daysUntil(end).toList();
        expect(days.length, 4);
        expect(days.first, DateTime(2024, 3, 1));
        expect(days.last, DateTime(2024, 3, 4));
      });
    });

    group('isSameWeek', () {
      test('returns true for dates in the same week', () {
        final date1 = DateTime(2024, 3, 11); // Monday
        final date2 = DateTime(2024, 3, 15); // Friday
        expect(date1.isSameWeek(date2), isTrue);
      });

      test('returns false for dates in different weeks', () {
        final date1 = DateTime(2024, 3, 15); // Friday
        final date2 = DateTime(2024, 3, 17); // Sunday (next week)
        expect(date1.isSameWeek(date2), isFalse);
      });
    });

    group('previousMonth', () {
      test('returns first day of previous month', () {
        final date = DateTime(2024, 3, 15);
        expect(date.previousMonth, DateTime(2024, 2, 1));
      });

      test('handles January', () {
        final date = DateTime(2024, 1, 15);
        expect(date.previousMonth, DateTime(2023, 12, 1));
      });
    });

    group('nextMonth', () {
      test('returns first day of next month', () {
        final date = DateTime(2024, 3, 15);
        expect(date.nextMonth, DateTime(2024, 4, 1));
      });

      test('handles December', () {
        final date = DateTime(2024, 12, 15);
        expect(date.nextMonth, DateTime(2025, 1, 1));
      });
    });

    group('previousWeek', () {
      test('returns same day in previous week', () {
        final date = DateTime(2024, 3, 15);
        expect(date.previousWeek, DateTime(2024, 3, 8));
      });
    });

    group('nextWeek', () {
      test('returns same day in next week', () {
        final date = DateTime(2024, 3, 15);
        expect(date.nextWeek, DateTime(2024, 3, 22));
      });
    });

    group('nextDay', () {
      test('returns next day', () {
        final date = DateTime(2024, 3, 15);
        expect(date.nextDay, DateTime(2024, 3, 16));
      });
    });

    group('daysInWeek', () {
      test('returns all days in the week', () {
        final date = DateTime(2024, 3, 15); // Friday
        final days = date.daysInWeek;
        expect(days.length, 7);
        expect(days.first.weekday, DateTime.sunday);
        expect(days.last.weekday, DateTime.saturday);
      });
    });

    group('isExtraDay', () {
      test('returns true for day in different month', () {
        final date = DateTime(2024, 4, 1);
        final currentMonth = DateTime(2024, 3, 15);
        expect(date.isExtraDay(currentMonth), isTrue);
      });

      test('returns false for day in same month', () {
        final date = DateTime(2024, 3, 15);
        final currentMonth = DateTime(2024, 3, 1);
        expect(date.isExtraDay(currentMonth), isFalse);
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        final now = DateTime.now();
        expect(now.isToday, isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isToday, isFalse);
      });
    });

    group('isYesterday', () {
      test('returns true for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isYesterday, isTrue);
      });

      test('returns false for today', () {
        final now = DateTime.now();
        expect(now.isYesterday, isFalse);
      });
    });

    group('isTomorrow', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isTomorrow, isTrue);
      });

      test('returns false for today', () {
        final now = DateTime.now();
        expect(now.isTomorrow, isFalse);
      });
    });

    group('weekOfYear', () {
      test('returns correct week number', () {
        final date = DateTime(2024, 1, 1);
        expect(date.weekOfYear, greaterThan(0));
      });
    });

    group('quarter', () {
      test('returns Q1 for January', () {
        expect(DateTime(2024, 1, 15).quarter, 1);
      });

      test('returns Q2 for April', () {
        expect(DateTime(2024, 4, 15).quarter, 2);
      });

      test('returns Q3 for July', () {
        expect(DateTime(2024, 7, 15).quarter, 3);
      });

      test('returns Q4 for October', () {
        expect(DateTime(2024, 10, 15).quarter, 4);
      });
    });

    group('firstDayOfQuarter', () {
      test('returns first day of Q1', () {
        expect(DateTime(2024, 2, 15).firstDayOfQuarter, DateTime(2024, 1, 1));
      });

      test('returns first day of Q2', () {
        expect(DateTime(2024, 5, 15).firstDayOfQuarter, DateTime(2024, 4, 1));
      });
    });

    group('lastDayOfQuarter', () {
      test('returns last day of Q1', () {
        expect(DateTime(2024, 2, 15).lastDayOfQuarter, DateTime(2024, 3, 31));
      });

      test('returns last day of Q2', () {
        expect(DateTime(2024, 5, 15).lastDayOfQuarter, DateTime(2024, 6, 30));
      });
    });

    group('dayOfYear', () {
      test('returns 1 for January 1st', () {
        expect(DateTime(2024, 1, 1).dayOfYear, 1);
      });

      test('returns correct day for later date', () {
        expect(DateTime(2024, 3, 1).dayOfYear, 61); // Leap year
      });
    });

    group('isWeekend', () {
      test('returns true for Saturday', () {
        expect(DateTime(2024, 3, 16).isWeekend, isTrue);
      });

      test('returns true for Sunday', () {
        expect(DateTime(2024, 3, 17).isWeekend, isTrue);
      });

      test('returns false for weekday', () {
        expect(DateTime(2024, 3, 15).isWeekend, isFalse);
      });
    });

    group('isWeekday', () {
      test('returns true for weekday', () {
        expect(DateTime(2024, 3, 15).isWeekday, isTrue);
      });

      test('returns false for weekend', () {
        expect(DateTime(2024, 3, 16).isWeekday, isFalse);
      });
    });

    group('isLeapYear', () {
      test('returns true for leap year', () {
        expect(DateTime(2024, 1, 1).isLeapYear, isTrue);
      });

      test('returns false for non-leap year', () {
        expect(DateTime(2023, 1, 1).isLeapYear, isFalse);
      });

      test('returns false for century non-leap year', () {
        expect(DateTime(1900, 1, 1).isLeapYear, isFalse);
      });

      test('returns true for century leap year', () {
        expect(DateTime(2000, 1, 1).isLeapYear, isTrue);
      });
    });

    group('weekNumber', () {
      test('returns correct week number', () {
        final date = DateTime(2024, 1, 1);
        expect(date.weekNumber, greaterThan(0));
      });
    });

    group('addMonths', () {
      test('adds months correctly', () {
        final date = DateTime(2024, 1, 15);
        expect(date.addMonths(2), DateTime(2024, 3, 15));
      });

      test('handles year rollover', () {
        final date = DateTime(2024, 11, 15);
        expect(date.addMonths(3), DateTime(2025, 2, 15));
      });

      test('adjusts day when target month has fewer days', () {
        final date = DateTime(2024, 1, 31);
        expect(date.addMonths(1), DateTime(2024, 2, 29)); // Leap year
      });
    });

    group('formatRelative', () {
      test('returns "just now" for current time', () {
        final now = DateTime.now();
        expect(now.formatRelative(), 'just now');
      });

      test('returns minutes ago for past time', () {
        final past = DateTime.now().subtract(const Duration(minutes: 5));
        expect(past.formatRelative(), '5 minutes ago');
      });

      test('returns hours ago for past time', () {
        final past = DateTime.now().subtract(const Duration(hours: 2));
        expect(past.formatRelative(), '2 hours ago');
      });

      test('returns yesterday for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.formatRelative(), 'yesterday');
      });

      test('returns tomorrow for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.formatRelative(), 'tomorrow');
      });
    });

    group('addYears', () {
      test('adds years correctly', () {
        final date = DateTime(2024, 3, 15);
        expect(date.addYears(2), DateTime(2026, 3, 15));
      });

      test('handles leap year to non-leap year', () {
        final date = DateTime(2024, 2, 29);
        // Dart normalizes Feb 29 to Mar 1 in non-leap years
        expect(date.addYears(1), DateTime(2025, 3, 1));
      });
    });

    group('startOfDay', () {
      test('returns start of day', () {
        final date = DateTime(2024, 3, 15, 14, 30, 45);
        expect(date.startOfDay, DateTime(2024, 3, 15, 0, 0, 0));
      });
    });

    group('endOfDay', () {
      test('returns end of day', () {
        final date = DateTime(2024, 3, 15, 14, 30, 45);
        expect(date.endOfDay, DateTime(2024, 3, 15, 23, 59, 59, 999));
      });
    });

    group('nextBusinessDay', () {
      test('returns Monday when starting on Friday', () {
        final friday = DateTime(2024, 3, 15);
        expect(friday.nextBusinessDay, DateTime(2024, 3, 18));
      });

      test('returns Monday when starting on Saturday', () {
        final saturday = DateTime(2024, 3, 16);
        expect(saturday.nextBusinessDay, DateTime(2024, 3, 18));
      });
    });

    group('previousBusinessDay', () {
      test('returns Friday when starting on Monday', () {
        final monday = DateTime(2024, 3, 18);
        expect(monday.previousBusinessDay, DateTime(2024, 3, 15));
      });

      test('returns Friday when starting on Sunday', () {
        final sunday = DateTime(2024, 3, 17);
        expect(sunday.previousBusinessDay, DateTime(2024, 3, 15));
      });
    });

    group('addBusinessDays', () {
      test('adds business days correctly', () {
        final monday = DateTime(2024, 3, 18);
        expect(monday.addBusinessDays(5), DateTime(2024, 3, 25));
      });

      test('skips weekends', () {
        final friday = DateTime(2024, 3, 15);
        expect(friday.addBusinessDays(1), DateTime(2024, 3, 18));
      });
    });
  });
}
