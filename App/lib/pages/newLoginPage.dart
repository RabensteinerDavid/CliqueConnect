import 'package:flutter/material.dart';
import '../helper/helper_functions.dart';
import '../pages/authenticate_page.dart';
import '../pages/home_page.dart';

class NewLoginPage extends StatefulWidget {
  @override
  State<NewLoginPage> createState() => _NewLoginPage();
}

class _NewLoginPage extends State<NewLoginPage> {

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _getUserLoggedInStatus();
  }

  _getUserLoggedInStatus() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
      if(value != null) {
        setState(() {
          _isLoggedIn = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Chats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      //home: _isLoggedIn != null ? _isLoggedIn ? HomePage() : AuthenticatePage() : Center(child: CircularProgressIndicator()),
      home: AuthenticatePage(),
      //home: HomePage(),
    );
  }
}