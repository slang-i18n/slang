![featured](resources/featured.svg)

# fast_i18n

Lightweight i18n solution. Use JSON files to create typesafe translations.

**For Flutter Web users:** version 3.0.4 contains the workaround for [#79555](https://github.com/flutter/flutter/issues/79555).
Version 4.x.x is web compatible as soon as the Flutter team merge this fix into the stable branch.

## Features

- 🚀 Minimal setup, create JSON files and get started! No configuration needed.
- 📦 Self-contained, you can remove this library after generation
- 🐞 Bug-resistant, no typos or missing arguments possible due to static checking
- ⚡ Fast, you get translations using native dart method calls, zero parsing!
- ⚙ Configurable, English is not the default language? Configure it in `build.yaml`!

You can see an example of the generated file [here](https://github.com/Tienisto/flutter-fast-i18n/blob/master/example/lib/i18n/strings.g.dart).

## Getting Started

**Step 1: Add dependencies**

```yaml
dependencies:
  fast_i18n: ^4.1.0

dev_dependencies:
  build_runner: any
```

**Step 2: Create JSON files**

Create these files inside your `lib` directory. Preferably in one common package like `lib/i18n`.
Only files having the `.i18n.json` file extension will be detected.
The part after the underscore `_` is the actual locale (e.g. en_US, en-US, fr).
You **must** provide the default translation file (the file without locale extension).

`strings.i18n.json (mandatory, default, fallback)`

```json
{
  "hello": "Hello $name",
  "save": "Save",
  "login": {
    "success": "Logged in successfully",
    "fail": "Logged in failed"
  }
}
```

`strings_de.i18n.json`

```json
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
flutter pub run build_runner build
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

```dart
MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LocaleSettings.supportedLocales, // <---
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
String a = t.login.success; // plain
String b = t.hello(name: 'Tom'); // with argument
String c = t.step[3]; // with index (for arrays)
String d = t.type['WARNING']; // with key (for maps)

// advanced
TranslationProvider(child: MyApp()); // wrap your app with TranslationProvider
// [...]
final t = Translations.of(context); // forces a rebuild on locale change
String translateAdvanced = t.hello(name: 'Tom');
```

## Configuration

All settings can be set in the `build.yaml` file. Place it in the root directory.

```yaml
targets:
  $default:
    builders:
      fast_i18n:i18nBuilder:
        options:
          base_locale: en
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_pattern: .g.dart
          translate_var: t
          enum_name: AppLocale
          translation_class_visibility: private
          key_case: snake
          maps:
            - a
            - b
            - c.d
```

Key|Type|Usage|Default
---|---|---|---
base_locale|`String`|locale of default json|`en`
input_directory|`String`|path to input directory|`null`
input_file_pattern|`String`|input file pattern|`.i18n.json`
output_directory|`String`|path to output directory|`null`
output_file_pattern|`String`|output file pattern|`.g.dart`
translate_var|`String`|translate variable name|`t`
enum_name|`String`|enum name|`AppLocale`
translation_class_visibility|`private`, `public`|class visibility|`private`
key_case|`camel`, `pascal`, `snake`|transform keys (optional)|`null`
maps|`List<String>`|entries which should be accessed via keys|`[]`

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

## FAQ

**How do I add arguments?**

Use the `$` prefix.

In edge cases you can also wrap it with `${...}`.

```json
{
  "greeting": "Hello $name",
  "distance": "${distance}m"
}
```

```dart
t.greeting(name: 'Tom'); // Hello Tom
t.distance(distance: 4.5); // 4.5m
```

**How can I access translations using string keys?**

Define the maps in your `build.yaml`. Each configuration item represents the translation tree separated by dots.

Keep in mind that all nice features like autocompletion are gone.

`strings.i18n.json`
```json
{
  "welcome": "Welcome",
  "thisIsAMap": {
    "hello world": "hello"
  },
  "notAMapParent": {
    "notAMap": "hello",
    "aMapInClass": {
      "hi": "hi"
    }
  }
}
```

`build.yaml`
```yaml
targets:
  $default:
    builders:
      fast_i18n:i18nBuilder:
        options:
          maps:
            - thisIsAMap
            - notAMapParent.aMapInClass
```

Now you can access the translations via keys:

```dart
String a = t.thisIsAMap['hello world'];
String b = t.notAMapParent.notAMap; // the "classical" way
String c = t.notAMapParent.aMapInClass['hi']; // nested
```

**Can I use lists?**

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

**Why I cannot rebuild i18n translations?**

For some reason, build_runner requires you to delete the old output.

````sh
flutter pub run build_runner build --delete-conflicting-outputs
````

**Why setLocale doesn't work?**

In most cases you forgot the `setState` call.

A more elegant solution is to use `TranslationProvider(child: MyApp())` and then get you translation variable with `final t = Translations.of(context)`.
It will automatically trigger a rebuild on `setLocale` for all affected widgets.

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
