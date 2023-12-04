# Dependency Injection

## Motivation

The included `LocaleSettings` should be enough for most use cases.

In big projects, developers tend to use a dependency injection solution.

You can make use of that to increase code quality.

## Configuration

Please set the translation classes public:

```yaml
# Config
locale_handling: false # remove unused t variable, LocaleSettings, etc.
translation_class_visibility: public
```

## Usage

Call the `build` method in your enum to create a new translation instance of the desired locale.

If you have plurals, then you can also put your custom resolver into the `build` method.

Here is an example using the `riverpod` package.

```dart
final english = AppLocale.en.build();
final german = AppLocale.de.build();
final translationProvider = StateProvider<Translations>((ref) => german); // set it

// access the current instance
final t = ref.watch(translationProvider);
String a = t.welcome.title; // get translation
AppLocale locale = t.$meta.locale; // get locale

// initialize MaterialApp
MaterialApp(
  locale: ref.watch(translationProvider).$meta.locale.flutterLocale,
  supportedLocales: AppLocaleUtils.supportedLocales,
  localizationsDelegates: GlobalMaterialLocalizations.delegates, // from flutter_localizations package
  // ...
);
```

To make things easier, there are some utility functions in `AppLocaleUtils`.

```dart
// get locale as enum
AppLocale deviceLocale = AppLocaleUtils.findDeviceLocale();
AppLocale specificLocale = AppLocaleUtils.parse('en_US'); // handles '-' and '_'

// build instance
Translations translations = specificLocale.build();

// access instance
AppLocale locale = translations.$meta.locale;
String a = translations.welcome.title;
```
