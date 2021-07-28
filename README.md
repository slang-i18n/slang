![featured](resources/featured.svg)

# fast_i18n

[![pub package](https://img.shields.io/pub/v/fast_i18n.svg)](https://pub.dev/packages/fast_i18n)
<a href="https://github.com/Solido/awesome-flutter">
   <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true" />
</a>
![ci](https://github.com/Tienisto/flutter-fast-i18n/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Lightweight i18n solution. Use JSON files to create typesafe translations.

**Latest version for projects without null safety:** 4.11.0

## About this library

- 🚀 Minimal setup, create JSON files and get started! No configuration needed.
- 📦 Self-contained, you can remove this library after generation.
- 🐞 Bug-resistant, no typos or missing arguments possible due to compiler errors.
- ⚡ Fast, you get translations using native dart method calls, zero parsing!
- 🔨 Configurable, English is not the default language? Configure it in `build.yaml`!

You can see an example of the generated file [here](https://github.com/Tienisto/flutter-fast-i18n/blob/master/example/lib/i18n/strings.g.dart).

This is how you access the translations:

```dart
final t = Translations.of(context); // optional, there is also a static getter without context

String a = t.mainScreen.title;                         // simple use case
String b = t.game.end.highscore(score: 32.6);          // with parameters
String c = t.items(count: 2);                          // with pluralization (using count)
String d = t.greet(name: 'Tom', context: Gender.male); // with custom context
String e = t.intro.step[4];                            // with index
String f = t.error.type['WARNING'];                    // with dynamic key
String g = t['mainScreen.title'];                      // with fully dynamic key
```

## Table of Contents

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Features](#features)
    - [Auto Rebuild](#auto-rebuild)
    - [String Interpolation](#string-interpolation)
    - [Linked Translations](#linked-translations)
    - [Locale Enum](#locale-enum)
    - [Pluralization](#pluralization)
    - [Custom Contexts](#custom-contexts)
    - [Maps](#maps)
    - [Dynamic Keys](#dynamic-keys)
    - [Lists](#lists)
    - [Fallback](#fallback)
- [API](#api)
- [FAQ](#faq)

## Getting Started

**Step 1: Add dependencies**

It is recommended to add `fast_i18n` to `dev_dependencies`.

```yaml
dev_dependencies:
  build_runner: any
  fast_i18n: 5.0.3
```

**Step 2: Create JSON files**

Create these files inside your `lib` directory. Preferably in one common package like `lib/i18n`.
Only files having the `.i18n.json` file extension will be detected.
The part after the underscore `_` is the actual locale (e.g. en_US, en-US, fr).
You **must** provide the default translation file (the file without locale extension).

```json5
// File: strings.i18n.json (mandatory, default, fallback)
{
  "hello": "Hello $name",
  "save": "Save",
  "login": {
    "success": "Logged in successfully",
    "fail": "Logged in failed"
  }
}
```

```json5
// File: strings_de.i18n.json
{
  "hello": "Hallo $name",
  "save": "Speichern",
  "login": {
    "success": "Login erfolgreich",
    "fail": "Login fehlgeschlagen"
  }
}
```

**Step 3: Generate the dart code**

```
flutter pub run fast_i18n
```
alternative (but slower):
```
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 4: Initialize**

a) use device locale
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // add this
  LocaleSettings.useDeviceLocale(); // and this
  runApp(MyApp());
}
```

b) use specific locale
```dart
@override
void initState() {
  super.initState();
  String storedLocale = loadFromStorage(); // your logic here
  LocaleSettings.setLocaleRaw(storedLocale);
}
```

**Step 4a: Override 'supportedLocales'**

This is optional but recommended.

Standard flutter controls (e.g. back button's tooltip) will also pick the right locale.

```yaml
# File: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations: # add this
    sdk: flutter
```

```dart
MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LocaleSettings.supportedLocales,
)
```

**Step 4b: iOS configuration**

```
File: ios/Runner/Info.plist

<key>CFBundleLocalizations</key>
<array>
   <string>en</string>
   <string>de</string>
</array>
```

**Step 5: Use your translations**

```dart
import 'package:my_app/i18n/strings.g.dart'; // import

String a = t.login.success; // get translation
```

## Configuration

This is **optional**. This library works without any configuration (in most cases).

For customization, you can create the `build.yaml` file. Place it in the root directory.

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          base_locale: fr
          fallback_strategy: base_locale
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_pattern: .g.dart
          translate_var: t
          enum_name: AppLocale
          translation_class_visibility: private
          key_case: snake
          string_interpolation: double_braces
          flat_map: false
          maps:
            - error.codes
            - category
            - iconNames
          pluralization:
            auto: cardinal
            cardinal:
              - someKey.apple
            ordinal:
              - someKey.place
          contexts:
            gender_context:
              enum:
                - male
                - female
              auto: false
              paths:
                - my.path.to.greet
```

Key|Type|Usage|Default
---|---|---|---
`base_locale`|`String`|locale of default json|`en`
`fallback_strategy`|`none`, `base_locale`|handle missing translations|`none`
`input_directory`|`String`|path to input directory|`null`
`input_file_pattern`|`String`|input file pattern|`.i18n.json`
`output_directory`|`String`|path to output directory|`null`
`output_file_pattern`|`String`|output file pattern|`.g.dart`
`translate_var`|`String`|translate variable name|`t`
`enum_name`|`String`|enum name|`AppLocale`
`translation_class_visibility`|`private`, `public`|class visibility|`private`
`key_case`|`camel`, `pascal`, `snake`|transform keys (optional)|`null`
`string_interpolation`|`dart`, `braces`, `double_braces`|string interpolation mode|`dart`
`flat_map`|`Boolean`|generate flat map|`true`
`maps`|`List<String>`|entries which should be accessed via keys|`[]`
`pluralization`/`auto`|`off`, `cardinal`, `ordinal`|detect plurals automatically|`cardinal`
`pluralization`/`cardinal`|`List<String>`|entries which have cardinals|`[]`
`pluralization`/`ordinal`|`List<String>`|entries which have ordinals|`[]`
`<context>`/`enum`|`List<String>`|context forms|no default
`<context>`/`auto`|`Boolean`|auto detect context|`true`
`<context>`/`paths`|`List<String>`|entries using this context|`[]`

## Features

### Auto Rebuild

You can let the library rebuild automatically for you.
The watch function from `build_runner` is **NOT** maintained.

Just run this command:

```sh
flutter pub run fast_i18n watch
```

### String Interpolation

There are three modes configurable via `string_interpolation` in `build.yaml`.

You can always escape them by adding a backslash, e.g. `\{notAnArgument}`.

Mode|JSON Entry|Call
---|---|---
`dart (default)`|`Hello $name. I am ${height}m.`|`t.myKey(name: 'Tom', height: 1.73)`
`braces`|`Hello {name}`|`t.myKey(name: 'Anna')`
`double_braces`|`Hello {{name}}`|`t.myKey(name: 'Tom')`

### Linked Translations

You can link one translation to another. Add the prefix `@:` followed by the translation key.

```json
{
  "meta": {
    "appName": "My App"
  },
  "welcome": "Welcome to @:meta.appName"
}
```

### Locale Enum

Typesafety is one of the main advantages of this library. No typos. Enjoy exhausted switch-cases!

```dart
// this enum is generated automatically for you
enum AppLocale {
  en,
  fr,
  zhCn,
}
```

```dart
// use cases
LocaleSettings.setLocale(AppLocale.en); // set locale
List<AppLocale> locales = AppLocale.values; // list all supported locales
Locale locale = AppLocale.en.flutterLocale; // convert to native flutter locale
String tag = AppLocale.en.languageTag; // convert to string tag (e.g. en-US)
final t = AppLocale.en.translations; // get translations of one locale
```

### Pluralization

This library uses the concept defined [here](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html).

Some languages have support out of the box. See [here](https://github.com/Tienisto/flutter-fast-i18n/blob/master/lib/src/model/pluralization_resolvers.dart).

Plurals are detected by the following keywords: `zero`, `one`, `two`, `few`, `many`, `other`.

You can access the `num count` but it is optional.

```json5
// File: strings.i18n.json
{
  "someKey": {
    "apple": {
      "one": "I have $count apple.",
      "other": "I have $count apples."
    }
  }
}
```

```dart
String a = t.someKey.apple(count: 1); // I have 1 apple.
String b = t.someKey.apple(count: 2); // I have 2 apples.
```

Plurals are interpreted as cardinals by default. You can configure or disable it.

```json5
// File: strings.i18n.json
{
  "someKey": {
    "apple": {
      "one": "I have $count apple.",
      "other": "I have $count apples."
    },
    "place": {
      "one": "${count}st place.",
      "two": "${count}nd place.",
      "few": "${count}rd place.",
      "other": "${count}th place."
    }
  }
}
```

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          pluralization:
            auto: off
            cardinal:
              - someKey.apple
            ordinal:
              - someKey.place
```

In case your language is not supported, you must provide a custom pluralization resolver:

```dart
// add this before you call the pluralization strings. Otherwise an exception will be thrown.
// you don't need to specify both
LocaleSettings.setPluralResolver(
  language: 'en',
  cardinalResolver: (num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
    if (n == 0)
      return zero ?? other!;
    if (n == 1)
      return one ?? other!;
    return other!;
  },
  ordinalResolver: (num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
    if (n % 10 == 1 && n % 100 != 11)
      return one ?? other!;
    if (n % 10 == 2 && n % 100 != 12)
      return two ?? other!;
    if (n % 10 == 3 && n % 100 != 13)
      return few ?? other!;
    return other!;
  },
);
```

### Custom Contexts

You can utilize custom contexts to differentiate between male and female forms.

```json5
// File: strings.i18n.json
{
  "greet": {
    "male": "Hello Mr $name",
    "female": "Hello Ms $name"
  }
}
```

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          contexts:
            gender_context:
              enum:
                - male
                - female
            polite_context:
              enum:
                - polite
                - rude
```

```dart
String a = t.greet(name: 'Maria', context: GenderContext.female);
```

Auto detection is on by default. You can disable auto detection. This may speed up build time.

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          contexts:
            gender_context:
              enum:
                - male
                - female
              auto: false # disable auto detection
              paths: # now you must specify paths manually
                - my.path.to.greet
```

In contrast to pluralization, you **must** provide all forms. Collapse it to save space.

```json5
// File: strings.i18n.json
{
  "greet": {
    "male,female": "Hello $name",
  }
}
```

### Maps

You can access each translation via string keys by defining maps.

Define the maps in your `build.yaml`. Each configuration item represents the translation tree separated by dots.

Keep in mind that all nice features like autocompletion are gone.

```json5
// File: strings.i18n.json
{
  "a": {
    "hello world": "hello"
  },
  "b": {
    "b0": "hey",
    "b1": {
      "hi there": "hi"
    }
  }
}
```

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          maps:
            - a
            - b.b1
```

Now you can access the translations via keys:

```dart
String a = t.a['hello world']; // "hello"
String b = t.b.b0; // "hey"
String c = t.b.b1['hi there']; // "hi"
```

### Dynamic Keys

A more general solution to [Maps](#maps).

It is supported out of the box. No configuration needed. Please use this sparingly.

```dart
String a = t['myPath.anotherPath'];
String b = t['myPath.anotherPath.3']; // with index for arrays
String c = t['myPath.anotherPath'](name: 'Tom'); // with arguments
```

### Lists

Lists are fully supported. No configuration needed. You can also put lists or maps inside lists!

```json
{
  "niceList": [
    "hello",
    "nice",
    [
      "first item in nested list",
      "second item in nested list"
    ],
    {
      "wow": "WOW!",
      "ok": "OK!"
    },
    {
      "a map entry": "access via key",
      "another entry": "access via second key"
    }
  ]
}
```

```dart
String a = t.niceList[1]; // "nice"
String b = t.niceList[2][0]; // "first item in nested list"
String c = t.niceList[3].ok; // "OK!"
String d = t.niceList[4]['a map entry']; // "access via key"
```

### Fallback

By default, you must provide all translations for all locales. Otherwise, you cannot compile it.

In case of rapid development, you can turn off this feature. Missing translations will fallback to base locale.

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          base_locale: en
          fallback_strategy: base_locale  # add this
```

```json5
// English
{
  "hello": "Hello",
  "bye": "Bye"
}
```

```json5
// French
{
  "hello": "Salut",
  // "bye" is missing, fallback to English version
}
```

## API                                                                                   
                                                                                         
When the dart code has been generated, you will see some useful classes and functions    
                                                                                         
`t` - the translate variable for simple translations                                     
                                                                                         
`Translations.of(context)` - translations which reacts to locale changes                 
                                                                                         
`TranslationProvider` - App wrapper, used for `Translations.of(context)`                 
                                                                                         
`LocaleSettings.useDeviceLocale()` - use the locale of the device                        
                                                                                         
`LocaleSettings.setLocale(AppLocale.en)` - change the locale                             
                                                                                         
`LocaleSettings.setLocaleRaw('de')` - change the locale                                  
                                                                                         
`LocaleSettings.currentLocale` - get the current locale                                  
                                                                                         
`LocaleSettings.baseLocale` - get the base locale                                        
                                                                                         
`LocaleSettings.supportedLocalesRaw` - get the supported locales                         
                                                                                         
`LocaleSettings.supportedLocales` - see step 4a                                          
                                                                                         
`LocaleSettings.setPluralResolver` - set pluralization resolver for unsupported languages

## FAQ

**Can I write the json files in the asset folder?**

Yes. Specify `input_directory` and `output_directory` in `build.yaml`.

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          input_directory: assets/i18n
          output_directory: lib/i18n
```

**Can I skip translations or use them from base locale?**

Yes. Please set `fallback_strategy: base_locale` in `build.yaml`.

Now you can leave out translations in secondary languages. Missing translations will fallback to base locale.

**Why setLocale doesn't work?**

In most cases you forgot the `setState` call.

A more elegant solution is to use `TranslationProvider(child: MyApp())` and then get you translation variable with `final t = Translations.of(context)`.
It will automatically trigger a rebuild on `setLocale` for all affected widgets.

**My plural resolver is not specified?**

An exception is thrown by `_missingPluralResolver` because you missed to add `LocaleSettings.setPluralResolver` for the specific language.

See [Pluralization](#pluralization).

**How does auto detection work?**

You can let the library detect plurals or contexts.

For plurals, it checks if any json node has `zero`, `one`, `two`, `few`, `many` or `other` as children.

As soon as an unknown item has been detected, then this json node is **not** a pluralization.

```json5
{
  "fake": {
    "one": "One apple",
    "two": "Two apples",
    "three": "Three apples" // unknown key word 'three', 'fake' is not a pluralization
  }
}
```

For contexts, all enum values must exist.

## License

MIT License

Copyright (c) 2020-2021 Tien Do Nam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
