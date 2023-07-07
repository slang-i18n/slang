![featured](https://github.com/slang-i18n/slang/blob/main/resources/featured.svg)

![logo](https://github.com/slang-i18n/slang/blob/main/resources/logo.svg)

[![pub package](https://img.shields.io/pub/v/slang.svg)](https://pub.dev/packages/slang)
![ci](https://github.com/slang-i18n/slang/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Type-safe i18n solution using JSON, YAML or CSV files.

The official successor of [fast_i18n](https://pub.dev/packages/fast_i18n).

## About this library

- 🚀 Minimal setup, create JSON files and get started! No configuration needed.
- 🐞 Bug-resistant, no typos or missing arguments possible due to compile-time checking.
- ⚡ Fast, you get translations using native dart method calls, zero parsing!
- 📁 Organized, split large files into smaller ones via namespaces.
- 🔨 Configurable, English is not the default language? Configure it in `build.yaml`!

You can see an example of the generated file [here](https://github.com/slang-i18n/slang/blob/master/slang/example/lib/i18n/strings.g.dart).

This is how you access the translations:

```dart
final t = Translations.of(context); // there is also a static getter without context

String a = t.mainScreen.title;                         // simple use case
String b = t.game.end.highscore(score: 32.6);          // with parameters
String c = t.items(n: 2);                              // with pluralization
String d = t.greet(name: 'Tom', context: Gender.male); // with custom context
String e = t.intro.step[4];                            // with index
String f = t.error.type['WARNING'];                    // with dynamic key
String g = t['mainScreen.title'];                      // with fully dynamic key
TextSpan h = t.greet(name: TextSpan(text: 'Tom'));     // with RichText

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
  - [Changing Locale](#-changing-locale)
- [Complex Features](#complex-features)
  - [Linked Translations](#-linked-translations)
  - [Pluralization](#-pluralization)
  - [Custom Contexts / Enums](#-custom-contexts--enums)
  - [Interfaces](#-interfaces)
  - [Modifiers](#-modifiers)
  - [Locale Enum](#-locale-enum)
  - [Locale Stream](#-locale-stream)
  - [Translation Overrides](#-translation-overrides)
  - [Dependency Injection](#-dependency-injection)
- [Structuring Features](#structuring-features)
  - [Namespaces](#-namespaces)
  - [Output Format](#-output-format)
  - [Compact CSV](#-compact-csv)
- [Other Features](#other-features)
  - [Fallback](#-fallback)
  - [Comments](#-comments)
  - [Recasing](#-recasing)
  - [Obfuscation](#-obfuscation)
  - [Dart Only](#-dart-only)
- [Tools](#tools)
  - [Main Command](#-main-command)
  - [Analyze Translations](#-analyze-translations)
  - [Apply Translations](#-apply-translations)
  - [Edit Translations](#-edit-translations)
  - [Outdated Translations](#-outdated-translations)
  - [Migration](#-migration)
    - [ARB](#arb)
  - [Statistics](#-statistics)
  - [Auto Rebuild](#-auto-rebuild)
- [More Usages](#more-usages)
  - [Assets](#-assets)
  - [Unit Tests](#-unit-tests)
- [Integrations](#integrations)
  - [slang x riverpod](#-slang-x-riverpod)
- [FAQ](#faq)
- [Further Reading](#further-reading)
- [Apps built with slang](#apps-built-with-slang)

## Getting Started

Coming from ARB? There is a [tool](#arb) for that.

**Step 1: Add dependencies**

You will probably need at least 2 packages: [slang](https://pub.dev/packages/slang) and [slang_flutter](https://pub.dev/packages/slang_flutter).

```yaml
dependencies:
  slang: <version>
  slang_flutter: <version> # also add this if you use flutter

dev_dependencies:
  build_runner: <version> # ONLY if you use build_runner (1/2)
  slang_build_runner: <version> # ONLY if you use build_runner (2/2)
```

**Step 2: Create JSON files**

Format:
```text
<namespace>_<locale?>.<extension>
```

You can ignore the [namespace](#-namespaces) for this basic example, so just use a generic name like `strings`.

Most common i18n directories are `assets/i18n` and `lib/i18n`. (see [Assets](#-assets)).

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

Built-in:

```text
# Recommended during development. It runs much faster than build_runner.

dart run slang
```

Alternative (requires [slang_build_runner](https://pub.dev/packages/slang_build_runner)):

```text
# Useful for CI and initial git checkout.

dart run build_runner build -d
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
  supportedLocales: AppLocaleUtils.supportedLocales,
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

For customization, you can create a `slang.yaml` or a `build.yaml` file. Place it in the root directory.

<details>
  <summary>slang.yaml (Click to open example)</summary>

If you don't use `build_runner`, then you can define your config in `slang.yaml` for less boilerplate.

```yaml
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
translation_overrides: false
timestamp: true
maps:
  - error.codes
  - category
  - iconNames
pluralization:
  auto: cardinal
  default_parameter: n
  cardinal:
    - someKey.apple
  ordinal:
    - someKey.place
contexts:
  gender_context:
    enum:
      - male
      - female
    paths:
      - my.path.to.greet
    default_parameter: gender
    generate_enum: true
interfaces:
  PageData: onboarding.pages.*
  PageData2:
    paths:
      - my.path
      - cool.pages.*
    attributes:
      - String title
      - String? content
obfuscation:
  enabled: false
  secret: somekey
imports:
  - 'package:my_package/path_to_enum.dart'
```

</details>

<details>
  <summary>build.yaml (Click to open example)</summary>

Using `build.yaml` is **necessary** if you use `build_runner`. It has a higher compatibility as `dart run slang` also recognizes this file.

```yaml
targets:
  $default:
    builders:
      slang_build_runner:
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
          translation_overrides: false
          timestamp: true
          maps:
            - error.codes
            - category
            - iconNames
          pluralization:
            auto: cardinal
            default_parameter: n
            cardinal:
              - someKey.apple
            ordinal:
              - someKey.place
          contexts:
            gender_context:
              enum:
                - male
                - female
              paths:
                - my.path.to.greet
              default_parameter: gender
              generate_enum: true
          interfaces:
            PageData: onboarding.pages.*
            PageData2:
              paths:
                - my.path
                - cool.pages.*
              attributes:
                - String title
                - String? content
          obfuscation:
            enabled: false
            secret: somekey
          imports:
            - 'package:my_package/path_to_enum.dart'
```

</details>

| Key                                 | Type                               | Usage                                                        | Default       |
|-------------------------------------|------------------------------------|--------------------------------------------------------------|---------------|
| `base_locale`                       | `String`                           | locale of default json                                       | `en`          |
| `fallback_strategy`                 | `none`, `base_locale`              | handle missing translations [(i)](#-fallback)                | `none`        |
| `input_directory`                   | `String`                           | path to input directory                                      | `null`        |
| `input_file_pattern`                | `String`                           | input file pattern, must end with .json, .yaml or .csv       | `.i18n.json`  |
| `output_directory`                  | `String`                           | path to output directory                                     | `null`        |
| `output_file_name`                  | `String`                           | output file name                                             | `null`        |
| `output_format`                     | `single_file`, `multiple_files`    | split output files [(i)](#-output-format)                    | `single_file` |
| `locale_handling`                   | `Boolean`                          | generate locale handling logic [(i)](#-dependency-injection) | `true`        |
| `flutter_integration`               | `Boolean`                          | generate flutter features [(i)](#-dart-only)                 | `true`        |
| `namespaces`                        | `Boolean`                          | split input files [(i)](#-namespaces)                        | `false`       |
| `translate_var`                     | `String`                           | translate variable name                                      | `t`           |
| `enum_name`                         | `String`                           | enum name                                                    | `AppLocale`   |
| `translation_class_visibility`      | `private`, `public`                | class visibility                                             | `private`     |
| `key_case`                          | `null`, `camel`, `pascal`, `snake` | transform keys (optional) [(i)](#-recasing)                  | `null`        |
| `key_map_case`                      | `null`, `camel`, `pascal`, `snake` | transform keys for maps (optional) [(i)](#-recasing)         | `null`        |
| `param_case`                        | `null`, `camel`, `pascal`, `snake` | transform parameters (optional) [(i)](#-recasing)            | `null`        |
| `string_interpolation`              | `dart`, `braces`, `double_braces`  | string interpolation mode [(i)](#-string-interpolation)      | `dart`        |
| `flat_map`                          | `Boolean`                          | generate flat map [(i)](#-dynamic-keys--flat-map)            | `true`        |
| `translation_overrides`             | `Boolean`                          | enable translation overrides [(i)](#-translation-overrides)  | `false`       |
| `timestamp`                         | `Boolean`                          | write "Built on" timestamp                                   | `true`        |
| `maps`                              | `List<String>`                     | entries which should be accessed via keys [(i)](#-maps)      | `[]`          |
| `pluralization`/`auto`              | `off`, `cardinal`, `ordinal`       | detect plurals automatically [(i)](#-pluralization)          | `cardinal`    |
| `pluralization`/`default_parameter` | `String`                           | default plural parameter [(i)](#-pluralization)              | `n`           |
| `pluralization`/`cardinal`          | `List<String>`                     | entries which have cardinals                                 | `[]`          |
| `pluralization`/`ordinal`           | `List<String>`                     | entries which have ordinals                                  | `[]`          |
| `<context>`/`enum`                  | `List<String>`                     | DEPRECATED: context forms [(i)](#-custom-contexts--enums)    | no default    |
| `<context>`/`paths`                 | `List<String>`                     | DEPRECATED: entries using this context                       | `[]`          |
| `<context>`/`default_parameter`     | `String`                           | default parameter name                                       | `context`     |
| `<context>`/`generate_enum`         | `Boolean`                          | generate enum                                                | `true`        |
| `children of interfaces`            | `Pairs of Alias:Path`              | alias interfaces [(i)](#-interfaces)                         | `null`        |
| `obfuscation`/`enabled`             | `Boolean`                          | enable obfuscation [(i)](#-obfuscation)                      | `false`       |
| `obfuscation`/`secret`              | `String`                           | obfuscation secret (random if null) [(i)](#-obfuscation)     | `null`        |
| `imports`                           | `List<String>`                     | generate import statements                                   | `[]`          |

## Main Features

### ➤ File Types

Supported file types: `JSON (default)`, `YAML` and `CSV`.

To change to YAML or CSV, please modify `input_file_pattern`.

```yaml
# Config
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
# Config
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

You can add multiple styles to one translation.

To do this, please add the `(rich)` modifier.

Parameters are formatted according to `string_interpolation`.

Default text can be defined via brackets `(...)`, e.g. `underline(here)`.

```json
{
  "myText(rich)": "Welcome $name. Please click ${tapHere(here)}!"
}
```

Usage:

```dart
// Text.rich is a Flutter built-in feature!
Widget a = Text.rich(t.myText(
  // Show name in blue color
  name: TextSpan(text: 'Tom', style: TextStyle(color: Colors.blue)),
  
  // Turn 'here' into a link
  tapHere: (text) => TextSpan(
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

You can access each translation via string keys.

Add the `(map)` modifier.

```json5
// File: strings.i18n.json
{
  "a(map)": {
    "hello world": "hello"
  },
  "b": {
    "b0": "hey",
    "b1(map)": {
      "hi there": "hi"
    }
  }
}
```

For large projects with lots of locales, it may be better to specify them in the config file.

```yaml
# Config
maps: # Applies to all locales!
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

### ➤ Changing Locale

If you use the built-in `LocaleSettings` solution, then it is quite easy to change the locale.

| Method                           | Description                           | Platform      |
|----------------------------------|---------------------------------------|---------------|
| `LocaleSettings.setLocale`       | Set locale (type-safe)                | Dart, Flutter |
| `LocaleSettings.setLocaleRaw`    | Set locale (via string)               | Dart, Flutter |
| `LocaleSettings.useDeviceLocale` | Set to device locale and listen to it | Flutter only  |

The `TranslationProvider` listens to locale changes from the device.

- `LocaleSettings.useDeviceLocale` will enable the listener.
- `LocaleSettings.setLocale` and `LocaleSettings.setLocaleRaw` will disable the listener by default.

Widgets rebuild only if you use `final t = Translations.of(context)` or `context.t`.

## Complex Features

### ➤ Linked Translations

You can link one translation to another. Add the prefix `@:` followed by the **absolute** path of the desired translation.

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

If namespaces are used, then it has to be specified in the path too.

[RichTexts](#-richtext) can also contain links! But only [RichTexts](#-richtext) can link to [RichTexts](#-richtext).

### ➤ Pluralization

This library uses the concept defined [here](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html).

Some languages have support out of the box. See [here](https://github.com/slang-i18n/slang/blob/master/slang/lib/api/plural_resolver_map.dart).

Plurals are detected by the following keywords: `zero`, `one`, `two`, `few`, `many`, `other`.

```json5
// File: strings.i18n.json
{
  "someKey": {
    "apple": {
      "one": "I have $n apple.",
      "other": "I have $n apples."
    }
  }
}
```

```dart
String a = t.someKey.apple(n: 1); // I have 1 apple.
String b = t.someKey.apple(n: 2); // I have 2 apples.
```

The detected plurals are **cardinals** by default.

To specify ordinals, you need to add the `(ordinal)` modifier.

```json5
// File: strings.i18n.json
{
  "someKey": {
    "apple(cardinal)": {
      // cardinal
      "one": "I have $n apple.",
      "other": "I have $n apples."
    },
    "place(ordinal)": {
      // ordinal (rarely used)
      "one": "${n}st place.",
      "two": "${n}nd place.",
      "few": "${n}rd place.",
      "other": "${n}th place."
    }
  }
}
```

You can also specify all plural forms in the global config.

```yaml
# Config
pluralization: # Applies to all locales!
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
  locale: AppLocale.en,
  cardinalResolver: (n, {zero, one, two, few, many, other}) {
    if (n == 0)
      return zero ?? other!;
    if (n == 1)
      return one ?? other!;
    return other!;
  },
  ordinalResolver: (n, {zero, one, two, few, many, other}) {
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

By default, the parameter name is `n`. You can change that by adding a modifier.

```json
{
  "someKey": {
    "apple(param=appleCount)": {
      "one": "I have one apple.",
      "other": "I have multiple apples."
    }
  }
}
```

```dart
String a = t.someKey.apple(appleCount: 2); // notice 'appleCount' instead of 'n'
```

You can set the default parameter globally via `pluralization`/`default_parameter`.

### ➤ Custom Contexts / Enums

You can utilize custom contexts to differentiate between male and female forms (or other enums).

```json5
// File: strings.i18n.json
{
  "greet(context=GenderContext)": {
    "male": "Hello Mr $name",
    "female": "Hello Ms $name"
  }
}
```

The following enum will be generated for you:

```dart
enum GenderContext {
  male,
  female,
}
```

So you can use it like this:

```dart
String a = t.greet(name: 'Maria', context: GenderContext.female);
```

In contrast to pluralization, you **must** provide all forms. Collapse it to save space.

```json
{
  "greet(context=GenderContext)": {
    "male,female": "Hello $name"
  }
}
```

Similarly to plurals, the parameter name is `context` by default. You can change that by adding a modifier.

```json
{
  "greet(context=GenderContext, param=gender)": {
    "male": "Hello Mr",
    "female": "Hello Ms"
  }
}
```

```dart
String a = t.greet(gender: GenderContext.female); // notice 'gender' instead of 'context'
```

... or set it globally:

```yaml
# Config
contexts:
  GenderContext:
    default_parameter: gender # by default: "context"
```

You already have an existing enum? Import it instead!

```yaml
# Config
imports:
  - 'package:my_package/path_to_enum.dart' # define where your enum is
contexts:
  UserType:
    generate_enum: false # turn off enum generation
```

### ➤ Interfaces

Often, multiple objects have the same attributes. You can create a common super class for that.

Add the `(interface=<Interface Name>)` to the container node.

```json
{
  "onboarding": {
    "whatsNew(interface=ChangeData)": {
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

Alternatively, you can specify them in the global config:

```yaml
# Config
interfaces:
  ChangeData: onboarding.whatsNew.*
```

The following mixin will be generated automatically for you:

```dart
mixin ChangeData {
  String get title;
  List<String> get rows;
}
```

Now you can access these fields using polymorphism:

```dart
// before: without interfaces
void myOldFunction(dynamic changes) {
  List<String> rows = changes.rows as List<String>; // Not type-safe! Prone to typos!
}

// after: using interfaces
void myFunction(ChangeData changes) {
  List<String> rows = changes.rows; // Type-safe! No need to worry!
}

void main() {
  myFunction(t.onboarding.whatsNew.v2);
  myFunction(t.onboarding.whatsNew.v3);
}
```

You can customize the attributes and use different node selectors.

Checkout the [full article](https://github.com/slang-i18n/slang/blob/master/slang/documentation/interfaces.md).

### ➤ Modifiers

There are several modifiers for further adjustments.

You can combine multiple modifiers with commas like this:

```json
{
  "apple(plural, param=appleCount, rich)": {
    "one": "I have $appleCount apple.",
    "other": "I have $appleCount apples."
  }
}
```

Available Modifiers:

| Modifier                   | Meaning                                       | Applicable for                  |
|----------------------------|-----------------------------------------------|---------------------------------|
| `(rich)`                   | This is a rich text.                          | Leaves, Maps (Plural / Context) |
| `(map)`                    | This is a map / dictionary (and not a class). | Maps                            |
| `(plural)`                 | This is a plural (type: cardinal)             | Maps                            |
| `(cardinal)`               | This is a plural (type: cardinal)             | Maps                            |
| `(ordinal)`                | This is a plural (type: ordinal)              | Maps                            |
| `(context=<Context Type>)` | This is a context of type `<Context Type>`    | Maps                            |
| `(param=<Param Name>)`     | This has the parameter `<Param Name>`         | Maps (Plural / Context)         |
| `(interface=<I>)`          | Container of interfaces of type `I`           | Map/List containing Maps        |
| `(singleInterface=<I>)`    | This is an interface of type `I`              | Maps                            |

Analysis Modifiers (only used for the analysis tool):

| Modifier          | Meaning                                     | Applicable for |
|-------------------|---------------------------------------------|----------------|
| `(ignoreMissing)` | Ignore missing translations during analysis | All nodes      |
| `(ignoreUnused)`  | Ignore unused translations during analysis  | All nodes      |
| `(OUTDATED)`      | Flagged as outdated for secondary locales   | All nodes      |

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

### ➤ Locale Stream

You may want to track locale changes. Please use `LocaleSettings.getLocaleStream`.

```dart
LocaleSettings.getLocaleStream().listen((event) {
  print('locale changed: $event');
});
```

### ➤ Translation Overrides

You may want to update translations dynamically (e.g. via backend server over network).

Set the following configuration:

```yaml
# Config
translation_overrides: true
```

Example:

```dart
// override
LocaleSettings.overrideTranslations(
  locale: AppLocale.en,
  fileType: FileType.yaml,
  content: r'''
onboarding
  title: 'Welcome {name}'
  '''
);

// access
String a = t.onboarding.title(name: 'Tom'); // "Welcome Tom"
```

A few remarks:

1. New translations will be parsed but have no effect.
2. New parameters stay unparsed. (i.e. `{name}` stays `{name}`)
3. Missing translations will use translations **before** the override.
4. Overriding a second time reverts the last override.

### ➤ Dependency Injection

You don't like the included `LocaleSettings` solution?

Then you can use your own dependency injection solution!

Just create custom translation instances that don't depend on `LocaleSettings` or any other side effects.

First, set the following configuration:

```yaml
# Config
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
String a = t.welcome.title; // get translation
AppLocale locale = t.$meta.locale; // get locale
```

Checkout the [full article](https://github.com/slang-i18n/slang/blob/master/slang/documentation/dependency_injection.md).

## Structuring Features

### ➤ Namespaces

You can split the translations into multiple files. Each file represents a namespace.

This feature is disabled by default for single-file usage. You must enable it.

```yaml
# Config
namespaces: true # enable this feature
output_directory: lib/i18n # optional
output_file_name: translations.g.dart # set file name (mandatory)
```

Let's create two namespaces called `widgets` and `errorDialogs`. Please use camel case for multiple words.

```text
<namespace>_<locale?>.<extension>
```

```text
i18n/
 └── widgets.i18n.json
 └── widgets_fr.i18n.json
 └── errorDialogs.i18n.json <-- camel case for multiple words
 └── errorDialogs_fr.i18n.json
```

You can also use different folders. The namespace is only dependent on the file name!

```text
i18n/
 └── widgets/
      └── widgets.i18n.json
      └── widgets_fr.i18n.json
 └── errorDialogs/
      └── errorDialogs.i18n.json
      └── errorDialogs_fr.i18n.json
```

```text
i18n/
 └── en/
      └── widgets.i18n.json
      └── error_dialogs.i18n.json
 └── fr/
      └── widgets-fr.i18n.json
      └── error_dialogs.i18n.json <-- directory locale will be used
```

If you use directory locales, then you may use underscores as namespace.

Now access the translations:

```dart
// t.<namespace>.<path>
String a = t.widgets.welcomeCard.title;
String b = t.errorDialogs.login.wrongPassword;
```

### ➤ Output Format

By default, a single `.g.dart` file will be generated.

You can split this file into multiple ones to improve readability and IDE performance.

```yaml
# Config
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
# Config
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
  "my_map(map)": {
    "this_should_be_in_pascal": "hi"
  }
}
```

```yaml
# Config
key_case: camel
key_map_case: pascal
param_case: snake
```

```dart
String a = t.mustBeCamelCase(snake_case: 'nice');
String b = t.myMap['ThisShouldBeInPascal'];
```

If you specify paths in the config, please case them correctly:

```yaml
# Config
key_case: camel
maps:
   - myMap # all paths must be cased accordingly
```

### ➤ Obfuscation

Obfuscate the translation strings to make reverse engineering harder.

You should also enable [Flutter obfuscation](https://docs.flutter.dev/deployment/obfuscate) for additional security.

```yaml
# Config
obfuscation:
  enabled: true
  secret: somekey # set this if you want deterministic obfuscation
```

That's all. Everything should work like before.

Now, instead of this:

```dart
String get hello => 'Hello';
```

The following will be generated:

```dart
String get hello => _root.$meta.d([104, 69, 76, 76, 79]);
```

The secret key itself is hidden in the generated code.

XOR is used for encryption to keep your app (nearly) as fast as before.

Keep in mind that this only prevents simple string searches of the binary.

An experienced reverse engineer can still find the strings given enough time.

### ➤ Dart Only

You can use this library without flutter.

```yaml
# Config
flutter_integration: false # set this
```

## Tools

### ➤ Main Command

The main command to generate dart files from translation resources.

```sh
dart run slang
```

### ➤ Analyze Translations

You can use the slang analyzer to find missing and unused translations.

Missing translations only occur when `fallback_strategy: base_locale` is used.

```sh
dart run slang analyze [--split] [--full] [--outdir=assets/i18n]
```

| Argument          | Usage                                                  |
|-------------------|--------------------------------------------------------|
| `--split`         | Split analysis for each locale                         |
| `--split-missing` | Split missing translations for each locale             |
| `--split-unused`  | Split unused translations for each locale              |
| `--full`          | Find unused translations in whole source code          |
| `--outdir=<dir>`  | Path of analysis output (`input_directory` by default) |

Result file:

```json5
{
  "de": {
    "mainScreen": {
      "login": "This translation is missing, showing base translation here"
    }
  },
  "fr": {} // everything ok
}
```

You can ignore a specific node by adding an `(ignoreMissing)` or `(ignoreUnused)` modifier.

### ➤ Apply Translations

The follow-up command for `analyze`.

It reads the `_missing_translations` file and adds the translations to the original files.

Currently, only JSON and YAML are supported.

```sh
dart run slang apply [--locale=fr-FR] [--outdir=assets/i18n]
```

| Argument            | Usage                                                  |
|---------------------|--------------------------------------------------------|
| `--locale=<locale>` | Apply only one specific locale                         |
| `--outdir=<dir>`    | Path of analysis output (`input_directory` by default) |

### ➤ Edit Translations

You can use this command to rename, remove, or add translation keys. This is useful when you have many locales, or if you just want to use the command line.

```sh
dart run slang edit <type> <params...>
```

| Type        | Meaning              | Example                                                 |
|-------------|----------------------|---------------------------------------------------------|
| `add`       | Add a translation    | `dart run slang edit add fr greetings.hello "Bonjour"`  | 
| `move`      | Move a translation   | `dart run slang edit move loginPage authPage`           |
| `copy`      | Copy a translation   | `dart run slang edit copy loginPage authPage`           |
| `delete`    | Delete a translation | `dart run slang edit delete loginPage.title`            |
| `outdated`* | Add outdated flag    | `dart run slang edit outdated loginPage.title`          |

\* See [Outdated Translations](#-outdated-translations)

### ➤ Outdated Translations

You want to update an existing string, but you want to keep the old translations for other locales?

Here, you can run a simple command to flag translations as `OUTDATED`. They will show up in `_missing_translations` when running `analyze`.

```sh
dart run slang edit outdated a.b.c

# shorthand
dart run slang outdated a.b.c
```

This will add an `(OUTDATED)` modifier to all secondary locales.

```json5
{
  "a": {
    "b": {
      "c(OUTDATED)": "This translation is outdated"
    }
  }
}
```

You can also add these flags manually!

### ➤ Migration

There are some tools to make migration from other i18n solutions easier.

General migration syntax:

```sh
dart run slang migrate <type> <source> <destination>
```

#### ARB

Transforms ARB files to compatible JSON format. All descriptions are retained.

```sh
dart run slang migrate arb source.arb destination.json
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
        "count(param=count)": {
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
dart run slang stats
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
dart run slang watch
```

## More Usages

### ➤ Assets

You can write the i18n files wherever you want.

Specify `input_directory` and `output_directory` in `build.yaml`.

```yaml
targets:
  $default:
    sources:
      - "custom-directory/**" # optional; only assets/* and lib/* are scanned by build_runner
    builders:
      slang_build_runner:
        options:
          input_directory: assets/i18n
          output_directory: lib/i18n # defaulting to lib/gen if input is outside of lib/
```

... or in `slang.yaml`:

```yaml
input_directory: assets/i18n
output_directory: lib/i18n # defaulting to lib/gen if input is outside of lib/
```

### ➤ Unit Tests

It is recommended to add at least one test that accesses the translations to make sure that they are compiled correctly.

Because slang is type-safe, this test is most likely enough to ensure that the translations are working.

```dart
import 'package:my_app/gen/strings.g.dart';
import 'package:test/test.dart';

void main() {
  group('i18n', () {
    test('should compile', () {
      // The following test will fail if the i18n file is either not compiled
      // or there are compile-time errors.
      expect(AppLocale.en.build().aboutPage.title, 'About');
    });
  });
}
```

## Integrations

### ➤ slang x riverpod

**Method A: Use static getter**

Access translation variable `t` directly, use `LocaleSettings.setLocale` to change locales.

Track locale changes with `LocaleSettings.getLocaleStream()`:

```dart
final localeProvider = StreamProvider((ref) => LocaleSettings.getLocaleStream());
```

**Method B: Use dependency injection**

Checkout [Dependency Injection](https://github.com/slang-i18n/slang/blob/master/slang/documentation/dependency_injection.md).

## FAQ

**Translations don't update when device locale changes**

By default, this library does not listen to locale changes from device.

To enable this, either use `LocaleSettings.useDeviceLocale` or set `listenToDeviceLocale: true` when changing the locale.

Additionally, wrap your app with `TranslationProvider` and get the translations via `final t = Translations.of(context)`.

**CSV files are not parsed correctly**

Note that translated EOL should be written as `\n`.

CORRECT:

```csv
my.path,hello\nworld
```

WRONG:

```csv
my.path,hello<LF>
world
```

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
  "apples(param=appleCount)": {
    "one": "one apple",
    "other": "{appleCount} apples"
  },
  "bananas(param=bananaCount)": {
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

- [Interfaces](https://github.com/slang-i18n/slang/blob/master/slang/documentation/interfaces.md)
- [Dependency Injection](https://github.com/slang-i18n/slang/blob/master/slang/documentation/dependency_injection.md)

### Tutorials

**Blogs**

- [Medium (English)](https://medium.com/swlh/flutter-i18n-made-easy-1fd9ccd82cb3)
- [Хабр (Russian)](https://habr.com/ru/post/718310/)
- [Qiita (Japanese)](https://qiita.com/popy1017/items/3495be9fdc028161bef9)
- [okaryo (Japanese)](https://blog.okaryo.io/20230104-split-and-manage-arb-files-for-internationalized-flutter-app-in-yaml-format)
- [zenn (Japanese)](https://zenn.dev/flutteruniv_dev/articles/30cbf9a90442e1)
- [zenn (Japanese)](https://zenn.dev/flutteruniv_dev/articles/6be509f86c0fd7)

**Videos**

- [Youtube (Korean)](https://www.youtube.com/watch?v=4OqPlOm7UVo)
- [Youtube (Spanish)](https://www.youtube.com/watch?v=qRb8e-D860o)
- [Zhihu (Chinese)](https://www.zhihu.com/zvideo/1614731449386598400)

Feel free to extend this list :)

## Apps built with slang

Open source:

- [LocalSend (file sharing app)](https://github.com/localsend/localsend)
- [Saber (notes app)](https://github.com/adil192/saber)
- [Boorusphere (booru viewer)](https://github.com/nullxception/boorusphere)
- [Flutter Advanced Boilerplate (boilerplate project)](https://github.com/fikretsengul/flutter_advanced_boilerplate)

Closed source:

- Notan (grade calculator)

Feel free to extend this list :)

## License

MIT License

Copyright (c) 2020-2023 Tien Do Nam

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
