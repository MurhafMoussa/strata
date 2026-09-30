import 'package:intl/intl.dart';

/// Extension methods on [String].
extension StrataStringExtensions on String {
  /// Tries to parse the string into a [DateTime] by testing multiple date formats.
  DateTime parseDate() {
    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('MM-dd-yyyy'),
      DateFormat('dd.MM.yyyy'),
      DateFormat('MMM dd, yyyy'),
      DateFormat('MMMM dd, yyyy'),
      DateFormat('EEE, MMM dd, yyyy'),
      DateFormat('EEE MMM dd, yyyy'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('yyyy.MM.dd'),
      DateFormat('yyyyMMdd'),
    ];

    for (final format in formats) {
      try {
        return format.parse(this);
      } catch (_) {}
    }
    throw FormatException('Unable to parse date: $this');
  }

  /// Returns `true` if all characters are equal.
  bool get isOneAKind {
    if (isEmpty) return false;
    final first = this[0];
    return runes.every((rune) => rune == first.codeUnitAt(0));
  }

  bool get isPassport => RegExp(r'^(?!^0+$)[a-zA-Z0-9]{6,9}$').hasMatch(this);

  bool get isNum => num.tryParse(this) is num;

  bool get isNumericOnly => RegExp(r'^\d+$').hasMatch(this);

  bool get isAlphabetOnly => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  bool get hasCapitalLetter => RegExp('[A-Z]').hasMatch(this);

  bool get isBool => this == 'true' || this == 'false';

  bool get isVideo {
    final ext = toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.wmv') ||
        ext.endsWith('.rmvb') ||
        ext.endsWith('.mpg') ||
        ext.endsWith('.mpeg') ||
        ext.endsWith('.3gp');
  }

  bool get isImage {
    final ext = toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.bmp');
  }

  bool get isAudio {
    final ext = toLowerCase();
    return ext.endsWith('.mp3') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.wma') ||
        ext.endsWith('.amr') ||
        ext.endsWith('.ogg');
  }

  bool get isPPT {
    final ext = toLowerCase();
    return ext.endsWith('.ppt') || ext.endsWith('.pptx');
  }

  bool get isWord {
    final ext = toLowerCase();
    return ext.endsWith('.doc') || ext.endsWith('.docx');
  }

  bool get isExcel {
    final ext = toLowerCase();
    return ext.endsWith('.xls') || ext.endsWith('.xlsx');
  }

  bool get isAPK => toLowerCase().endsWith('.apk');

  bool get isPDF => toLowerCase().endsWith('.pdf');

  bool get isTxt => toLowerCase().endsWith('.txt');

  bool get isChm => toLowerCase().endsWith('.chm');

  bool get isVector => toLowerCase().endsWith('.svg');

  bool get isHTML => toLowerCase().endsWith('.html');

  bool get isUsername =>
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.]+[a-zA-Z0-9]$').hasMatch(this);

  bool get isURL => RegExp(
    r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www\.|[a-zA-Z0-9]\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,7}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-]+))*$",
  ).hasMatch(this);

  bool get isEmail => RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  ).hasMatch(this);

  bool get isPhoneNumber {
    if (length > 16 || length < 9) return false;
    return RegExp(
      r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
    ).hasMatch(this);
  }

  bool get isDateTime {
    try {
      final parsedDate = DateTime.parse(this);
      final formattedDate =
          '${parsedDate.month}/${parsedDate.day}/${parsedDate.year}';
      return this == formattedDate;
    } catch (e) {
      return false;
    }
  }

  bool get isMD5 => RegExp(r'^[a-f0-9]{32}$').hasMatch(this);

  bool get isSHA1 => RegExp(
    r'(([A-Fa-f0-9]{2}\:){19}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{40})',
  ).hasMatch(this);

  bool get isSHA256 => RegExp(
    r'([A-Fa-f0-9]{2}\:){31}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{64}',
  ).hasMatch(this);

  bool get isSSN => RegExp(
    r'^(?!0{3}|6{3}|9[0-9]{2})[0-9]{3}-?(?!0{2})[0-9]{2}-?(?!0{4})[0-9]{4}$',
  ).hasMatch(this);

  bool get isBinary => RegExp(r'^[0-1]+$').hasMatch(this);

  bool get isIPv4 => RegExp(
    r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$',
  ).hasMatch(this);

  bool get isIPv6 => RegExp(
    r'^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$',
  ).hasMatch(this);

  bool get isHexadecimal =>
      RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(this);

  bool get isPalindrom {
    final cleanString = toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp('[^0-9a-zA-Z]+'), '');
    for (int i = 0; i < cleanString.length; i++) {
      if (cleanString[i] != cleanString[cleanString.length - i - 1]) {
        return false;
      }
    }
    return true;
  }

  bool hasMatch(String pattern) => RegExp(pattern).hasMatch(this);

  bool caseInsensitiveContains(String other) =>
      toLowerCase().contains(other.toLowerCase());

  bool caseInsensitiveContainsAny(String other) {
    final lowA = toLowerCase();
    final lowB = other.toLowerCase();
    return lowA.contains(lowB) || lowB.contains(lowA);
  }

  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();

  String get capitalizeAllWordsFirstLetter {
    final words = toLowerCase().trim().split(' ');
    if (words.isEmpty) return '';
    return words
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String get capitalizeFirstLettersOfFirstTwoWords {
    if (isEmpty) return '';
    final words = split(' ');
    final firstTwo = words.take(2);
    return firstTwo.map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
  }

  String get removeAllWhitespace => replaceAll(' ', '');

  String get camelCase {
    if (isEmpty) return this;
    final parts = split(RegExp(r'[!@#<>?":`~;[\]\\|=+)(*&^%-\s_]+'));
    if (parts.isEmpty) return this;
    final newString = parts
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
    return newString[0].toLowerCase() + newString.substring(1);
  }

  String camelCaseToLowerUnderscore() {
    final sb = StringBuffer();
    bool first = true;
    for (var rune in runes) {
      final char = String.fromCharCode(rune);
      if (char.toUpperCase() == char && !first) {
        if (char != '_') {
          sb.write('_');
        }
        sb.write(char.toLowerCase());
      } else {
        first = false;
        sb.write(char.toLowerCase());
      }
    }
    return sb.toString();
  }

  List<String> _groupIntoWords() {
    final RegExp upperAlphaRegex = RegExp('[A-Z]');
    final Set<String> symbolSet = {' ', '.', '/', '_', r'\', '-'};
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = toUpperCase() == this;
    for (int i = 0; i < length; i++) {
      final char = this[i];
      final nextChar = i + 1 == length ? null : this[i + 1];
      if (symbolSet.contains(char)) continue;
      sb.write(char);
      final isEndOfWord =
          nextChar == null ||
          (upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          symbolSet.contains(nextChar);
      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }
    return words;
  }

  String? snakeCase({String separator = '_'}) {
    if (trim().isEmpty) return null;
    final words = _groupIntoWords();
    return words.map((word) => word.toLowerCase()).join(separator);
  }

  String? get paramCase => snakeCase(separator: '-');

  String numericOnly({bool firstWordOnly = false}) {
    String numericOnlyStr = '';
    for (int i = 0; i < length; i++) {
      if (RegExp(r'\d').hasMatch(this[i])) {
        numericOnlyStr += this[i];
      }
      if (firstWordOnly && numericOnlyStr.isNotEmpty && this[i] == ' ') {
        break;
      }
    }
    return numericOnlyStr;
  }
}
