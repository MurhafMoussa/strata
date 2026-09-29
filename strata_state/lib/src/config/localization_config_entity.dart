import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class const LocalizationConfigEntity({
  required final List<Locale> supportedLocales,
  required final List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required final Locale defaultLocale,
}) extends Equatable {

  /// Finds a supported locale matching the target locale, first checking exact
  /// match, then falling back to language code match (returning [target]).
  Locale? findSupportedLocale(Locale target) {
    for (final supported in supportedLocales) {
      if (supported == target) return supported;
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode.toLowerCase() ==
          target.languageCode.toLowerCase()) {
        return target;
      }
    }
    return null;
  }

  /// Checks if [locale] is supported either by exact match or language code match.
  bool isSupported(Locale locale) => findSupportedLocale(locale) != null;

  @override
  List<Object> get props => [
        supportedLocales,
        localizationsDelegates,
        defaultLocale,
      ];
}
