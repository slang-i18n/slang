import 'package:slang/builder/model/enums.dart';
import 'package:slang/src/builder/builder/text_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseParam', () {
    test('Should parse without type', () {
      final result = parseParam(
        rawParam: 'myName',
        caseStyle: null,
        defaultType: 'DefaultType',
      );
      expect(result.paramName, 'myName');
      expect(result.paramType, 'DefaultType');
    });

    test('Should parse with type', () {
      final result = parseParam(
        rawParam: 'myName: MyType',
        caseStyle: null,
        defaultType: 'DefaultType',
      );
      expect(result.paramName, 'myName');
      expect(result.paramType, 'MyType');
    });

    test('Should recase', () {
      final result = parseParam(
        rawParam: 'my_name',
        caseStyle: CaseStyle.pascal,
        defaultType: 'DefaultType',
      );
      expect(result.paramName, 'MyName');
      expect(result.paramType, 'DefaultType');
    });

    test('Should ignore rich text default parameter', () {
      final result = parseParam(
        rawParam: 'hello(Hi)',
        caseStyle: null,
        defaultType: 'DefaultType',
      );
      expect(result.paramName, 'hello(Hi)');
      expect(result.paramType, '');
    });
  });

  group('parseParamWithArg', () {
    test('Should parse without arg', () {
      final result = parseParamWithArg(
        rawParam: 'myName',
        paramCase: null,
      );
      expect(result.paramName, 'myName');
      expect(result.arg, null);
    });

    test('Should parse with arg', () {
      final result = parseParamWithArg(
        rawParam: 'myName(Hello!)',
        paramCase: null,
      );
      expect(result.paramName, 'myName');
      expect(result.arg, 'Hello!');
    });

    test('Should recase', () {
      final result = parseParamWithArg(
        rawParam: 'my_name(Hello!)',
        paramCase: CaseStyle.pascal,
      );
      expect(result.paramName, 'MyName');
      expect(result.arg, 'Hello!');
    });
  });
}
