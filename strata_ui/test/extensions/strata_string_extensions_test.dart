import 'package:flutter_test/flutter_test.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataStringExtensions', () {
    group('parseDate', () {
      test('parses yyyy-MM-dd format', () {
        expect('2024-03-15'.parseDate(), DateTime(2024, 3, 15));
      });

      test('parses dd/MM/yyyy format', () {
        expect('15/03/2024'.parseDate(), DateTime(2024, 3, 15));
      });

      test('parses dd.MM.yyyy format', () {
        expect('15.03.2024'.parseDate(), DateTime(2024, 3, 15));
      });

      test('throws FormatException for invalid date', () {
        expect(() => 'not-a-date'.parseDate(), throwsFormatException);
      });
    });

    group('isOneAKind', () {
      test('returns true for string with all same characters', () {
        expect('aaaa'.isOneAKind, isTrue);
        expect('1111'.isOneAKind, isTrue);
      });

      test('returns false for empty string', () {
        expect(''.isOneAKind, isFalse);
      });

      test('returns false for string with different characters', () {
        expect('abcd'.isOneAKind, isFalse);
      });
    });

    group('isPassport', () {
      test('returns true for valid passport', () {
        expect('AB123456'.isPassport, isTrue);
        expect('A1234567'.isPassport, isTrue);
      });

      test('returns false for all zeros', () {
        expect('000000'.isPassport, isFalse);
      });

      test('returns false for too short', () {
        expect('A123'.isPassport, isFalse);
      });

      test('returns false for too long', () {
        expect('A1234567890'.isPassport, isFalse);
      });
    });

    group('isNum', () {
      test('returns true for valid number', () {
        expect('123'.isNum, isTrue);
        expect('12.5'.isNum, isTrue);
        expect('-5'.isNum, isTrue);
      });

      test('returns false for non-number', () {
        expect('abc'.isNum, isFalse);
      });
    });

    group('isNumericOnly', () {
      test('returns true for numeric string', () {
        expect('123'.isNumericOnly, isTrue);
      });

      test('returns false for non-numeric string', () {
        expect('12a'.isNumericOnly, isFalse);
      });
    });

    group('isAlphabetOnly', () {
      test('returns true for alphabetic string', () {
        expect('abc'.isAlphabetOnly, isTrue);
        expect('ABC'.isAlphabetOnly, isTrue);
      });

      test('returns false for non-alphabetic string', () {
        expect('abc1'.isAlphabetOnly, isFalse);
      });
    });

    group('hasCapitalLetter', () {
      test('returns true for string with capital letter', () {
        expect('Abc'.hasCapitalLetter, isTrue);
        expect('ABC'.hasCapitalLetter, isTrue);
      });

      test('returns false for string without capital letter', () {
        expect('abc'.hasCapitalLetter, isFalse);
      });
    });

    group('isBool', () {
      test('returns true for "true"', () {
        expect('true'.isBool, isTrue);
      });

      test('returns true for "false"', () {
        expect('false'.isBool, isTrue);
      });

      test('returns false for other strings', () {
        expect('yes'.isBool, isFalse);
      });
    });

    group('isVideo', () {
      test('returns true for video extensions', () {
        expect('video.mp4'.isVideo, isTrue);
        expect('video.avi'.isVideo, isTrue);
        expect('video.wmv'.isVideo, isTrue);
      });

      test('returns false for non-video extensions', () {
        expect('image.jpg'.isVideo, isFalse);
      });
    });

    group('isImage', () {
      test('returns true for image extensions', () {
        expect('image.jpg'.isImage, isTrue);
        expect('image.png'.isImage, isTrue);
        expect('image.gif'.isImage, isTrue);
      });

      test('returns false for non-image extensions', () {
        expect('video.mp4'.isImage, isFalse);
      });
    });

    group('isAudio', () {
      test('returns true for audio extensions', () {
        expect('audio.mp3'.isAudio, isTrue);
        expect('audio.wav'.isAudio, isTrue);
      });

      test('returns false for non-audio extensions', () {
        expect('image.jpg'.isAudio, isFalse);
      });
    });

    group('isPDF', () {
      test('returns true for pdf extension', () {
        expect('document.pdf'.isPDF, isTrue);
      });

      test('returns false for non-pdf extension', () {
        expect('document.doc'.isPDF, isFalse);
      });
    });

    group('isEmail', () {
      test('returns true for valid email', () {
        expect('test@example.com'.isEmail, isTrue);
        expect('user.name@domain.co.uk'.isEmail, isTrue);
      });

      test('returns false for invalid email', () {
        expect('not-an-email'.isEmail, isFalse);
        expect('@domain.com'.isEmail, isFalse);
      });
    });

    group('isURL', () {
      test('returns true for valid URL', () {
        expect('www.example.com'.isURL, isTrue);
      });

      test('returns false for invalid URL', () {
        expect('not-a-url'.isURL, isFalse);
      });
    });

    group('isUsername', () {
      test('returns true for valid username', () {
        expect('user_name'.isUsername, isTrue);
        expect('user.name'.isUsername, isTrue);
      });

      test('returns false for invalid username', () {
        expect('_username'.isUsername, isFalse);
        expect('user_'.isUsername, isFalse);
      });
    });

    group('isPhoneNumber', () {
      test('returns true for valid phone number', () {
        expect('+1234567890'.isPhoneNumber, isTrue);
        expect('123-456-7890'.isPhoneNumber, isTrue);
      });

      test('returns false for too short', () {
        expect('123'.isPhoneNumber, isFalse);
      });

      test('returns false for too long', () {
        expect('12345678901234567'.isPhoneNumber, isFalse);
      });
    });

    group('isMD5', () {
      test('returns true for valid MD5', () {
        expect('d41d8cd98f00b204e9800998ecf8427e'.isMD5, isTrue);
      });

      test('returns false for invalid MD5', () {
        expect('not-md5'.isMD5, isFalse);
      });
    });

    group('isSHA1', () {
      test('returns true for valid SHA1', () {
        expect('aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d'.isSHA1, isTrue);
      });

      test('returns false for invalid SHA1', () {
        expect('not-sha1'.isSHA1, isFalse);
      });
    });

    group('isSHA256', () {
      test('returns true for valid SHA256', () {
        expect(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
              .isSHA256,
          isTrue,
        );
      });

      test('returns false for invalid SHA256', () {
        expect('not-sha256'.isSHA256, isFalse);
      });
    });

    group('isSSN', () {
      test('returns true for valid SSN', () {
        expect('123-45-6789'.isSSN, isTrue);
      });

      test('returns false for invalid SSN', () {
        expect('000-00-0000'.isSSN, isFalse);
      });
    });

    group('isBinary', () {
      test('returns true for binary string', () {
        expect('101010'.isBinary, isTrue);
      });

      test('returns false for non-binary string', () {
        expect('102'.isBinary, isFalse);
      });
    });

    group('isIPv4', () {
      test('returns true for valid IPv4', () {
        expect('192.168.1.1'.isIPv4, isTrue);
        expect('10.0.0.1'.isIPv4, isTrue);
      });

      test('returns false for invalid IPv4', () {
        expect('256.1.1.1'.isIPv4, isFalse);
      });
    });

    group('isHexadecimal', () {
      test('returns true for valid hex color', () {
        expect('#FF5733'.isHexadecimal, isTrue);
        expect('FF5733'.isHexadecimal, isTrue);
        expect('#FFF'.isHexadecimal, isTrue);
      });

      test('returns false for invalid hex color', () {
        expect('GGGGGG'.isHexadecimal, isFalse);
      });
    });

    group('isPalindrom', () {
      test('returns true for palindrome', () {
        expect('racecar'.isPalindrom, isTrue);
        expect('A man a plan a canal Panama'.isPalindrom, isTrue);
      });

      test('returns false for non-palindrome', () {
        expect('hello'.isPalindrom, isFalse);
      });
    });

    group('hasMatch', () {
      test('returns true when pattern matches', () {
        expect('hello'.hasMatch(r'ell'), isTrue);
      });

      test('returns false when pattern does not match', () {
        expect('hello'.hasMatch(r'xyz'), isFalse);
      });
    });

    group('caseInsensitiveContains', () {
      test('returns true when contains (case insensitive)', () {
        expect('Hello World'.caseInsensitiveContains('hello'), isTrue);
      });

      test('returns false when does not contain', () {
        expect('Hello World'.caseInsensitiveContains('xyz'), isFalse);
      });
    });

    group('caseInsensitiveContainsAny', () {
      test('returns true when either contains the other', () {
        expect('Hello'.caseInsensitiveContainsAny('hello world'), isTrue);
        expect('Hello World'.caseInsensitiveContainsAny('hello'), isTrue);
      });

      test('returns false when neither contains the other', () {
        expect('Hello'.caseInsensitiveContainsAny('xyz'), isFalse);
      });
    });

    group('capitalize', () {
      test('capitalizes first letter and lowercases rest', () {
        expect('hello'.capitalize, 'Hello');
        expect('HELLO'.capitalize, 'Hello');
      });

      test('returns empty string for empty input', () {
        expect(''.capitalize, '');
      });
    });

    group('capitalizeAllWordsFirstLetter', () {
      test('capitalizes first letter of each word', () {
        expect('hello world'.capitalizeAllWordsFirstLetter, 'Hello World');
      });

      test('returns empty string for empty input', () {
        expect(''.capitalizeAllWordsFirstLetter, '');
      });
    });

    group('capitalizeFirstLettersOfFirstTwoWords', () {
      test('capitalizes first letters of first two words', () {
        expect('hello world'.capitalizeFirstLettersOfFirstTwoWords, 'HW');
      });

      test('returns empty string for empty input', () {
        expect(''.capitalizeFirstLettersOfFirstTwoWords, '');
      });
    });

    group('removeAllWhitespace', () {
      test('removes all spaces', () {
        expect('hello world'.removeAllWhitespace, 'helloworld');
      });
    });

    group('camelCase', () {
      test('converts to camelCase', () {
        expect('hello world'.camelCase, 'helloWorld');
        expect('Hello World'.camelCase, 'helloWorld');
      });

      test('returns empty string for empty input', () {
        expect(''.camelCase, '');
      });
    });

    group('camelCaseToLowerUnderscore', () {
      test('converts camelCase to lower underscore', () {
        expect('helloWorld'.camelCaseToLowerUnderscore(), 'hello_world');
      });
    });

    group('snakeCase', () {
      test('converts to snake_case', () {
        expect('HelloWorld'.snakeCase(), 'hello_world');
        expect('hello world'.snakeCase(), 'hello_world');
      });

      test('returns null for empty string', () {
        expect(''.snakeCase(), isNull);
      });
    });

    group('paramCase', () {
      test('converts to param-case', () {
        expect('HelloWorld'.paramCase, 'hello-world');
      });
    });

    group('numericOnly', () {
      test('extracts numeric characters', () {
        expect('abc123def456'.numericOnly(), '123456');
      });

      test('with firstWordOnly returns only first word numbers', () {
        expect('abc123 def456'.numericOnly(firstWordOnly: true), '123');
      });
    });
  });
}
