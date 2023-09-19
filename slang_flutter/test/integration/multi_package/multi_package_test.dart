import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gen/strings_a.g.dart' as packageA;
import 'gen/strings_b.g.dart' as packageB;

void main() {
  setUp(() {
    packageA.LocaleSettings.instance.setLocale(packageA.AppLocale.en);
    packageB.LocaleSettings.instance.setLocale(packageB.AppLocale.en);
  });

  test('Should return 2 different package strings (sanity check)', () {
    expect(packageA.t.title, 'Package A (en)');
    expect(packageB.t.title, 'Package B (en)');
  });

  testWidgets('Should show 2 different package strings', (tester) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(packageA.t.title),
            Text(packageB.t.title),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);

    expect(find.text('Package A (en)'), findsOneWidget);
    expect(find.text('Package B (en)'), findsOneWidget);
  });

  testWidgets('Should change locale of both packages', (tester) async {
    final widget = packageA.TranslationProvider(
      child: packageB.TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return Column(
                children: [
                  Text(packageA.Translations.of(context).title),
                  Text(packageB.Translations.of(context).title),
                ],
              );
            }),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    expect(find.text('Package A (en)'), findsOneWidget);
    expect(find.text('Package B (en)'), findsOneWidget);

    // This should change the locale of both packages.
    packageA.LocaleSettings.setLocale(packageA.AppLocale.de);

    await tester.pumpAndSettle();

    expect(find.text('Package A (de)'), findsOneWidget);
    expect(find.text('Package B (de)'), findsOneWidget);
  });
}
