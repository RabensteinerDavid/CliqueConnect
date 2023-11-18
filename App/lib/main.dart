import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'components/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Define your custom colors
  static const Color blueMain = Color(0xff2e148C);
  static const Color lilac = Color(0xff6059f0);
  static const Color babyBlue = Color(0xffa7d5f2);
  static const Color lightRose = Color(0xFFF199F2);
  static const Color pinkMain = Color(0xFFEF3DF2);
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  static const Color greyDark = Color(0xffaca9bf);
  static const Color greyMedium = Color(0xffdbd9e7);
  static const Color greyLight = Color(0xEE2E148C);

  static const Color greyChat = Color(0xffEEEEEE);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Intro",
      theme: ThemeData(
        fontFamily: 'DINCondensed',
        backgroundColor: blueMain,
        // Add more customizations with your colors
        // For example:
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: black),
          titleMedium: TextStyle(color: black),
          titleSmall: TextStyle(color: black),
          bodyLarge: TextStyle(color: black),
          bodyMedium: TextStyle(color: black),
          bodySmall: TextStyle(color: black),
          displayLarge: TextStyle(color: black),
          displayMedium: TextStyle(color: black),
          displaySmall: TextStyle(color: black),
          headlineLarge: TextStyle(color: black),
          headlineMedium: TextStyle(color: black),
          headlineSmall: TextStyle(color: black),
          labelLarge: TextStyle(color: black),
          labelMedium: TextStyle(color: black),
          labelSmall: TextStyle(color: black),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
