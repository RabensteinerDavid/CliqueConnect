import 'package:flutter/material.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<Calendar> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Screen Title'),
      ),
      body: const Material(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(46.0, 60.0, 46.0, 60.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ],
            ),
          ),
        ),
      ),
    );
  }
}