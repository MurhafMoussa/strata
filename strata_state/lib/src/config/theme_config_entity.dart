import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeConfigEntity extends Equatable {
  const ThemeConfigEntity({
    required this.themeMode,
    required this.enableAutoSwitch,
  });

  factory ThemeConfigEntity.defaultConfig() => const ThemeConfigEntity(
        themeMode: ThemeMode.light,
        enableAutoSwitch: false,
      );

  final ThemeMode themeMode;
  final bool enableAutoSwitch;

  ThemeConfigEntity copyWith({
    ThemeMode? themeMode,
    bool? enableAutoSwitch,
  }) {
    return ThemeConfigEntity(
      themeMode: themeMode ?? this.themeMode,
      enableAutoSwitch: enableAutoSwitch ?? this.enableAutoSwitch,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'enableAutoSwitch': enableAutoSwitch,
      };

  factory ThemeConfigEntity.fromJson(Map<String, dynamic> json) {
    final modeName = json['themeMode'] as String?;
    final mode = ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.light,
    );
    return ThemeConfigEntity(
      themeMode: mode,
      enableAutoSwitch: json['enableAutoSwitch'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [themeMode, enableAutoSwitch];
}
