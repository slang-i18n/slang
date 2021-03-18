import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale(); // initialize with the right locale

  // we will wrap it with TranslationProvider because user can change locale at runtime
  // see method B in .g.dart file
  runApp(TranslationProvider(
    child: MyApp()
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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

                // some locale variables (some redundancy here, but this is a tutorial)
                AppLocale activeLocale = LocaleSettings.currentLocaleTyped; // active locale (typed version)
                String activeLocaleString = LocaleSettings.currentLocale; // active locale (string version)
                String activeLocaleStringAlternative = activeLocale.toLanguageTag(); // active locale (string version)
                AppLocale loopLocale = locale; // current locale in loop (typed version)
                String loopLocaleString = loopLocale.toLanguageTag(); // current locale in loop (string version)
                bool active = activeLocale == loopLocale; // typed version is preferred to avoid typos

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: active ? Colors.blue.shade100 : null),
                    onPressed: () {
                      // locale change, will trigger a rebuild (no setState needed)
                      LocaleSettings.setLocaleTyped(locale);
                    },
                    child: Text(t.locales[loopLocaleString]!),
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
