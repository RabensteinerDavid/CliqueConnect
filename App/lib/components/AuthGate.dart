import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_clique_connect/components/CreateProfile.dart';
import '../helper/helper_functions.dart';
import 'Home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'NavigationBar.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLogin = true;
  double formHeightPercentage = 0.4;
  double roundEdges = 20.0;
  Color primaryColor = const Color(0xff26168C);
  Color textColor = Colors.white;
  Color textColorBlue = const Color(0xff26168C);
  Color emailFieldColor = Colors.white;
  Color passwordFieldColor = Colors.white;
  Color formFieldBackgroundColor = const Color(0xffb4a8e5);
  Color textInputColor = Colors.white;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> saveYourLogin() async{
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool('isLoggedIn', true);
  }

  Future<bool?> isProfileCreated() async{
    User? user = FirebaseAuth.instance.currentUser;
    var userID = user?.uid;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(userID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: primaryColor,
              width: MediaQuery.of(context).size.width - 200,
              height: MediaQuery.of(context).size.height * formHeightPercentage,
              child: Center(
                child: Image.asset(
                  'assets/cliqueConnect.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(roundEdges),
                  topRight: Radius.circular(roundEdges),
                ),
              ),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * (1 - formHeightPercentage),
              child: SingleChildScrollView(
                child: buildAuthForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAuthForm() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          buildLogoImage(),
          if (isLogin)
            const Text(
              'Continue to Sign In',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
          if (!isLogin)
            const Text(
              'Find your Tribe with CliqueConnect',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
          buildEmailTextField(),
          buildPasswordTextField(),
          if (!isLogin) buildConfirmPasswordTextField(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: buildSignInUpButton(),
          ),
          buildToggleAuthModeButton(),
          buildResetPasswordButton(),
        ],
      ),
    );
  }

  Widget buildResetPasswordButton() {
    return isLogin
        ? TextButton(
      onPressed: _resetPassword,
      child: const Text(
        'Reset Password',
        style: TextStyle(color: Colors.grey),
      ),
    )
        : const SizedBox();
  }

  Future<void> _resetPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your email address.'),
      ));
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent. Please check your inbox.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error sending password reset email.'),
      ));
    }
  }

  Widget buildLogoImage() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        isLogin ? 'Login' : 'Sign Up',
        style: TextStyle(
          fontSize: 50.0,
          color: isLogin ? primaryColor : primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildEmailTextField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(color: textInputColor),
        controller: emailController,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: emailFieldColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildPasswordTextField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(color: textInputColor),
        controller: passwordController,
        obscureText: true,
       /* obscureText: true, // Obscure the password input*/
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(color: passwordFieldColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildConfirmPasswordTextField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(color: textInputColor),
        controller: confirmPasswordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: TextStyle(color: emailFieldColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildSignInUpButton() {
    return ElevatedButton(
      onPressed: isLogin ? _signIn : _signUp,
      style: ElevatedButton.styleFrom(
        primary: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundEdges),
        ),
      ),
      child: Text(
        isLogin ? 'Sign In' : 'Sign Up',
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget buildToggleAuthModeButton() {
    return TextButton(
      onPressed: _toggleAuthMode,
      child: Text(
        isLogin ? 'Switch to Sign Up' : 'Switch to Login',
        style: TextStyle(color: textColorBlue),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }



  Future<void> _signIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter both email and password.'),
      ));
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await saveYourLogin();

      await HelperFunctions.saveUserLoggedInSharedPreference(true);
      await HelperFunctions.saveUserEmailSharedPreference(email);
      await HelperFunctions.saveUserNameSharedPreference(
          "David Rabensteiner"
      );

      if (await isProfileCreated() != true) {
        print("here");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CreateProfile()));
      }
      if (userCredential.user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavigationBarExample()));
      }
    } catch (e) {
      String errorMessage = "An error occurred during sign-in.";
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Wrong password. Please try again.";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    }
  }

  Future<void> _signUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    final emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter email, password, and confirm password.'),
      ));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password must be at least 6 characters long.'),
      ));
      return;
    }

    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid email address.'),
      ));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Passwords do not match."),
      ));
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await saveYourLogin();
        if (await isProfileCreated() == true) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => CreateProfile()));
        }
      }
    } catch (e) {
      String errorMessage = "An error occurred during sign-up.";
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage =
          "The email address is already in use. Please sign in.";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    }
  }
}
