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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Intro",
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xff26168C, <int, Color>{
          50: Color(0xff26168C),
          100: Color(0xff26168C),
          200: Color(0xff26168C),
          300: Color(0xff26168C),
          400: Color(0xff26168C),
          500: Color(0xff26168C),
          600: Color(0xff26168C),
          700: Color(0xff26168C),
          800: Color(0xff26168C),
          900: Color(0xff26168C),
        }), // Set your primary color
        backgroundColor: const Color(0xff26168C), // Set the background color
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}





