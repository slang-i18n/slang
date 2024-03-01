part of 'slang_flutter.dart';

class TranslationOverridesFlutter {
  /// Handler for overridden rich text.
  /// Returns a [TextSpan] if the [path] was successfully overridden.
  /// Returns null otherwise.
  static TextSpan? rich(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.overrides[path];
    if (node == null) {
      return null;
    }
    if (node is! RichTextNode) {
      print(
          'Overridden $path is not a RichTextNode but a ${node.runtimeType}.');
      return null;
    }

    return node._buildTextSpan(meta, param);
  }

  /// Handler for overridden rich plural.
  /// Returns a [TextSpan] if the [path] was successfully overridden.
  /// Returns null otherwise.
  static TextSpan? richPlural(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.overrides[path];
    if (node == null) {
      return null;
    }
    if (node is! PluralNode) {
      print('Overridden $path is not a PluralNode but a ${node.runtimeType}.');
      return null;
    }
    if (!node.rich) {
      print('Overridden $path must be rich (RichText).');
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

    final quantities = node.quantities.cast<Quantity, RichTextNode>();

    return RichPluralResolvers.bridge(
      n: param[node.paramName] as num,
      resolver: resolver,
      zero: quantities[Quantity.zero] != null
          ? () => quantities[Quantity.zero]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
      one: quantities[Quantity.one] != null
          ? () => quantities[Quantity.one]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
      two: quantities[Quantity.two] != null
          ? () => quantities[Quantity.two]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
      few: quantities[Quantity.few] != null
          ? () => quantities[Quantity.few]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
      many: quantities[Quantity.many] != null
          ? () => quantities[Quantity.many]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
      other: quantities[Quantity.other] != null
          ? () => quantities[Quantity.other]!
              ._buildTextSpan<num>(meta, param, node.paramName)
          : null,
    );
  }

  /// Handler for overridden rich context.
  /// Returns a [TextSpan] if the [path] was successfully overridden.
  /// Returns null otherwise.
  static TextSpan? richContext<T>(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.overrides[path];
    if (node == null) {
      return null;
    }
    if (node is! ContextNode) {
      print('Overridden $path is not a ContextNode but a ${node.runtimeType}.');
      return null;
    }
    if (!node.rich) {
      print('Overridden $path must be rich (RichText).');
      return null;
    }

    final context = param[node.paramName]! as Enum;
    return (node.entries[context.name]! as RichTextNode?)
        ?._buildTextSpan<T>(meta, param, node.paramName);
  }
}

/// Rich plural resolvers
class RichPluralResolvers {
  /// The plural resolver for rich text.
  /// It uses the original [resolver] (which only handles strings)
  /// to determine which plural form should be used.
  static TextSpan bridge({
    required num n,
    required PluralResolver resolver,
    TextSpan Function()? zero,
    TextSpan Function()? one,
    TextSpan Function()? two,
    TextSpan Function()? few,
    TextSpan Function()? many,
    TextSpan Function()? other,
  }) {
    final String select = resolver(
      n,
      zero: zero != null ? 'zero' : null,
      one: one != null ? 'one' : null,
      two: two != null ? 'two' : null,
      few: few != null ? 'few' : null,
      many: many != null ? 'many' : null,
      other: other != null ? 'other' : null,
    );

    switch (select) {
      case 'zero':
        return zero!();
      case 'one':
        return one!();
      case 'two':
        return two!();
      case 'few':
        return few!();
      case 'many':
        return many!();
      case 'other':
        return other!();
      default:
        throw 'This should not happen';
    }
  }
}

extension on RichTextNode {
  TextSpan _buildTextSpan<T>(
    TranslationMetadata meta,
    Map<String, Object> param, [
    String? builderParam,
  ]) {
    return TextSpan(
      children: spans.map((e) {
        if (e is LiteralSpan) {
          return TextSpan(
            text: e.literal.applyParamsAndLinks(meta, param),
          );
        }
        if (e is FunctionSpan) {
          return (param[e.functionName] as InlineSpanBuilder)(e.arg);
        }
        if (e is VariableSpan) {
          if (e.variableName == builderParam) {
            return (param['${e.variableName}Builder'] as InlineSpan Function(
                T))(param[builderParam] as T);
          }
          return param[e.variableName] as InlineSpan;
        }
        throw 'This should not happen';
      }).toList(),
    );
  }
}
