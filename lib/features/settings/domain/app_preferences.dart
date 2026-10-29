import 'package:flutter/material.dart';

class AppPreferences {
  const AppPreferences({
    this.languageCode,
    this.themeMode = ThemeMode.system,
    this.onboardingComplete = false,
  });
  final String? languageCode;
  final ThemeMode themeMode;
  final bool onboardingComplete;
  AppPreferences copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    bool? onboardingComplete,
  }) => AppPreferences(
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode ?? this.themeMode,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
  Map<String, Object?> toJson() => {
    'version': 1,
    'language': languageCode,
    'theme': themeMode.name,
    'onboarding': onboardingComplete,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) => AppPreferences(
    languageCode: ['ar', 'en'].contains(json['language'])
        ? json['language'] as String
        : null,
    themeMode:
        ThemeMode.values.where((v) => v.name == json['theme']).firstOrNull ??
        ThemeMode.system,
    onboardingComplete: json['onboarding'] == true,
  );
}
