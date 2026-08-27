import 'package:flutter/foundation.dart';

class ChordsSettingsService extends ValueNotifier<bool> {
  static final ChordsSettingsService _instance = ChordsSettingsService._internal();
  static ChordsSettingsService get instance => _instance;

  ChordsSettingsService._internal() : super(false); // Defaults to false (turns off on every cold start)

  void setShowChordsAndShapes(bool enabled) {
    value = enabled;
  }
}
