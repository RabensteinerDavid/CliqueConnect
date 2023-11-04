import 'package:flutter/material.dart';
import 'AnimatedMarkersMap.dart';

class MainAnimatedMarkerMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: AnimatedMarkersMap(),
    );
  }}
