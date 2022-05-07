![featured](resources/featured.svg)

# slang

**[s]tructured [lan]guage file [g]enerator**

[![pub package](https://img.shields.io/pub/v/slang.svg)](https://pub.dev/packages/slang)
<a href="https://github.com/Solido/awesome-flutter">
   <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true" />
</a>
![ci](https://github.com/Tienisto/flutter-fast-i18n/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Type-safe i18n solution using JSON, YAML or CSV files.

The official successor of [fast_i18n](https://pub.dev/packages/fast_i18n).

## About this library

- 🚀 Minimal setup, create JSON files and get started! No configuration needed.
- 🐞 Bug-resistant, no typos or missing arguments possible due to compile-time checking.
- ⚡ Fast, you get translations using native dart method calls, zero parsing!
- 📁 Organized, split large files into smaller ones via namespaces.
- 🔨 Configurable, English is not the default language? Configure it in `build.yaml`!

You can see an example of the generated file [here](https://github.com/Tienisto/flutter-fast-i18n/blob/master/slang/example/lib/i18n/strings.g.dart).

This is how you access the translations:

```dart
final t = Translations.of(context); // there is also a static getter without context

String a = t.mainScreen.title;                         // simple use case
String b = t.game.end.highscore(score: 32.6);          // with parameters
String c = t.items(count: 2);                          // with pluralization
String d = t.greet(name: 'Tom', context: Gender.male); // with custom context
String e = t.intro.step[4];                            // with index
String f = t.error.type['WARNING'];                    // with dynamic key
String g = t['mainScreen.title'];                      // with fully dynamic key
InlineSpan h = t.greet(name: TextSpan(text: 'Tom'));   // with RichText

PageData page0 = t.onboarding.pages[0];                // with interfaces
PageData page1 = t.onboarding.pages[1];
String i = page1.title; // type-safe call
```

## Table of Contents

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Main Features](#main-features)
    - [File Types](#-file-types)
    - [String Interpolation](#-string-interpolation)
    - [RichText](#-richtext)
    - [Lists](#-lists)
    - [Maps](#-maps)
    - [Dynamic Keys](#-dynamic-keys--flat-map)
- [Complex Features](#complex-features)
  - [Linked Translations](#-linked-translations)
  - [Pluralization](#-pluralization)
  - [Custom Contexts](#-custom-contexts)
  - [Interfaces](#-interfaces)
  - [Locale Enum](#-locale-enum)
  - [Dependency Injection](#-dependency-injection)
- [Structuring Features](#structuring-features)
  - [Namespaces](#-namespaces)
  - [Output Format](#-output-format)
  - [Compact CSV](#-compact-csv)
- [Other Features](#other-features)
  - [Fallback](#-fallback)
  - [Comments](#-comments)
  - [Recasing](#-recasing)
  - [Dart Only](#-dart-only)
- [Tools](#tools)
  - [Main Command](#-main-command)
  - [Migration](#-migration)
    - [ARB](#arb)
  - [Statistics](#-statistics)
  - [Auto Rebuild](#-auto-rebuild)
- [FAQ](#faq)
- [Further Reading](#further-reading)

## Getting Started

It may be easier if you checkout [tutorials](#tutorials) in your language.

Coming from ARB? There is a [tool](#arb) for that.

**Step 1: Add dependencies**

```yaml
dependencies:
  slang: <latest version>
  slang_flutter: <latest version> # also add this if you use flutter

dev_dependencies:
  build_runner: any
```

**Step 2: Create JSON files**

Create these files inside your `lib` directory. For example, `lib/i18n`.

YAML and CSV files are also supported (see [File Types](#-file-types)).

Writing translations into assets folder requires extra configuration (see [FAQ](#faq)).

Format:
```text
<namespace>_<locale?>.<extension>
```

You can ignore the [namespace](#-namespaces) for this basic example, so just use a generic name like `strings` or `translations`.

Example:
```text
lib/
 └── i18n/
      └── strings.i18n.json
      └── strings_de.i18n.json
      └── strings_zh-CN.i18n.json <-- example for country code
```

```json5
// File: strings.i18n.json (mandatory, base locale)
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

```text
flutter pub run slang
```
alternative (but slower):
```text
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

c) use dependency injection (aka *"I handle it myself"*)

```dart
final english = AppLocale.en.build();
final german = AppLocale.de.build();

// read
String a = german.login.success;
```

You can ignore step 4a and 5 (but not 4b) if you handle the locale yourself.

**Step 4a: Flutter locale**

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
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TranslationProvider(child: MyApp())); // Wrap your app with TranslationProvider
}
```

```dart
MaterialApp(
  locale: TranslationProvider.of(context).flutterLocale, // use provider
  supportedLocales: LocaleSettings.supportedLocales,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  child: YourFirstScreen(),
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
      slang:
        options:
          base_locale: fr
          fallback_strategy: base_locale
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_name: translations.g.dart
          output_format: single_file
          locale_handling: true
          flutter_integration: true
          namespaces: false
          translate_var: t
          enum_name: AppLocale
          translation_class_visibility: private
          key_case: snake
          key_map_case: camel
          param_case: pascal
          string_interpolation: double_braces
          flat_map: false
          timestamp: true
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
          interfaces:
            PageData: onboarding.pages.*
            PageData2:
              paths:
                - my.path
                - cool.pages.*
              attributes:
                - String title
                - String? content
```

Key|Type|Usage|Default
---|---|---|---
`base_locale`|`String`|locale of default json|`en`
`fallback_strategy`|`none`, `base_locale`|handle missing translations [(i)](#-fallback)|`none`
`input_directory`|`String`|path to input directory|`null`
`input_file_pattern`|`String`|input file pattern, must end with .json, .yaml or .csv|`.i18n.json`
`output_directory`|`String`|path to output directory|`null`
`output_file_name`|`String`|output file name|`null`
`output_format`|`single_file`, `multiple_files`|split output files [(i)](#-output-format)|`single_file`
`locale_handling`|`Boolean`|generate locale handling logic [(i)](#-dependency-injection)|`true`
`flutter_integration`|`Boolean`|generate flutter features [(i)](#-dart-only)|`true`
`namespaces`|`Boolean`|split input files [(i)](#-namespaces)|`false`
`translate_var`|`String`|translate variable name|`t`
`enum_name`|`String`|enum name|`AppLocale`
`translation_class_visibility`|`private`, `public`|class visibility|`private`
`key_case`|`null`, `camel`, `pascal`, `snake`|transform keys (optional) [(i)](#-recasing)|`null`
`key_map_case`|`null`, `camel`, `pascal`, `snake`|transform keys for maps (optional) [(i)](#-recasing)|`null`
`param_case`|`null`, `camel`, `pascal`, `snake`|transform parameters (optional) [(i)](#-recasing)|`null`
`string_interpolation`|`dart`, `braces`, `double_braces`|string interpolation mode [(i)](#-string-interpolation)|`dart`
`flat_map`|`Boolean`|generate flat map [(i)](#-dynamic-keys--flat-map)|`true`
`timestamp`|`Boolean`|write "Built on" timestamp|`true`
`maps`|`List<String>`|entries which should be accessed via keys [(i)](#-maps)|`[]`
`pluralization`/`auto`|`off`, `cardinal`, `ordinal`|detect plurals automatically [(i)](#-pluralization)|`cardinal`
`pluralization`/`cardinal`|`List<String>`|entries which have cardinals|`[]`
`pluralization`/`ordinal`|`List<String>`|entries which have ordinals|`[]`
`<context>`/`enum`|`List<String>`|context forms [(i)](#-custom-contexts)|no default
`<context>`/`auto`|`Boolean`|auto detect context|`true`
`<context>`/`paths`|`List<String>`|entries using this context|`[]`
`children of interfaces`|`Pairs of Alias:Path`|alias interfaces [(i)](#-interfaces)|`null`

## Main Features

### ➤ File Types

Supported file types: `JSON (default)`, `YAML` and `CSV`.

To change to YAML or CSV, please modify `input_file_pattern`.

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      slang:
        options:
          input_directory: assets/i18n
          input_file_pattern: .i18n.yaml # must end with .json, .yaml or .csv
```

**JSON Example**
```json
{
  "welcome": {
    "title": "Welcome $name"
  }
}
```

**YAML Example**
```yaml
welcome:
  title: Welcome $name # some comment
```

**CSV Example**

You may also combine multiple locales into one CSV (see [Compact CSV](#-compact-csv)).

```csv
# Format: <key>, <translation>

welcome.title,Welcome $name
pages.0.title,First Page
pages.1.title,Second Page
```

### ➤ String Interpolation

Translations often have a dynamic parameter. There are multiple ways to define them.

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      slang:
        options:
          string_interpolation: dart # change to braces or double_braces
```

You can always escape them by adding a backslash, e.g. `\{notAnArgument}`.

**dart (default)**
```text
Hello $name. I am ${height}m.
```

**braces**
```text
Hello {name}
```

**double_braces**
```text
Hello {{name}}
```

### ➤ RichText

In Flutter environment, you can tell the library to generate `TextSpan` objects.

To do this, please add the `(rich)` hint.

```json
{
  "myText(rich)": "Welcome $name. Please click ${underline(here)}!"
}
```

Usage:

```dart
Text.rich(t.myText(
  name: TextSpan(text: 'Tom', style: TextStyle(color: Colors.blue)),
  underline: (text) => TextSpan(
    text: text,
    style: TextStyle(color: Colors.blue),
    recognizer: TapGestureRecognizer()..onTap=(){
      print('tap');
    },
  ),
));
```

### ➤ Lists

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

### ➤ Maps

You can access each translation via string keys by defining maps.

Define maps in your `build.yaml`.

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
      slang:
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

### ➤ Dynamic Keys / Flat Map

A more general solution to [Maps](#-maps). **ALL** translations are accessible via an one-dimensional map.

It is supported out of the box. No configuration needed.

This can be disabled globally by setting `flat_map: false`.

```dart
String a = t['myPath.anotherPath'];
String b = t['myPath.anotherPath.3']; // with index for arrays
String c = t['myPath.anotherPath'](name: 'Tom'); // with arguments
```

## Complex Features

### ➤ Linked Translations

You can link one translation to another. Add the prefix `@:` followed by the translation key.

```json
{
  "fields": {
    "name": "my name is {firstName}",
    "age": "I am {age} years old"
  },
  "introduce": "Hello, @:fields.name and @:fields.age"
}
```

```dart
String s = t.introduce(firstName: 'Tom', age: 27); // Hello, my name is Tom and I am 27 years old.
```

### ➤ Pluralization

This library uses the concept defined [here](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html).

Some languages have support out of the box. See [here](https://github.com/Tienisto/flutter-fast-i18n/blob/master/lib/src/model/pluralization_resolvers.dart).

Plurals are detected by the following keywords: `zero`, `one`, `two`, `few`, `many`, `other`.

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

The detected plurals are **cardinals** by default.

In general, you will probably use only this variant. Ordinals are rarely used.
If your project only has cardinals, then you don't need to configure anything! It works out of the box.

However, if you have ordinals, then you will need some configurations.

```json5
// File: strings.i18n.json
{
  "someKey": {
    "apple": {
      // cardinal
      "one": "I have $count apple.",
      "other": "I have $count apples."
    },
    "place": {
      // ordinal (rarely used)
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
      slang:
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

By default, the parameter name is `count`. You can change that by adding a hint.

```json
{
  "someKey": {
    "apple(appleCount)": {
      "one": "I have one apple.",
      "other": "I have multiple apples."
    }
  }
}
```

```dart
String a = t.someKey.apple(appleCount: 2); // notice 'appleCount' instead of 'count'
```

### ➤ Custom Contexts

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
      slang:
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
      slang:
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

```json
{
  "greet": {
    "male,female": "Hello $name"
  }
}
```

Similarly to plurals, the parameter name is `context` by default. You can change that by adding a hint.

```json
{
  "greet(gender)": {
    "male": "Hello Mr",
    "female": "Hello Ms"
  }
}
```

```dart
String a = t.greet(gender: GenderContext.female); // notice 'gender' instead of 'context'
```

### ➤ Interfaces

Often, multiple objects have the same attributes. You can create a common super class for that.

```json
{
  "onboarding": {
    "whatsNew": {
      "v2": {
        "title": "New in 2.0",
        "rows": [
          "Add sync"
        ]
      },
      "v3": {
        "title": "New in 3.0",
        "rows": [
          "New game modes",
          "And a lot more!"
        ]
      }
    }
  }
}
```

Here we know that all objects inside `whatsNew` have the same attributes. Let's name these objects `ChangeData`.

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      slang:
        options:
          interfaces:
            ChangeData: onboarding.whatsNew.*
```

This would create the following mixin:

```dart
mixin ChangeData {
  String get title;
  List<String> get rows;
}
```

Now you can access these fields by using polymorphism:

```dart
// before: without interfaces
void myOldFunction(dynamic changes) {
  String title = changes.title; // not type safe!
  List<String> rows = changes.rows; // prone to typos
}

// after: using interfaces
void myFunction(ChangeData changes) {
  String title = changes.title;
  List<String> rows = changes.rows;
}

void main() {
  myFunction(t.onboarding.whatsNew.v2);
  myFunction(t.onboarding.whatsNew.v3);
}
```

You can customize the attributes and use different node selectors.

Checkout the [full article](https://github.com/Tienisto/flutter-fast-i18n/blob/master/slang/documentation/interfaces.md).

### ➤ Locale Enum

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
// extension methods
Locale locale = AppLocale.en.flutterLocale; // to native flutter locale
String tag = AppLocale.en.languageTag; // to string tag (e.g. en-US)
final t = AppLocale.en.translations; // get translations of one locale
```

### ➤ Dependency Injection

You don't like the included `LocaleSettings` solution?

Then you can use your own dependency injection solution!

Just create custom translation instances that don't depend on `LocaleSettings` or any other side effects.

First, set the following configuration:

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      slang:
        options:
          locale_handling: false # remove unused t variable, LocaleSettings, etc.
          translation_class_visibility: public
```

Example using the `riverpod` library:

```dart
final english = AppLocale.en.build(cardinalResolver: myEnResolver);
final german = AppLocale.de.build(cardinalResolver: myDeResolver);
final translationProvider = StateProvider<StringsEn>((ref) => german); // set it

// access the current instance
final t = ref.watch(translationProvider);
String a = t.welcome.title;
```

Checkout the [full article](https://github.com/Tienisto/flutter-fast-i18n/blob/master/slang/documentation/dependency_injection.md).

## Structuring Features

### ➤ Namespaces

You can split the translations into multiple files. Each file represents a namespace.

This feature is disabled by default for single-file usage. You must enable it.

```yaml
# File: build.yaml
targets:
  $default:
    builders:
      slang:
        options:
          namespaces: true # enable this feature
          output_directory: lib/i18n # optional
          output_file_name: translations.g.dart # set file name (mandatory)
```

Let's create two namespaces called `widgets` and `dialogs`.

```text
<namespace>_<locale?>.<extension>
```

```text
i18n/
 └── widgets.i18n.json
 └── widgets_fr.i18n.json
 └── dialogs.i18n.json
 └── dialogs_fr.i18n.json
```

You can also use different folders. Only file name matters!

```text
i18n/
 └── widgets/
      └── widgets.i18n.json
      └── widgets_fr.i18n.json
 └── dialogs/
      └── dialogs.i18n.json
      └── dialogs_fr.i18n.json
```

```text
i18n/
 └── en/
      └── widgets.i18n.json
      └── dialogs.i18n.json
 └── fr/
      └── widgets_fr.i18n.json
      └── dialogs_fr.i18n.json
```

Now access the translations:

```dart
// t.<namespace>.<path>
String a = t.widgets.welcomeCard.title;
String b = t.dialogs.logout.title;
```

### ➤ Output Format

By default, a single `.g.dart` file will be generated.

You can split this file into multiple ones to improve readability and IDE performance.

```yaml
targets:
  $default:
    builders:
      slang:
        options:
          output_file_name: translations.g.dart
          output_format: multiple_files # set this
```

This will generate the following files:

```text
lib/
 └── i18n/
      └── translations.g.dart <-- main file
      └── translations_en.g.dart <-- translation classes
      └── translations_de.g.dart <-- translation classes
      └── ...
      └── translations_map.g.dart <-- translations stored in flat maps
```

You only need to import the main file!

### ➤ Compact CSV

Normally, you would create a new csv file for each locale:
`strings.i18n.csv`, `strings_fr.i18n.csv`, etc.

You can also merge multiple locales into one single csv file! To do this,
you need at least 3 columns. The first row contains the locale names. This library should detect that, so no configuration is needed.

Comments are supported. (see [Comments](#-comments))

```csv
     ,locale_0 ,locale_1 , ... ,locale_n
key_0,string_00,string_01, ... ,string_0n
key_1,string_10,string_11, ... ,string_1n
...
key_m,string_m0,string_m1, ... ,string_mn
```

Example:
```csv
key,en,de-DE
welcome.title,Welcome $name,Willkommen $name
welcome.button,Start,Start
```

```text
assets/
 └── i18n/
      └── strings.i18n.csv <-- contains all locales
```

## Other Features

### ➤ Fallback

By default, you must provide all translations for all locales. Otherwise, you cannot compile it.

In case of rapid development, you can turn off this feature. Missing translations will fallback to base locale.

```yaml
targets:
  $default:
    builders:
      slang:
        options:
          base_locale: en
          fallback_strategy: base_locale # add this
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

### ➤ Comments

You can add comments in your translation files.

**JSON**

All keys starting with `@` will be ignored.

If a `@key` key matches an existing key, then its value will be rendered as a comment.

```json5
{
  "@@locale": "en", // fully ignored
  "mainScreen": {
    "button": "Submit",

    // ignored as translation but rendered as a comment
    "@button": "The submit button shown at the bottom",
    
    // ARB style is also possible, the description will be rendered as a comment
    "@button2": {
      "context": "HomePage",
      "description": "The submit button shown at the bottom"
    },
  }
}
```

**YAML**

Currently, not parsed and no comments will be generated.

```yaml
mainScreen:
  button: Submit # The submit button shown at the bottom
```

**CSV**

Columns with parentheses like `(my_column)` are ignored.

Values in the first column with parentheses will be rendered as a comment.

```csv
key,(comment),en,de,(ignored comment)
mainScreen.button,The submit button shown at the bottom,Submit,Bestätigen,fully ignored
mainScreen.content,,Content,Inhalt,
```

**Generated File**

```dart
/// The submit button shown at the bottom
String get button => 'Submit';
```

### ➤ Recasing

By default, no transformations will be applied.

You can change that by specifying `key_case`, `key_map_case` or `param_case`.

Possible cases are: `camel`, `snake` and `pascal`.

```json
{
  "must_be_camel_case": "The parameter is in {snakeCase}",
  "my_map": {
    "this_should_be_in_pascal": "hi"
  }
}
```

```yaml
targets:
  $default:
    builders:
      slang:
        options:
          key_case: camel
          key_map_case: pascal
          param_case: snake
          maps:
            - myMap # all paths must be cased accordingly
```

```dart
String a = t.mustBeCamelCase(snake_case: 'nice');
String b = t.myMap['ThisShouldBeInPascal'];
```

### ➤ Dart Only

You can use this library without flutter.

```yaml
targets:
  $default:
    builders:
      slang:
        options:
          flutter_integration: false # set this
```

## Tools

### ➤ Main Command

The main command to generate dart files from translation resources.

```sh
flutter pub run slang
```

### ➤ Migration

There are some tools to make migration from other i18n solutions easier.

General migration syntax:

```sh
flutter pub run slang:migrate <type> <source> <destination>
```

#### ARB

Transforms ARB files to compatible JSON format. All descriptions are retained.

```sh
flutter pub run slang:migrate arb source.arb destination.json
```

ARB Input
```json
{
  "@@locale": "en_US",
  "@@context": "HomePage",
  "title_bar": "My Cool Home",
  "@title_bar": {
    "type": "text",
    "context": "HomePage",
    "description": "Page title."
  },
  "FOO_123": "Your pending cost is {COST}",
  "foo456": "Hello {0}",
  "pageHomeInboxCount" : "{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}",
  "@pageHomeInboxCount" : {
    "placeholders": {
      "count": {}
    }
  }
}
```

JSON Result
```json
{
  "@@locale": "en_US",
  "@@context": "HomePage",
  "title": {
    "bar": "My Cool Home",
    "@bar": "Page title."
  },
  "foo123": "Your pending cost is {cost}",
  "foo456": "Hello {arg0}",
  "page": {
    "home": {
      "inbox": {
        "count(count)": {
          "zero": "You have no new messages",
          "one": "You have 1 new message",
          "other": "You have {count} new messages"
        }
      }
    }
  }
}
```

### ➤ Statistics

There is a command to quickly get the number of words, characters, etc.

```sh
flutter pub run slang:stats
```

Example console output:

```text
[en]
 - 9 keys (including intermediate keys)
 - 6 translations (leaves only)
 - 15 words
 - 82 characters (ex. [,.?!'¿¡])
```

### ➤ Auto Rebuild

You can let the library rebuild automatically for you.
The watch function from `build_runner` is **NOT** maintained.

```sh
flutter pub run slang:watch
```

## FAQ

**Can I write the json files in the asset folder?**

Yes. Specify `input_directory` and `output_directory` in `build.yaml`.

```yaml
targets:
  $default:
    sources:
      - "custom-directory/**" # optional; only assets/* and lib/* are scanned by build_runner
    builders:
      slang:
        options:
          input_directory: assets/i18n
          output_directory: lib/i18n
```

**Can I skip translations or use them from base locale?**

Yes. Please set `fallback_strategy: base_locale` in `build.yaml`.

Now you can leave out translations in secondary languages. Missing translations will fallback to base locale.

**Can I prevent the timestamp `Built on` from updating?**

No, but you can disable the timestamp altogether. Set `timestamp: false` in `build.yaml`.

**Why setLocale doesn't work?**

In most cases, you forgot the `setState` call.

A more elegant solution is to use `TranslationProvider(child: MyApp())` and then get your translation variable with `final t = Translations.of(context)`.
It will automatically trigger a rebuild on `setLocale` for all affected widgets.

**My plural resolver is not specified?**

An exception is thrown by `_missingPluralResolver` because you missed to add `LocaleSettings.setPluralResolver` for the specific language.

See [Pluralization](#-pluralization).

**How does plural / context detection work?**

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

**How can I use multiple plurals in one sentence?**

You may use linked translations to solve this problem.

```json
{
  "apples(appleCount)": {
    "one": "one apple",
    "other": "{appleCount} apples"
  },
  "bananas(bananaCount)": {
    "one": "one banana",
    "other": "{bananaCount} bananas"
  },
  "sentence": "I have @:apples and @:bananas"
}
```

```dart
String a = t.sentence(appleCount: 1, bananaCount: 2); // two different plural parameters!
```

**What's the difference between `AppLocale.en.translations` and `AppLocale.en.build()`?**

The plural resolvers of `AppLocale.<locale>.translations` must be set via `LocaleSettings.setPluralResolver`.
Therefore, calls on `LocaleSettings` has side effects on `AppLocale.<locale>.translations`.

When you call `AppLocale.<locale>.build()`, there are no side effects.

Furthermore, the first method returns the instance managed by this library.
The second one always returns a new instance.

## Further Reading

### In Depth

[Interfaces](https://github.com/Tienisto/flutter-fast-i18n/blob/master/slang/documentation/interfaces.md)

[Dependency Injection](https://github.com/Tienisto/flutter-fast-i18n/blob/master/slang/documentation/dependency_injection.md)

### Tutorials

[Medium (English)](https://medium.com/swlh/flutter-i18n-made-easy-1fd9ccd82cb3)

[Qiita (Japanese)](https://qiita.com/popy1017/items/3495be9fdc028161bef9)

[Youtube (Korean)](https://www.youtube.com/watch?v=4OqPlOm7UVo)

Feel free to extend this list :)

## License

MIT License

Copyright (c) 2020-2022 Tien Do Nam

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
