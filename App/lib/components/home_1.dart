import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthGate.dart'; // Import your login screen widget

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Sign Out Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _signOut(); // Sign out the user
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthGate()));
            },
          ),
        ],
        automaticallyImplyLeading: false,
        title: const Text('User Profile'),
      ),
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/cliqueConnect.png'),
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}
