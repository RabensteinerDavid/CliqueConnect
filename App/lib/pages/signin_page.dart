import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../helper/helper_functions.dart';
import '../models/user.dart';
import '../pages/home_page.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../shared/constants.dart';
import '../shared/loading.dart';

class SignInPage extends StatefulWidget {
  final Function toggleView;
  SignInPage({required this.toggleView});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  late User _user;

  Future<void> _onSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _auth.signInWithEmailAndPassword(email, password);

        if (result != null) {
          final userInfoSnapshot =
          await DatabaseService(uid: _user.uid).getUserData(email);

          final userData = userInfoSnapshot.data() as Map<String, dynamic>?;

          await HelperFunctions.saveUserLoggedInSharedPreference(true);
          await HelperFunctions.saveUserEmailSharedPreference(email);
          await HelperFunctions.saveUserNameSharedPreference(
            userData?['fullName'] ?? 'Default Full Name',
          );

          print("Signed In");
          print("Logged in: ${await HelperFunctions.getUserLoggedInSharedPreference()}");
          print("Email: ${await HelperFunctions.getUserEmailSharedPreference()}");
          print("Full Name: ${await HelperFunctions.getUserNameSharedPreference()}");

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePageChat()),
          );
        } else {
          setState(() {
            error = 'Error signing in!';
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error: $e");
        setState(() {
          error = 'An error occurred while signing in.';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return _isLoading ? Loading() : Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("Create or Join Groups", style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold)),

                  SizedBox(height: 30.0),

                  Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 25.0)),

                  SizedBox(height: 20.0),

                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    decoration: textInputDecoration.copyWith(labelText: 'Email'),
                    validator: (val) {
                      return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val!) ? null : "Please enter a valid email";
                    },
                    onChanged: (val) {
                      setState(() {
                        email = val;
                      });
                    },
                  ),

                  SizedBox(height: 15.0),

                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    decoration: textInputDecoration.copyWith(labelText: 'Password'),
                    validator: (val) => val!.length < 6 ? 'Password not strong enough' : null,
                    obscureText: true,
                    onChanged: (val) {
                      setState(() {
                        password = val;
                      });
                    },
                  ),

                  SizedBox(height: 20.0),

                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0.0,
                        primary: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                      ),
                      onPressed: () {
                        _onSignIn();
                      },
                      child: Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                    ),
                  ),


                  SizedBox(height: 10.0),

                  Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Register here',
                          style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            widget.toggleView();
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.0),

                  Text(error, style: TextStyle(color: Colors.red, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
