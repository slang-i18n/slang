# slang_flutter

This is a support package for [slang](https://pub.dev/packages/slang).

Import this package if you develop flutter apps.

```yaml
dependencies:
  slang: <version>
  slang_flutter: <version>
```

## RichText

This package enables RichText support.

## BuildContext translations

This package adds `BuildContext` integration to rebuild all widgets on locale change.

```dart
// get translation instance and mark this widget for rebuild on locale change
final t = Translations.of(context);

String a = t.myTranslation;
String b = context.t.myTranslation; // build-in extensions for BuildContext
```

## Additional API

Some useful methods provided by this package.

```dart
// use current device locale
LocaleSettings.useDeviceLocale();

// get current device locale
AppLocale locale = AppLocaleUtils.findDeviceLocale();

// get supported locales (handy for MaterialApp)
List<Locale> locales = AppLocaleUtils.supportedLocales;
```
