# Slang Advanced Features — Complete Reference

This document covers every advanced feature beyond basic key-value translation.
For each feature, see the syntax guide and usage examples.

## Contents

- [Pluralization](#pluralization)
- [Custom Contexts / Enums](#custom-contexts--enums)
- [RichText](#richtext)
- [Linked Translations](#linked-translations)
- [Interfaces](#interfaces)
- [Typed Parameters](#typed-parameters)
- [L10n Formatting (Numbers & Dates)](#l10n-formatting-numbers--dates)
- [Lists & Nested Structures](#lists--nested-structures)
- [Dynamic Maps](#dynamic-maps)
- [Namespaces](#namespaces)
- [Region Extensions](#region-extensions)
- [Wildcard Locales](#wildcard-locales)
- [Translation Overrides](#translation-overrides)
- [Dependency Injection (Riverpod)](#dependency-injection-riverpod)
- [Modifiers Reference](#modifiers-reference)

## Pluralization

Plurals follow the [CLDR plural rules](https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html).

**Auto-detection:** When JSON contains the reserved keys `zero`, `one`, `two`,
`few`, `many`, or `other`, slang treats the entry as a plural.

```json
{
  "items": {
    "one": "$n item",
    "other": "$n items"
  }
}
```

```dart
t.items(n: 1);  // "1 item"
t.items(n: 5);  // "5 items"
```

**Ordinals:** Add the `(ordinal)` modifier (rare usage):

```json
{
  "place(ordinal)": {
    "one": "${n}st place",
    "two": "${n}nd place",
    "few": "${n}rd place",
    "other": "${n}th place"
  }
}
```

**Custom parameter name:**

```json
{
  "apple(param=appleCount)": {
    "one": "One apple",
    "other": "$appleCount apples"
  }
}
```

```dart
t.apple(appleCount: 3);  // "3 apples"
```

**Custom plural resolver** (for unsupported languages):

```dart
LocaleSettings.setPluralResolver(
  locale: AppLocale.xx,
  cardinalResolver: (n, {zero, one, two, few, many, other}) {
    if (n == 0) return zero ?? other!;
    if (n == 1) return one ?? other!;
    return other!;
  },
);
```

**Config-based pluralization** (alternative to modifiers):

```yaml
pluralization:
  auto: cardinal
  default_parameter: n
  cardinal:
    - someKey.apple
  ordinal:
    - someKey.place
```

## Custom Contexts / Enums

For context-dependent translations (gender, formality, user role, etc.).

```json
{
  "greet(context=GenderContext)": {
    "male": "Hello Mr $name",
    "female": "Hello Ms $name",
    "neutral": "Hello $name"
  }
}
```

Slang generates:

```dart
enum GenderContext {
  male,
  female,
  neutral,
}
```

Usage:

```dart
t.greet(name: 'Maria', context: GenderContext.female); // "Hello Ms Maria"
```

**Collapse identical forms:**

```json
{
  "greet(context=GenderContext)": {
    "male,female": "Hello $name"
  }
}
```

**Custom parameter name:**

```json
{
  "greet(context=GenderContext, param=gender)": {
    "male": "Hello Mr",
    "female": "Hello Ms"
  }
}
```

```dart
t.greet(gender: GenderContext.female);
```

**Using an existing enum** (no generation):

```yaml
imports:
  - 'package:my_app/path/to/enum.dart'
contexts:
  UserType:
    generate_enum: false
```

## RichText

Enabled by the `(rich)` modifier. Parameters accept `TextSpan` instead of `String`.

```json
{
  "welcome(rich)": "Hello $name, click ${here(here)}"
}
```

```dart
Text.rich(
  t.welcome(
    name: TextSpan(text: 'Tom', style: TextStyle(fontWeight: FontWeight.bold)),
    here: (text) => TextSpan(
      text: text,
      style: TextStyle(color: Colors.blue),
      recognizer: TapGestureRecognizer()..onTap = () => print('tapped'),
    ),
  ),
);
```

**Rules:**
- Only RichText entries can link to other RichText entries via `@:path.to.key`.
- The `(rich)` modifier can be combined with plurals and contexts.
- Default text in brackets `(here)` is used as fallback if the parameter is not provided.

## Linked Translations

Reference one translation from another using the `@:` prefix.

```json
{
  "fields": {
    "name": "my name is $firstName",
    "age": "I am $age years old"
  },
  "intro": "Hello, @:fields.name and @:fields.age"
}
```

```dart
t.intro(firstName: 'Tom', age: 27); // "Hello, my name is Tom and I am 27 years old"
```

**With namespaces:** Include the namespace in the path:

```dart
t.home.intro(...); // links to @:widgets.greeting
```

**Escaped linking** (when the path is followed by text that could be part of the path):

```json
{
  "fields": { "name": "my name is $firstName" },
  "intro": "Hello, @:{fields.name}inator"
}
```

## Interfaces

For type-safe access to translation objects with the same shape.

```json
{
  "onboarding": {
    "whatsNew(interface=ChangeData)": {
      "v2": {
        "title": "New in 2.0",
        "rows": ["Add sync"]
      },
      "v3": {
        "title": "New in 3.0",
        "rows": ["New game modes", "And a lot more!"]
      }
    }
  }
}
```

Slang generates:

```dart
mixin ChangeData {
  String get title;
  List<String> get rows;
}
```

Usage:

```dart
void render(ChangeData changes) {
  print(changes.title);   // Type-safe, no cast needed
  print(changes.rows);    // Inferred as List<String>
}

render(t.onboarding.whatsNew.v2);
render(t.onboarding.whatsNew.v3);
```

**Explicit attributes** (override inferred types):

```yaml
interfaces:
  PageData:
    attributes:
      - String title
      - String? content
      - int index
```

**Single interface** for a single object (not a container):

```json
{
  "config(singleInterface=AppConfig)": {
    "version": "1.0",
    "debug": true
  }
}
```

## Typed Parameters

Parameters are `Object` by default. Add type annotations for compile-time safety.

```json
{
  "greet": "Hello {name: String}, you are {age: int} years old",
  "price": "It costs {amount: double}"
}
```

```dart
t.greet(name: 'Tom', age: 27);         // String and int
t.price(amount: 19.99);                 // double
```

## L10n Formatting (Numbers & Dates)

Requires `intl` package. Uses built-in `NumberFormat` and `DateFormat` types.

```json
{
  "balance": "You have {amount: currency} in your account",
  "today": "Today is {date: yMd}",
  "time": "It is {now: jm}"
}
```

```dart
t.balance(amount: 1234.56);                        // "$1,234.56" (en) / "R$ 1.234,56" (pt-BR)
t.today(date: DateTime(2023, 12, 31));             // "12/31/2023" (en) / "31/12/2023" (pt-BR)
t.time(now: DateTime(2023, 1, 1, 14, 30));         // "2:30 PM" (en) / "14:30" (pt-BR)
```

### Built-in L10n Types

| Long name | Short name | Example (en) | Example (pt-BR) |
|---|---|---|---|
| `NumberFormat.compact` | `compact` | 1.2M | 1,2 mi |
| `NumberFormat.compactCurrency` | `compactCurrency` | $1.2M | R$ 1,2 mi |
| `NumberFormat.compactSimpleCurrency` | `compactSimpleCurrency` | $1.2M | R$ 1,2 mi |
| `NumberFormat.compactLong` | `compactLong` | 1.2 million | 1,2 milhão |
| `NumberFormat.currency` | `currency` | $1.23 | R$ 1,23 |
| `NumberFormat.decimalPattern` | `decimalPattern` | 1,234.56 | 1.234,56 |
| `NumberFormat.decimalPercentPattern` | `decimalPercentPattern` | 12.34% | 12,34% |
| `NumberFormat.percentPattern` | `percentPattern` | 12.34% | 12,34% |
| `NumberFormat.simpleCurrency` | `simpleCurrency` | $1.23 | R$ 1,23 |
| `DateFormat.yM` | `yM` | 2023-12 | 12/2023 |
| `DateFormat.yMd` | `yMd` | 2023-12-31 | 31/12/2023 |
| `DateFormat.Hm` | `Hm` | 14:30 | 14:30 |
| `DateFormat.Hms` | `Hms` | 14:30:15 | 14:30:15 |
| `DateFormat.jm` | `jm` | 2:30 PM | 14:30 |
| `DateFormat.jms` | `jms` | 2:30:15 PM | 14:30:15 |

### Custom Formats

```json
{
  "today": "Today is {date: DateFormat('yyyy-MM-dd')}",
  "price": "It costs {amount: currency(symbol: 'EUR')}"
}
```

### Custom Type Aliases (DRY)

```json
{
  "@@types": {
    "price": "currency(symbol: 'USD')",
    "dateOnly": "DateFormat('MM/dd/yyyy')"
  },
  "account": "You have {amount: price}",
  "today": "Today is {today: dateOnly}"
}
```

## Lists & Nested Structures

```json
{
  "niceList": [
    "hello",
    "nice",
    ["first nested", "second nested"],
    {"key1": "value1", "key2": "value2"}
  ]
}
```

```dart
t.niceList[1];               // "nice"
t.niceList[2][0];            // "first nested"
t.niceList[3].key1;          // "value1"
```

## Dynamic Maps

Use `(map)` modifier or config `maps` list for dictionary-style access.

```json
{
  "errors(map)": {
    "404": "Not found",
    "500": "Server error"
  }
}
```

```dart
t.errors['404'];  // "Not found"
```

**Config-based** (applies to all locales):

```yaml
maps:
  - errors
  - category.icons
```

**Fallback for maps:**

```json
{
  "errors(map, fallback)": {
    "404": "Not found"
  }
}
```

With fallback, unknown keys return the key itself instead of throwing.

## Namespaces

Split translations across multiple files per locale. Enable via `namespaces: true`.

**File naming:** `<namespace>_<locale>.i18n.json`

```
lib/i18n/
  widgets_en.i18n.json
  widgets_pt-BR.i18n.json
  errors_en.i18n.json
  errors_pt-BR.i18n.json
```

**Access:** `t.<namespace>.<path>`

```dart
t.widgets.hello;     // from widgets namespace
t.errors.e404;       // from errors namespace
```

**Root namespace:** Use `_default` for non-namespaced keys:

```
lib/i18n/
  _default_en.i18n.json
  _default_pt-BR.i18n.json
  widgets_en.i18n.json
```

```dart
t.appName;                    // from _default
t.widgets.welcomeCard.title;  // from widgets
```

## Region Extensions

Language-only files (e.g., `en.json`) can be extended by region-specific files
(e.g., `en-US.json`). Region files always fall back to the language file first,
then to `fallback_strategy`.

```
en.json          ← language base
en-US.json       ← extends en.json
en-GB.json       ← extends en.json
pt.json          ← language base
pt-BR.json       ← extends pt.json
```

Region fallback is hard-coded (region → language) and ignores the global
`fallback_strategy`.

## Wildcard Locales

Reuse the same translations for multiple locales.

```
i18n/
  en.json
  pt.json
  [en,pt,es].json     ← applies to en, pt, es
  [any]-FR.json       ← applies to en-FR, pt-FR (if those exist)
```

Existing specific files take precedence over wildcards.

## Translation Overrides

For dynamic translations from a backend server.

**Enable in config:**

```yaml
translation_overrides: true
```

**Override at runtime:**

```dart
LocaleSettings.overrideTranslations(
  locale: AppLocale.en,
  fileType: FileType.yaml,
  content: '''
onboarding:
  title: 'Welcome $name'
  ''',
);

t.onboarding.title(name: 'Tom');  // "Welcome Tom"
```

**With DI:**

```dart
final t2 = AppLocaleUtils.buildWithOverridesSync(
  locale: AppLocale.en,
  fileType: FileType.yaml,
  content: 'onboarding:\n  title: "Welcome $name"',
);
```

## Dependency Injection (Riverpod)

When you want to manage locale state via Riverpod instead of slang's built-in
global state.

**Config:**

```yaml
locale_handling: false
translation_class_visibility: public
```

**Provider:**

```dart
// app/lib/core/providers.dart
@Riverpod(keepAlive: true)
class CurrentLocale extends _$CurrentLocale {
  @override
  AppLocale build() => AppLocale.ptBr;

  void setLocale(AppLocale locale) {
    state = locale;
  }
}

final translationsProvider = Provider<Translations>((ref) {
  final locale = ref.watch(currentLocaleProvider);
  return locale.buildSync();
});
```

**Usage:**

```dart
final t = ref.watch(translationsProvider);
String name = t.app.name;
```

This approach is useful when:
- You want locale stored in a Riverpod provider for easy access across the app
- You need to persist locale choice via a repository
- You want to avoid global mutable state (`LocaleSettings` is global)

## Modifiers Reference

Modifiers are added to JSON keys in parentheses. Combine with commas.

```json
{
  "apple(plural, param=appleCount, rich)": {
    "one": "I have $appleCount apple.",
    "other": "I have $appleCount apples."
  }
}
```

### Structure Modifiers

| Modifier | Effect |
|---|---|
| `(rich)` | This translation accepts `TextSpan` parameters |
| `(map)` | Access this object via string keys (`t.obj['key']`) |
| `(map, fallback)` | Map that returns the key itself for unknown lookups |
| `(plural)` / `(cardinal)` | Cardinal plural (auto-detected, explicit marker) |
| `(ordinal)` | Ordinal plural (`1st`, `2nd`, `3rd`) |
| `(context=<Type>)` | Context-dependent translation, generates enum `<Type>` |
| `(param=<Name>)` | Custom parameter name for plural/context |
| `(interface=<Name>)` | Container of interfaces of type `<Name>` |
| `(singleInterface=<Name>)` | This object is an interface of type `<Name>` |

### Analysis Modifiers (no runtime effect)

| Modifier | Effect |
|---|---|
| `(ignoreMissing)` | Suppress "missing translation" warning in `slang analyze` |
| `(ignoreUnused)` | Suppress "unused translation" warning in `slang analyze` |
| `(OUTDATED)` | Flag this translation as outdated for secondary locales |
