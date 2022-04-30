# Dependency Injection

## Motivation

The included `LocaleSettings` should be enough for most use cases.

In big projects, developers tend to use a dependency injection solution.

You can make use of that to increase code quality.

## Configuration

Please set the translation classes public:

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          translation_class_visibility: public
```

## Usage

Call the `build` method in your enum to create a new translation instance of the desired locale.

If you have plurals, then you can also put your custom resolver into the `build` method.

Here is an example using the `riverpod` package.

```dart
final english = AppLocale.en.build(cardinalResolver: myEnResolver);
final german = AppLocale.de.build(cardinalResolver: myDeResolver);
final translationProvider = StateProvider<StringsEn>((ref) => german); // set it

// access the current instance
final t = ref.watch(translationProvider);
String a = t.welcome.title;
```

To make things easier, there are some utility functions in `AppLocaleUtils`.

```dart
// get locale as enum
final AppLocale deviceLocale = AppLocaleUtils.findDeviceLocale();
final AppLocale specificLocale = AppLocaleUtils.parse('en_US');

// build instance
final StringsEn translations;
switch (specificLocale) { // exhaustive switch
  case AppLocale.en:
    translations = AppLocale.en.build(cardinalResolver: myEnResolver);
    // ...
}
```