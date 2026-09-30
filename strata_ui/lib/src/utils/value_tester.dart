abstract final class ValueTester {
  /// Checks if the given object is null.
  static bool isNull(dynamic value) => value == null;

  /// Checks if a String, Iterable, or Map is null or "blank".
  static bool isNullOrBlank(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable || value is Map) return value.isEmpty as bool;
    return false;
  }

  /// Checks if a String, Iterable, or Map is blank.
  static bool isBlank(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable || value is Map) return value.isEmpty as bool;
    return false;
  }

  /// Returns the length of the value if applicable.
  static int? dynamicLength(dynamic value) {
    if (value == null) return null;
    if (value is String || value is Iterable || value is Map) {
      return value.length as int?;
    }
    if (value is int) return value.toString().length;
    if (value is double) return value.toString().replaceAll('.', '').length;
    return null;
  }

  static bool isLengthGreaterThan(dynamic value, int maxLength) =>
      dynamicLength(value) != null ? dynamicLength(value)! > maxLength : false;

  static bool isLengthGreaterOrEqual(dynamic value, int maxLength) =>
      dynamicLength(value) != null ? dynamicLength(value)! >= maxLength : false;

  static bool isLengthLessThan(dynamic value, int maxLength) =>
      dynamicLength(value) != null ? dynamicLength(value)! < maxLength : false;

  static bool isLengthLessOrEqual(dynamic value, int maxLength) =>
      dynamicLength(value) != null ? dynamicLength(value)! <= maxLength : false;

  static bool isLengthEqualTo(dynamic value, int otherLength) =>
      dynamicLength(value) != null
      ? dynamicLength(value)! == otherLength
      : false;

  static bool isLengthBetween(dynamic value, int minLength, int maxLength) =>
      value != null &&
      isLengthGreaterOrEqual(value, minLength) &&
      isLengthLessOrEqual(value, maxLength);
}
