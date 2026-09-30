import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('ValueTester', () {
    group('isNull', () {
      test('returns true for null', () {
        expect(ValueTester.isNull(null), isTrue);
      });

      test('returns false for non-null', () {
        expect(ValueTester.isNull('value'), isFalse);
        expect(ValueTester.isNull(0), isFalse);
        expect(ValueTester.isNull(''), isFalse);
      });
    });

    group('isNullOrBlank', () {
      test('returns true for null', () {
        expect(ValueTester.isNullOrBlank(null), isTrue);
      });

      test('returns true for empty string', () {
        expect(ValueTester.isNullOrBlank(''), isTrue);
      });

      test('returns true for whitespace-only string', () {
        expect(ValueTester.isNullOrBlank('   '), isTrue);
      });

      test('returns true for empty iterable', () {
        expect(ValueTester.isNullOrBlank([]), isTrue);
      });

      test('returns true for empty map', () {
        expect(ValueTester.isNullOrBlank({}), isTrue);
      });

      test('returns false for non-empty string', () {
        expect(ValueTester.isNullOrBlank('value'), isFalse);
      });

      test('returns false for non-empty iterable', () {
        expect(ValueTester.isNullOrBlank([1, 2]), isFalse);
      });

      test('returns false for non-empty map', () {
        expect(ValueTester.isNullOrBlank({'key': 'value'}), isFalse);
      });

      test('returns false for non-string non-iterable non-map', () {
        expect(ValueTester.isNullOrBlank(42), isFalse);
      });
    });

    group('isBlank', () {
      test('returns true for null', () {
        expect(ValueTester.isBlank(null), isTrue);
      });

      test('returns true for empty string', () {
        expect(ValueTester.isBlank(''), isTrue);
      });

      test('returns true for whitespace-only string', () {
        expect(ValueTester.isBlank('   '), isTrue);
      });

      test('returns true for empty iterable', () {
        expect(ValueTester.isBlank([]), isTrue);
      });

      test('returns true for empty map', () {
        expect(ValueTester.isBlank({}), isTrue);
      });

      test('returns false for non-empty string', () {
        expect(ValueTester.isBlank('value'), isFalse);
      });

      test('returns false for non-empty iterable', () {
        expect(ValueTester.isBlank([1, 2]), isFalse);
      });

      test('returns false for non-empty map', () {
        expect(ValueTester.isBlank({'key': 'value'}), isFalse);
      });

      test('returns false for non-string non-iterable non-map', () {
        expect(ValueTester.isBlank(42), isFalse);
      });
    });

    group('dynamicLength', () {
      test('returns null for null', () {
        expect(ValueTester.dynamicLength(null), isNull);
      });

      test('returns length for string', () {
        expect(ValueTester.dynamicLength('hello'), 5);
      });

      test('returns length for iterable', () {
        expect(ValueTester.dynamicLength([1, 2, 3]), 3);
      });

      test('returns length for map', () {
        expect(ValueTester.dynamicLength({'a': 1, 'b': 2}), 2);
      });

      test('returns string length for int', () {
        expect(ValueTester.dynamicLength(123), 3);
      });

      test('returns string length for double', () {
        expect(ValueTester.dynamicLength(12.3), 3);
      });

      test('returns null for other types', () {
        expect(ValueTester.dynamicLength(true), isNull);
      });
    });

    group('isLengthGreaterThan', () {
      test('returns true when length is greater', () {
        expect(ValueTester.isLengthGreaterThan('hello', 3), isTrue);
      });

      test('returns false when length is equal', () {
        expect(ValueTester.isLengthGreaterThan('hello', 5), isFalse);
      });

      test('returns false when length is less', () {
        expect(ValueTester.isLengthGreaterThan('hi', 3), isFalse);
      });

      test('returns false for null', () {
        expect(ValueTester.isLengthGreaterThan(null, 3), isFalse);
      });
    });

    group('isLengthGreaterOrEqual', () {
      test('returns true when length is greater', () {
        expect(ValueTester.isLengthGreaterOrEqual('hello', 3), isTrue);
      });

      test('returns true when length is equal', () {
        expect(ValueTester.isLengthGreaterOrEqual('hello', 5), isTrue);
      });

      test('returns false when length is less', () {
        expect(ValueTester.isLengthGreaterOrEqual('hi', 3), isFalse);
      });
    });

    group('isLengthLessThan', () {
      test('returns true when length is less', () {
        expect(ValueTester.isLengthLessThan('hi', 3), isTrue);
      });

      test('returns false when length is equal', () {
        expect(ValueTester.isLengthLessThan('hello', 5), isFalse);
      });

      test('returns false when length is greater', () {
        expect(ValueTester.isLengthLessThan('hello', 3), isFalse);
      });
    });

    group('isLengthLessOrEqual', () {
      test('returns true when length is less', () {
        expect(ValueTester.isLengthLessOrEqual('hi', 3), isTrue);
      });

      test('returns true when length is equal', () {
        expect(ValueTester.isLengthLessOrEqual('hello', 5), isTrue);
      });

      test('returns false when length is greater', () {
        expect(ValueTester.isLengthLessOrEqual('hello', 3), isFalse);
      });
    });

    group('isLengthEqualTo', () {
      test('returns true when length is equal', () {
        expect(ValueTester.isLengthEqualTo('hello', 5), isTrue);
      });

      test('returns false when length is not equal', () {
        expect(ValueTester.isLengthEqualTo('hello', 3), isFalse);
      });
    });

    group('isLengthBetween', () {
      test('returns true when length is between min and max', () {
        expect(ValueTester.isLengthBetween('hello', 3, 7), isTrue);
      });

      test('returns true when length equals min', () {
        expect(ValueTester.isLengthBetween('hi', 2, 5), isTrue);
      });

      test('returns true when length equals max', () {
        expect(ValueTester.isLengthBetween('hello', 3, 5), isTrue);
      });

      test('returns false when length is less than min', () {
        expect(ValueTester.isLengthBetween('hi', 3, 5), isFalse);
      });

      test('returns false when length is greater than max', () {
        expect(ValueTester.isLengthBetween('hello world', 3, 5), isFalse);
      });

      test('returns false for null', () {
        expect(ValueTester.isLengthBetween(null, 3, 5), isFalse);
      });
    });
  });
}
