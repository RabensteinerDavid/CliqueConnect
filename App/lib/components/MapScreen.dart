import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screen'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height - 0.1,
        width: MediaQuery.of(context).size.width ,
        child: MapboxMap(
          accessToken: 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg',
          styleString: 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10',
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0),
            zoom: 1000.0,
          ),
        ),
      ),
    );
  }
}
