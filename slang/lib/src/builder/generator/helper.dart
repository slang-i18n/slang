import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/obfuscation_config.dart';
import 'package:slang/src/builder/utils/encryption_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';

/// Pragmatic way to detect links within interpolations.
const String characteristicLinkPrefix = '_root.';

String getImportName({
  required I18nLocale locale,
}) {
  return 'l_${locale.languageTag.replaceAll('-', '_')}';
}

/// Returns the class name of the root translation class.
String getClassNameRoot({
  required String className,
  I18nLocale? locale,
}) {
  String result = className +
      (locale != null
          ? locale.languageTag.toCaseOfLocale(CaseStyle.pascal)
          : '');
  return result;
}

String getClassName({
  required bool base,
  required TranslationClassVisibility visibility,
  required String parentName,
  String childName = '',
  I18nLocale? locale,
}) {
  final String languageTag;
  if (locale != null) {
    languageTag = locale.languageTag.toCaseOfLocale(CaseStyle.pascal);
  } else {
    languageTag = '';
  }
  if (base) {
    visibility = TranslationClassVisibility.public;
  }
  if (!parentName.startsWith('_') &&
      visibility == TranslationClassVisibility.private) {
    parentName = '_$parentName';
  } else if (parentName.startsWith('_') &&
      visibility == TranslationClassVisibility.public) {
    parentName = parentName.substring(1);
  }
  return parentName + childName.toCase(CaseStyle.pascal) + languageTag;
}

const _nullFlag = '\u0000';

/// Either returns the plain string or the obfuscated one.
/// Whenever translation strings gets rendered, this method must be called.
String getStringLiteral(String value, int linkCount, ObfuscationConfig config) {
  if (!config.enabled || value.isEmpty) {
    // Return the plain version
    if (value.startsWith(r'${') &&
        value.indexOf('}') == value.length - 1 &&
        linkCount == 1) {
      // We can just remove the ${ and } since it's already a string
      return value.substring(2, value.length - 1);
    } else {
      // We need to add quotes
      return "'$value'";
    }
  }

  // Return the obfuscated version

  final interpolations = <String>[];
  final links = <bool>[];
  final digestedString = value.replaceDartNormalizedInterpolation(
    replacer: (match) {
      // remove the ${ and }
      final actualMatch = match.substring(2, match.length - 1).trim();

      interpolations.add(actualMatch);
      links.add(actualMatch.startsWith(characteristicLinkPrefix));
      return _nullFlag; // replace interpolation with a null flag
    },
  );

  // join the string with the interpolation in between
  final buffer = StringBuffer();
  final parts = digestedString.split(_nullFlag);
  bool needPlus = false;
  for (int i = 0; i < parts.length; i++) {
    // add the string part
    if (parts[i].isNotEmpty) {
      if (needPlus) {
        buffer.write(' + ');
      }
      buffer.write('_root.\$meta.d([');
      buffer.write(parts[i]
          .replaceAll("\\'", "'")
          .replaceAll('\\n', '\n')
          .encrypt(config.secret)
          .join(', '));
      buffer.write('])');
      needPlus = true;
    }

    // add the interpolation
    if (i < interpolations.length) {
      if (needPlus) {
        buffer.write(' + ');
      }
      buffer.write(interpolations[i]);
      if (!links[i]) {
        // toString() is needed for non-links
        buffer.write('.toString()');
      }
      needPlus = true;
    }
  }
  return buffer.toString();
}
