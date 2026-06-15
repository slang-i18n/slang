---
name: slang
description: >-
  Implement and manage internationalization with the slang package (type-safe
  i18n via JSON code-gen). Use whenever the user mentions translations,
  localization, l10n, i18n, multi-language support, adding a new locale,
  generating locale configs, or setting up slang in a Dart/Flutter project — even
  if they don't say "slang" explicitly. Also use when the task touches
  `.i18n.json` files, `slang.yaml`, `build.yaml` slang_build_runner config,
  `AppLocale`, `Translations`, `LocaleSettings`, `TranslationProvider`,
  `CFBundleLocalizations`, or melos scripts for i18n generation.
---

# Slang — Type-Safe Internationalization for Dart & Flutter

You are setting up or modifying a type-safe i18n system using the **slang**
package ecosystem. Every decision must produce compile-time-checked translations
with zero runtime parsing. The generated code is the source of truth — never
edit it by hand.

## Contents

- [When to Use This Skill](#when-to-use-this-skill)
- [Quick Decision: Two Generation Paths](#quick-decision-two-generation-paths)
- [Setup Workflow](#setup-workflow)
- [Resource Routing](#resource-routing)
- [Common Anti-Patterns](#common-anti-patterns)
- [Limitations](#limitations)

## When to Use This Skill

Trigger this skill when any of the following appear in the task:

- Setting up i18n/l10n for a new or existing Dart/Flutter project
- Adding, removing, or renaming translation keys across locales
- Adding a new locale (creating `*.i18n.json` files)
- Configuring `slang_build_runner` in `build.yaml` or a standalone `slang.yaml`
- Updating `CFBundleLocalizations` or Android locale config
- Wiring `TranslationProvider`, `LocaleSettings`, or locale delegates into a
  Flutter app
- Integrating slang code generation into melos workspace scripts
- Debugging missing translations, fallback behavior, or locale-switching issues
- Using slang features: plurals, contexts, rich text, linked translations,
  interfaces, namespaces, typed parameters, or L10n formatting

## Quick Decision: Two Generation Paths

Slang offers two generation workflows. Choose based on the project's
existing tooling:

| Scenario                                                                             | Use                    | Config file  | Generation command            |
| ------------------------------------------------------------------------------------ | ---------------------- | ------------ | ----------------------------- |
| Project already uses `build_runner` (freezed, json_serializable, riverpod_generator) | **slang_build_runner** | `build.yaml` | `dart run build_runner build` |
| Project does NOT use `build_runner`, or you want faster i18n-only generation         | **standalone slang**   | `slang.yaml` | `dart run slang`              |

> **Heuristic:** If the project has `build_runner` in its `dev_dependencies`,
> prefer `slang_build_runner` so all code generation runs with one command.

Both approaches produce identical output. The `build.yaml` config is also
recognized by `dart run slang`, so you can use both methods in the same project.

## Setup Workflow

Copy this checklist and execute in order:

- [ ] **Task Progress**
  - [ ] 1. Add dependencies to `pubspec.yaml`
  - [ ] 2. Create locale JSON files in the i18n directory
  - [ ] 3. Configure slang (in `build.yaml` or `slang.yaml`)
  - [ ] 4. Run code generation
  - [ ] 5. Initialize in `main.dart` (Flutter) or entry point (Dart)
  - [ ] 6. Wire locale configuration into `MaterialApp` / `CupertinoApp`
  - [ ] 7. Run `slang configure` to update native platform configs
  - [ ] 8. Add generated files to `.gitignore`
  - [ ] 9. Configure melos scripts (if monorepo)
  - [ ] 10. Verify: analyzer clean, translations resolve at runtime

### Step 1: Add Dependencies

**Always add at minimum:**

```yaml
# pubspec.yaml (app or package)
dependencies:
  slang: ^4.16.0
  slang_flutter: ^4.16.0 # only for Flutter apps
  flutter_localizations: # only for Flutter apps
    sdk: flutter

dev_dependencies:
  slang_build_runner: ^4.16.0 # only if using build_runner path
```

**If NOT using build_runner**, omit `slang_build_runner`. The `slang` package
includes the `dart run slang` CLI directly.

**If this is a pure Dart project** (no Flutter), omit both `slang_flutter` and
`flutter_localizations`.

### Step 2: Create Locale JSON Files

Create translation files in `lib/i18n/` (keeps translations inside the package's
`lib/` source tree).

**File naming format:** `<locale>.i18n.json`

```
lib/i18n/
  en.i18n.json    ← base locale (must contain every key)
  pt-BR.i18n.json       ← additional locale (can be partial — missing keys fall back)
```

**Base locale file** (the locale declared as `base_locale` in config) must have
every key. Secondary locales can be partial — missing keys fall back according
to `fallback_strategy`.

**JSON structure:**

```json
{
  "app": {
    "name": "App Name",
    "tagline": "My app tagline"
  },
  "greeting": "Hello, $name"
}
```

**If creating new content:** Add keys to the base locale file first, then
propagate to all secondary locales.
**If editing existing content:** Update the corresponding key across all locales.

**String interpolation syntax MUST match `string_interpolation` config:**
- `dart` (default): use `$name` or `${name}`
- `braces`: use `{name}`
- `double_braces`: use `{{name}}`

Using the wrong syntax produces literal text (e.g., `{name}` in `dart` mode
outputs the string `"{name}"` instead of the value).

**If using namespaces** (files > ~300 lines), format is
`<namespace>_<locale>.i18n.json`. See `references/features.md#namespaces`.

### Step 3: Configure Slang

#### Option A: `build.yaml` (when using `slang_build_runner`)

Add the `slang_build_runner` builder inside the existing `targets.$default.builders`:

```yaml
# build.yaml (app package)
targets:
  $default:
    builders:
      # ... existing builders (freezed, json_serializable, riverpod_generator)
      slang_build_runner:
        options:
          base_locale: pt-BR
          fallback_strategy: base_locale
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_name: strings.g.dart
          translate_var: t
          enum_name: AppLocale
          class_name: Translations
          locale_handling: true
          flutter_integration: true
          namespaces: false
          timestamp: false
```

#### Option B: `slang.yaml` (standalone, no build_runner)

Create `slang.yaml` in the package root (sibling to `pubspec.yaml`) with
identical options. The full config reference (40+ options) is at
`references/config.md`.

### Step 4: Run Code Generation

**With build_runner** (generates everything in one pass):

```bash
fvm dart run build_runner build
```

**Standalone** (i18n only, ~50ms):

```bash
fvm dart run slang
```

_Feedback Loop:_ If generation fails, check JSON for syntax errors (trailing
commas, unescaped quotes, duplicate keys). Run `dart run slang analyze` to find
missing and unused translations.

### Step 5: Initialize in main.dart (Flutter)

```dart
import 'package:my_app/i18n/strings.g.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();
  runApp(
    TranslationProvider(
      child: MyApp(),   // or ProviderScope(child: MyApp()) for Riverpod
    ),
  );
}
```

**Critical rules:**

- `WidgetsFlutterBinding.ensureInitialized()` must precede any locale call.
- `await LocaleSettings.useDeviceLocale()` returns a `Future` — always `await`
  it or the locale may not be ready when the first frame builds.
- `TranslationProvider` must be an ancestor of any widget that calls
  `Translations.of(context)` or `context.t`.

**For pure Dart projects** (no Flutter), skip `TranslationProvider` and call
`LocaleSettings.setLocale(AppLocale.en)` or use `AppLocale.en.build()` for
dependency injection.

### Step 6: Wire Locale into MaterialApp

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/i18n/strings.g.dart';

// Inside MaterialApp / MaterialApp.router / CupertinoApp:
MaterialApp.router(
  locale: TranslationProvider.of(context).flutterLocale,
  supportedLocales: AppLocaleUtils.supportedLocales,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
);
```

Without `supportedLocales` and `localizationsDelegates`, standard Flutter
widgets (back buttons, date pickers) render in English regardless of locale.
`MaterialApp.router` uses the same properties as `MaterialApp`.

### Step 7: Update Native Platform Configs

Run after adding or removing locales:

```bash
fvm dart run slang configure
```

This automatically updates `CFBundleLocalizations` in `ios/Runner/Info.plist`
and `macos/Runner/Info.plist`. For Android, ensure `AndroidManifest.xml` includes
`locale|layoutDirection` in `android:configChanges` (standard in Flutter templates).

### Step 8: Gitignore Generated Files

Add to the package's `.gitignore`:

```
# Generated i18n files
lib/i18n/**/*.g.dart
```

Generated `.g.dart` files are build artifacts. Do not commit them — regenerate
via `melos gen:all` or `dart run slang`.

### Step 9: Melos Scripts (Monorepo Only)

When the project uses Melos, add these scripts to the root `pubspec.yaml` under
`melos.scripts`:

```yaml
i18n:configure:
  description: Sync native locale configs with translation files
  run: melos exec --scope=app -- fvm dart run slang configure

gen:i18n:
  description: Quick i18n-only generation + config sync
  run: fvm dart run slang && fvm dart run slang configure
  exec:
    concurrency: 1
  packageFilters:
    depends-on: slang_build_runner
```

**Critical melos rules:**

1. `i18n:configure` uses `melos exec --scope=app` — not an `exec` script with
   `packageFilters` — to avoid interactive prompts.
2. Never `cd` into subdirectories in melos scripts; use `melos exec` or
   `melos run` instead.

For detailed monorepo patterns and troubleshooting, see `references/melos.md`.

### Step 10: Verify

```bash
fvm flutter analyze          # static analysis — must report 0 errors
fvm dart run slang           # verify generation runs cleanly
```

## Resource Routing

When a task goes beyond basic setup, read only the relevant reference file:

| Task                                                                                            | Read                     | Purpose                                                             |
| ----------------------------------------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------- |
| Tuning a specific option, seeing all 40+ config keys                                            | `references/config.md`   | Complete configuration table with defaults, types, and interactions |
| Adding plurals, contexts, rich text, linked translations, interfaces, typed parameters, or L10n | `references/features.md` | Full syntax guide for every advanced feature with examples          |
| Setting up melos scripts for a monorepo, debugging `melos exec` issues                          | `references/melos.md`    | Melos integration patterns, script templates, troubleshooting       |

## Common Anti-Patterns

### ❌ BAD: Forgetting `WidgetsFlutterBinding.ensureInitialized()`

```dart
void main() {
  LocaleSettings.useDeviceLocale(); // CRASHES — binding not initialized
  runApp(MyApp());
}
```

### ✅ GOOD: Ensure binding before any locale call

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: MyApp()));
}
```

### ❌ BAD: Not awaiting `useDeviceLocale()`

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale(); // Future not awaited — locale may not be ready
  runApp(TranslationProvider(child: MyApp()));
}
```

### ✅ GOOD: Await the locale initialization (`main` must be `async`)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: MyApp()));
}
```

### ❌ BAD: Missing `TranslationProvider` ancestor

```dart
MaterialApp(
  home: MyHomePage(), // Translations.of(context) — THROWS, no provider in tree
);
```

### ✅ GOOD: TranslationProvider wraps the app

```dart
TranslationProvider(
  child: MaterialApp(
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: MyHomePage(),
  ),
);
```

### ❌ BAD: Mixing `slang.yaml` and `build.yaml` for the same package

This causes conflicting settings. Choose one config file per package.

### ❌ BAD: Assuming `slang_build_runner` auto-applies without `build.yaml` config

```yaml
# ❌ WRONG — baseline agents often incorrectly omit this
# "slang_build_runner auto-applies, no config needed in build.yaml"
```

`slang_build_runner` MUST be configured in `build.yaml` alongside other builders
when the project uses `build_runner`. The slang docs explicitly require this.
Without it, generation still happens but you lose control over options like
`base_locale`, `fallback_strategy`, and `output_file_name`.

### ✅ GOOD: Always configure `slang_build_runner` explicitly in `build.yaml`

```yaml
targets:
  $default:
    builders:
      slang_build_runner:
        options:
          base_locale: pt-BR
          # ... all other options
```

### ❌ BAD: Using non-existent slang APIs

```dart
// ❌ WRONG — these do NOT exist
final locales = AppLocale.values;                          // NO — use AppLocaleUtils.supportedLocales
final delegates = AppLocalizationDelegates.delegates;       // NO — use GlobalMaterialLocalizations.delegates
```

### ✅ GOOD: Use the actual slang-provided APIs

```dart
// ✅ CORRECT
final locales = AppLocaleUtils.supportedLocales;
final delegates = GlobalMaterialLocalizations.delegates;
```

### ❌ BAD: Hardcoding locale lists in platform configs

```xml
<!-- Manually maintained — rots when locales change -->
<key>CFBundleLocalizations</key>
<array>
  <string>pt-BR</string>
</array>
```

### ✅ GOOD: Run `slang configure` after every locale change

```bash
fvm dart run slang configure
```

### ❌ BAD: Adding keys only to the base locale

Secondary locales silently fall back, producing mixed-language UIs.

### ✅ GOOD: Add keys to all locales, or run `slang analyze` to detect gaps

```bash
dart run slang analyze
```

### ❌ BAD: Committing generated `.g.dart` files

Build artifacts that should be gitignored. Committing them creates noise in PRs.

### ✅ GOOD: Gitignore all generated i18n artifacts

```
# .gitignore
lib/i18n/**/*.g.dart
```

## Limitations

- **Slang does not handle RTL layout.** RTL is a Flutter `Directionality` concern.
  Slang provides translations; the widget tree determines text direction.
- **`slang configure` only updates iOS/macOS `.plist` files.** Android locale
  resources must be managed separately if needed.
- **Generated code must be regenerated after every locale file change.** There is
  no hot-reload path for translations. Use `dart run slang` (<100ms) for fast
  iteration.
- **The flat map (`t['key']`) returns `Object?`, not `String`.** Cast or use the
  typed accessor (`t.myKey`) for compile-time safety.
- **Plurals for unsupported languages require a custom resolver.** See
  `references/features.md` for the plural resolver API.
- **Slang is not a translation management platform.** It generates code from local
  files. For large teams with external translators, pair slang with a translation
  service (Weblate integration is built-in) or a CI pipeline that syncs JSON files.
