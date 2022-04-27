import 'package:fast_i18n_dart/fast_i18n_dart.dart';
import 'package:flutter/widgets.dart';

extension ExtBaseAppLocale on BaseAppLocale {
  Locale get flutterLocale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }
}