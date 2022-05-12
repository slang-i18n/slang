## 2.0.0

**Extract build_runner to a separate package**

- **Breaking:** add `slang_build_runner` if you use the `build_runner` command (this ensures that `build` remains as a dev dependency)

You can read the detailed migration guide [here](https://github.com/Tienisto/slang/blob/master/slang/MIGRATION.md).

## 1.0.0

**Transition to a federated package structure**

This is still a pre-release. Please consider `2.0.0` as the first release.

- **Breaking:** rebranding to `slang`, add `slang_flutter` if you use flutter
- **Breaking:** remove `output_file_pattern` (was deprecated)
- feat: dart-only support (`flutter_integration: false`)
- feat: multiple package support
- feat: RichText support

Thanks to [@fzyzcjy](https://github.com/fzyzcjy).

You can read the detailed migration guide [here](https://github.com/Tienisto/slang/blob/master/slang/MIGRATION.md).
