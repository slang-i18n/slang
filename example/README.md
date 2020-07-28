# Example

## Step 1: Add dependencies

```yaml
dependencies:
  fast_i18n: ^1.2.0

dev_dependencies:
  build_runner: any
```

## Step 2: Create JSON files

Create these files inside your `lib` directory. Preferably in one common package like `lib/i18n`.

> strings.i18n.json

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

> strings_de.i18n.json

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

## Step 3: Generate the dart code

```
flutter packages pub run build_runner build
```

## Step 4: Initialize

```dart
@override
void initState() {
  super.initState();

  // a: use device locale
  LocaleSettings.useDeviceLocale().whenComplete(() {
    setState((){});
  });

  // b: use specific locale
  LocaleSettings.setLocale('de');

  // c: use default locale (default json locale)
  // *do nothing*
}
```

### Step 4b: iOS-only

```
File: ios/Runner/Info.plist

<key>CFBundleLocalizations</key>
<array>
   <string>en</string>
   <string>de</string>
</array>
```

## Step 5: Use your translations

```dart
// raw string
String translated = t.hello(name: 'Tom');

// inside component
Text(t.login.success)
```

## API

When the dart code has been generated, you will see some useful classes and functions

`t` - the most important translate variable

`LocaleSettings.useDeviceLocale()` - use the locale of the device

`LocaleSettings.setLocale('de')` - change the locale

`LocaleSettings.currentLocale` - get the current locale

## Additional features

### Maps

Sometimes you need to access the translations via keys.
A solution is to use a map. Add the `#map` as a key to enable this.
Keep in mind that you use it rarely because all nice features like autocompletion are gone.

```json
{
  "welcome": "Welcome",
  "thisIsAMap": {
    "#map": "", // value is not important here
    "hello world": "hello"
  },
  "classicClass": {
    "hello": "hello"
  }
}
```

Now you can access this via key:

```dart
String a = t.thisIsAMap['hello world'];
String b = t.classicClass.hello; // the "classical" way
```

### Lists

Lists are fully supported.

```json
{
  "niceList": [
    "hello",
    "nice",
    [
      "nestedList"
    ],
    {
      "wow": "wow"
    },
    {
      "#map": "",
      "cool": "cool"
    }
  ]
}
```

```dart
String a = t.niceList[1];
String b = t.niceList[3].wow;
String c = t.niceList[4]['cool'];
```