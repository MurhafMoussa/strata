import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../config/localization_config_entity.dart';

/// Persistent Hydrated Cubit for localization and locale state management.
class LocalizationCubit({
  required this.config,
  Locale? initialLocale,
}) extends HydratedCubit<Locale> {
  this : super(
          initialLocale != null
              ? (config.findSupportedLocale(initialLocale) ?? config.defaultLocale)
              : config.defaultLocale,
        );

  final LocalizationConfigEntity config;

  static const Set<String> _rtlLanguages = {
    'ar',
    'fa',
    'he',
    'ur',
    'ps',
    'sd',
    'ug',
    'yi',
  };

  /// Whether current locale is right-to-left.
  bool get isRtl => _rtlLanguages.contains(state.languageCode.toLowerCase());

  /// Text direction for current locale.
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  List<LocalizationsDelegate<dynamic>> get delegates =>
      config.localizationsDelegates;
  List<Locale> get supportedLocales => config.supportedLocales;

  /// Resolves the device's system locale against [supportedLocales] with fallback to [defaultLocale].
  static Locale resolveDeviceLocale(
    LocalizationConfigEntity config, [
    Locale? deviceLocale,
  ]) {
    final candidate = deviceLocale ?? PlatformDispatcher.instance.locale;
    return config.findSupportedLocale(candidate) ?? config.defaultLocale;
  }

  Future<void> changeLanguage(Locale newLocale) async {
    final matched = config.findSupportedLocale(newLocale);
    if (matched == null) return;
    if (state == matched) return;
    emit(matched);
  }

  @override
  Locale? fromJson(Map<String, dynamic> json) {
    try {
      final languageCode = json['languageCode'] as String?;
      final countryCode = json['countryCode'] as String?;
      if (languageCode != null && languageCode.isNotEmpty) {
        final candidate = Locale(languageCode, countryCode);
        return config.findSupportedLocale(candidate);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(Locale state) {
    return {
      'languageCode': state.languageCode,
      'countryCode': state.countryCode,
    };
  }
}
