import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_1.dart';

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
  Color primaryColor = Color(0xff26168C);
  Color textColor = Colors.white;
  Color textColorBlue = Color(0xff26168C);
  Color emailFieldColor = Colors.white;
  Color passwordFieldColor = Colors.white;
  Color formFieldBackgroundColor =  Color(0xffb4a8e5); // Background color for the input fields
  Color textInputColor = Colors.white;


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
                fontSize: 14.0, // You can adjust the font size as needed
              ),
            ),
          buildEmailTextField(),
          buildPasswordTextField(),
          if (!isLogin) buildConfirmPasswordTextField(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Make the container take the full width
            height: 50,
            child: buildSignInUpButton(),
          ),
          buildToggleAuthModeButton(),
        ],
      ),
    );
  }



  Widget buildLogoImage() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 16.0),
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
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor, // Background color for the input field
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(color: textInputColor),
        controller: emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: emailFieldColor),
          border: InputBorder.none,
        ),
        onTap: () {
          setState(() {
            emailFieldColor = emailFieldColor;
            passwordFieldColor = emailFieldColor;
          });
        },
      ),
    );
  }

  Widget buildPasswordTextField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor, // Background color for the input field
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(color: textInputColor),
        controller: passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(color: passwordFieldColor),
          border: InputBorder.none,
        ),
        onTap: () {
          setState(() {
            passwordFieldColor = emailFieldColor;
            emailFieldColor = emailFieldColor;
          });
        },
      ),
    );
  }

  Widget buildConfirmPasswordTextField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(roundEdges),
        color: formFieldBackgroundColor, // Background color for the input field
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 7,
            offset: Offset(0, 3),
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
        onTap: () {
          setState(() {
            emailFieldColor = emailFieldColor;
            passwordFieldColor = emailFieldColor;
          });
        },
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
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (userCredential.user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Passwords do not match."),
      ));
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (userCredential.user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } catch (e) {
      String errorMessage = "An error occurred during sign-up.";
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = "The email address is already in use. Please sign in.";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    }
  }
}
