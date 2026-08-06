# Slang + Melos — Monorepo Integration Patterns

When the project is a Dart/Flutter monorepo managed by
[Melos](https://pub.dev/packages/melos), integrate slang code generation into
the workspace scripts.

## Standard Two-Script Setup

Every monorepo using slang should have these two scripts:

```yaml
# Root pubspec.yaml → melos.scripts
melos:
  scripts:
    i18n:configure:
      description: Sync native locale configs (iOS/Android) with translation files
      run: melos exec --scope=app -- fvm dart run slang configure

    gen:i18n:
      description: Quick i18n-only generation (~50ms) and config sync
      run: fvm dart run slang && fvm dart run slang configure
      exec:
        concurrency: 1
      packageFilters:
        depends-on: slang_build_runner
```

### Script Purposes

| Script                     | When to run                                                                          | Duration |
| -------------------------- | ------------------------------------------------------------------------------------ | -------- |
| `melos gen:i18n`           | After changing only translation `.i18n.json` files                                   | <1s      |
| `melos run i18n:configure` | After manually adding/removing locales (rarely needed standalone — normally chained) | <1s      |

## Why These Patterns

### `i18n:configure` uses `melos exec --scope=app`, NOT `exec` + `packageFilters`

```yaml
# ❌ BAD — prompts the user to select packages:
i18n:configure:
  run: fvm dart run slang configure
  exec:
    concurrency: 1
  packageFilters:
    depends-on: slang_build_runner

# ✅ GOOD — always runs in app without prompting:
i18n:configure:
  run: melos exec --scope=app -- fvm dart run slang configure
```

**Why:** `exec` scripts with `packageFilters` trigger an interactive package
selection prompt unless `--no-select` is passed. `melos exec --scope=app` targets
the app package directly without prompting.

### Both `gen:all` and `gen:i18n` must chain configure

```yaml
# ❌ BAD — native configs silently fall out of sync:
gen:i18n:
  run: fvm dart run slang

# ✅ GOOD — configure always follows generation:
gen:i18n:
  run: fvm dart run slang && fvm dart run slang configure
```

**Why:** Adding or removing a locale `.i18n.json` file requires updating
`CFBundleLocalizations` in `Info.plist`. Without the configure step, the app
will still work (slang generates correct Dart code), but iOS will not display
the locale in system settings.

### No `cd` in melos scripts

```bash
# ❌ BAD:
run: fvm dart run build_runner build --workspace && (cd app && fvm dart run slang configure)

# ✅ GOOD:
run: fvm dart run build_runner build --workspace && melos run i18n:configure
```

**Why:** `cd` in scripts is fragile — melos may change the working directory
between scripts. Use `melos run` or `melos exec` to dispatch to the right
package.

## Advanced: Per-App I18n Generation

When the workspace has multiple apps that each have their own translations:

```yaml
gen:i18n:
  description: Generate i18n for all apps
  run: fvm dart run slang && fvm dart run slang configure
  exec:
    concurrency: 1
  packageFilters:
    depends-on: slang_build_runner
    dirExists: lib/i18n
```

The `exec` with `packageFilters` runs the command in each matching package
directory. When called from another script, add `--no-select`:

```yaml
gen:all:
  run: fvm dart run build_runner build --workspace && melos run gen:i18n --no-select
```

## Adding a `gen` Script That Handles Env Symlinks

If the app uses `.env` (e.g., with `envied`), symlink it before generation:

```yaml
gen:
  description: Run code generation for selected packages (interactive)
  run: |
    ln -sf ../.env .env 2>/dev/null || true
    fvm dart run build_runner build && fvm dart run slang configure
  exec:
    concurrency: 1
  packageFilters:
    depends-on: build_runner
```

This ensures the `gen` script (used for single-package runs) also configures
locales.

## Troubleshooting

### `slang configure` says "File not found: ./macos/Runner/Info.plist"

This is expected if the project doesn't have a macOS target. Not an error.

### Melos prompts "Which packages to run?"

Check that the script uses `melos exec --scope=<name>` (not `exec` with
`packageFilters`), or that it is called with `--no-select`.

### `build_runner` runs slang but doesn't find input files

Verify the `build.yaml` has `input_directory` pointing to the correct path,
and that `.i18n.json` files exist there. slang_build_runner scans the
directory specified in its options, not the project root.

### Generated file has `AppLocale.ptBr` instead of `AppLocale.ptBR`

This is expected behavior — slang converts locale tags to valid Dart enum
members. `pt-BR` becomes `ptBr`, `zh-CN` becomes `zhCn`.
