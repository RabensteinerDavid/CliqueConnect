import 'package:flutter/material.dart';
import '../save/AnimatedMarkersMap.dart';

class MainAnimatedMarkerMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: AnimatedMarkersMap(),
    );
  }}
