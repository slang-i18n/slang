import 'package:fast_i18n/pluralization.dart';

abstract class BaseTranslations {
  BaseTranslations copyWith(
      {PluralResolver? cardinalResolver, PluralResolver? ordinalResolver});
}
