import 'package:slang/src/utils/log.dart' as log;

part 'plural_resolver_map.dart';

/// Selects the correct string depending on [n]
typedef PluralResolver = String Function(
  num n, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
});

class _Resolvers {
  final PluralResolver cardinal;
  final PluralResolver ordinal;

  _Resolvers({required this.cardinal, required this.ordinal});
}

/// Default plural resolvers
class PluralResolvers {
  static PluralResolver cardinal(String language) {
    return _getResolvers(language).cardinal;
  }

  static PluralResolver ordinal(String language) {
    return _getResolvers(language).ordinal;
  }

  static _Resolvers _getResolvers(String language) {
    final resolvers = _resolverMap[language];
    if (resolvers == null) {
      log.error(
          'Resolver for <lang = $language> not specified! Please configure it via LocaleSettings.setPluralResolver. A fallback is used now.');
      return _defaultResolver;
    }
    return resolvers;
  }
}
