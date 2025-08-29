import 'package:slang/src/api/formatter.dart';
import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/pluralization.dart';
import 'package:slang/src/builder/builder/text/l10n_override_parser.dart';
import 'package:slang/src/builder/generator/helper.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/pluralization.dart';
import 'package:slang/src/builder/utils/reflection_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';
import 'package:slang/src/utils/log.dart' as log;

/// Utility class handling overridden translations
class TranslationOverrides {
  static String? string(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.getOverride(path);
    if (node == null) {
      return null;
    }
    if (node is! StringTextNode) {
      log.error(
          'Overridden $path is not a StringTextNode but a ${node.runtimeType}.');
      return null;
    }
    return node.content.applyParamsAndLinks(meta, param);
  }

  static String? plural(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.getOverride(path);
    if (node == null) {
      return null;
    }
    if (node is! PluralNode) {
      log.error('Overridden $path is not a PluralNode but a ${node.runtimeType}.');
      return null;
    }

    final PluralResolver resolver;
    if (node.pluralType == PluralType.cardinal) {
      resolver = meta.cardinalResolver ??
          PluralResolvers.cardinal(meta.locale.languageCode);
    } else {
      resolver = meta.ordinalResolver ??
          PluralResolvers.ordinal(meta.locale.languageCode);
    }

    final quantities = node.quantities.cast<Quantity, StringTextNode>();

    return resolver(
      param[node.paramName] as num,
      zero: quantities[Quantity.zero]?.content.applyParamsAndLinks(meta, param),
      one: quantities[Quantity.one]?.content.applyParamsAndLinks(meta, param),
      two: quantities[Quantity.two]?.content.applyParamsAndLinks(meta, param),
      few: quantities[Quantity.few]?.content.applyParamsAndLinks(meta, param),
      many: quantities[Quantity.many]?.content.applyParamsAndLinks(meta, param),
      other:
          quantities[Quantity.other]?.content.applyParamsAndLinks(meta, param),
    );
  }

  static String? context(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.getOverride(path);
    if (node == null) {
      return null;
    }
    if (node is! ContextNode) {
      log.error('Overridden $path is not a ContextNode but a ${node.runtimeType}.');
      return null;
    }
    final context = param[node.paramName];
    if (context == null || context is! Enum) {
      return null;
    }

    return (node.entries[context.name] as StringTextNode?)
        ?.content
        .applyParamsAndLinks(meta, param);
  }

  static Map<String, String>? map(TranslationMetadata meta, String path) {
    final node = meta.getOverride(path);
    if (node == null) {
      return null;
    }
    if (node is! ObjectNode) {
      log.error('Overridden $path is not an ObjectNode but a ${node.runtimeType}.');
      return null;
    }
    if (!node.isMap || node.genericType != 'String') {
      log.error('Overridden $path can only be a map containing plain Strings.');
      return null;
    }

    return {
      for (final entry in node.entries.entries)
        entry.key: (entry.value as StringTextNode).content.applyLinks(meta, {}),
    };
  }

  static List<String>? list(TranslationMetadata meta, String path) {
    final node = meta.getOverride(path);
    if (node == null) {
      return null;
    }
    if (node is! ListNode) {
      log.error('Overridden $path is not a ListNode but a ${node.runtimeType}.');
      return null;
    }
    if (node.genericType != 'String') {
      log.error('Overridden $path can only contain plain Strings.');
      return null;
    }

    return node.entries
        .map((e) => (e as StringTextNode).content.applyLinks(meta, {}))
        .toList();
  }
}

extension TranslationOverridesStringExt on String {
  /// Replaces every ${param} with the given parameter
  String applyParams(
    Map<String, ValueFormatter> existingTypes,
    String locale,
    Map<String, Object> param,
  ) {
    return replaceDartNormalizedInterpolation(replacer: (match) {
      final nodeParam = match.substring(2, match.length - 1);

      final colonIndex = nodeParam.indexOf(':');
      if (colonIndex == -1) {
        // parameter without type
        final providedParam = param[nodeParam];
        if (providedParam == null) {
          return match; // do not replace, keep as is
        }
        return providedParam.toString();
      }

      final paramName = nodeParam.substring(0, colonIndex).trim();
      final paramType = nodeParam.substring(colonIndex + 1).trim();

      final providedParam = param[paramName];
      if (providedParam == null) {
        return match; // do not replace, keep as is
      }

      return digestL10nOverride(
            locale: locale,
            existingTypes: existingTypes,
            type: paramType,
            value: providedParam,
          ) ??
          providedParam.toString();
    });
  }

  /// Replaces every `${_root.<path>}` with the real string
  String applyLinks(TranslationMetadata meta, Map<String, Object> param) {
    return replaceDartNormalizedInterpolation(replacer: (match) {
      final nodeParam = match.substring(2, match.length - 1);
      if (!nodeParam.startsWith(characteristicLinkPrefix)) {
        return match;
      }

      final path = RegexUtils.linkPathRegex.firstMatch(nodeParam)?.group(1);
      if (path == null) {
        return match;
      }

      final refInFlatMap = meta.getTranslation(path);
      if (refInFlatMap == null) {
        return match;
      }

      if (refInFlatMap is String) {
        return refInFlatMap;
      }

      if (refInFlatMap is Function) {
        final parameterList = getFunctionParameters(refInFlatMap);
        return Function.apply(
          refInFlatMap,
          const [],
          {
            for (final p in param.entries)
              if (parameterList.contains(p.key)) Symbol(p.key): p.value,
          },
        );
      }

      return match; // this should not happen (must be string or function)
    });
  }

  /// Shortcut to call both at once.
  String applyParamsAndLinks(
      TranslationMetadata meta, Map<String, Object> param) {
    return applyParams(meta.types, meta.locale.underscoreTag, param)
        .applyLinks(meta, param);
  }
}
