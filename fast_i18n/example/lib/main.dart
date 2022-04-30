import 'package:example/i18n/strings.g.dart';
import 'package:fast_i18n_flutter/fast_i18n_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale(); // initialize with the right locale
  runApp(TranslationProvider(
    // wrap with TranslationProvider
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: LocaleSettings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // get t variable, will trigger rebuild on locale change
    // otherwise just call t directly (if locale is not changeable)
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.mainScreen.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.mainScreen.counter(count: _counter)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              // lets loop over all supported locales
              children: AppLocale.values.map((locale) {
                AppLocale activeLocale =
                    LocaleSettings.currentLocale; // active locale
                bool active = activeLocale ==
                    locale; // typed version is preferred to avoid typos

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: active ? Colors.blue.shade100 : null),
                    onPressed: () {
                      // locale change, will trigger a rebuild (no setState needed)
                      LocaleSettings.setLocale(locale);
                    },
                    child: Text(t.locales[locale.languageTag]!),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: t.mainScreen.tapMe,
        child: Icon(Icons.add),
      ),
    );
  }
}
