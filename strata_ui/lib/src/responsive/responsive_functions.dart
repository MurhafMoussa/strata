import 'package:flutter/material.dart';

class ScreenBreakpoints {
  static const double mobile = 480;
  static const double tablet = 600;
  static const double largeTablet = 768;
  static const double desktop = 992;
  static const double largeDesktop = 1200;
}

T getValueForScreenType<T>({
  required BuildContext context,
  required T mobile,
  T? largeMobile,
  T? tablet,
  T? largeTablet,
  T? desktop,
  T? largeDesktop,
}) {
  final double width = MediaQuery.of(context).size.width;

  if (width >= ScreenBreakpoints.largeDesktop) {
    return _getValueWithFallback(
      largeDesktop,
      desktop,
      largeTablet,
      tablet,
      largeMobile,
      mobile,
    );
  } else if (width >= ScreenBreakpoints.desktop) {
    return _getValueWithFallback(
      desktop,
      largeTablet,
      tablet,
      largeMobile,
      mobile,
    );
  } else if (width >= ScreenBreakpoints.largeTablet) {
    return _getValueWithFallback(
      largeTablet,
      desktop,
      tablet,
      largeMobile,
      mobile,
    );
  } else if (width >= ScreenBreakpoints.tablet) {
    return _getValueWithFallback(
      tablet,
      largeTablet,
      desktop,
      largeMobile,
      mobile,
    );
  } else if (width >= ScreenBreakpoints.mobile) {
    return _getValueWithFallback(
      largeMobile,
      tablet,
      largeTablet,
      desktop,
      mobile,
    );
  } else {
    return mobile;
  }
}

T _getValueWithFallback<T>(
  T? primary,
  T? fallback1,
  T? fallback2,
  T? fallback3,
  T? fallback4, [
  T? fallback5,
]) {
  return primary ??
      fallback1 ??
      fallback2 ??
      fallback3 ??
      fallback4 ??
      (fallback5 as T);
}
