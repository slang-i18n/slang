## 2.1.0

- feat: add `slang.yaml` support which has less boilerplate than `build.yaml`
- fix: move internal `build.yaml` to correct package

## 2.0.0

**Transition to a federated package structure**

- **Breaking:** rebranding to `slang`
- **Breaking:** add `slang_build_runner`, `slang_flutter` depending on your use case
- **Breaking:** remove `output_file_pattern` (was deprecated)
- feat: dart-only support (`flutter_integration: false`)
- feat: multiple package support
- feat: RichText support

Thanks to [@fzyzcjy](https://github.com/fzyzcjy).

You can read the detailed migration guide [here](https://github.com/Tienisto/slang/blob/master/slang/MIGRATION.md).
