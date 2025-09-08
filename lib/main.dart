import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/providers/language_provider.dart';
import 'package:driver/screens/homescreen.dart';
import 'package:driver/screens/languages.dart';
import 'package:flutter/material.dart';
import 'package:driver/screens/login_screen.dart';
import 'package:driver/screens/visits_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('ur', 'PK')],
      localizationsDelegates: const [
        AppLocalizations.delegate, // Generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomePage(),
      routes: {
        // '/login' key routes to LoginScreen widget
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/language': (context) => const LanguagePage(),
        // '/profile' key routes to UserProfileScreen widget
      },
    );
  }
}
