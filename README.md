# fast_i18n

Lightweight i18n solution. Use JSON files to create typesafe translations.

## Getting Started

### Step 1: Add dependencies

```yaml
dependencies:
  fast_i18n: ^0.0.1

dev_dependencies:
  build_runner: any
```

### Step 2: Create JSON files

Create these files inside your `lib` directory. Preferably in one common package like `lib/i18n`.

> messages.i18n.json

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

> messages_de.i18n.json

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

### Step 3: Generate the dart code

```
flutter packages pub run build_runner build
```

### Step 4: Use your translations

```dart

// raw string
String translated = t.hello(name: 'Tom');

// inside component
Text(t.login.success)
```

## API

When the dart code has been generated, you will see some useful classes and functions

`t` - the most important translate variable

`LocaleSettings.changeLocale('de')` - change the locale

`LocaleSettings.currentLocale` - get the current locale