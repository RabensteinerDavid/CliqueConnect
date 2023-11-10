import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_clique_connect/components/Home.dart';
import 'package:video_player/video_player.dart';
import 'AuthGate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // video controller
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/intro.mp4',
    )
      ..initialize().then((_) {
        setState(() {});
      });
    /*..setVolume(0.0)*/

    _playVideo();
  }

  Future<bool?> getYourLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool? storedPassword = prefs.getBool('isLoggedIn');
    return storedPassword;
  }

  void _playVideo() async {
    // playing video
    _controller.play();

    // add delay until the video is complete
    await Future.delayed(const Duration(seconds: 2));

    if(await getYourLogin() != null && await getYourLogin() == true){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }
    else{
      // Navigating to the AuthGate screen with a custom transition
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AuthGate(),
        ),
      );
    }

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff26168C),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(
            _controller,
          ),
        )
            : Container(),
      ),
    );
  }
}
