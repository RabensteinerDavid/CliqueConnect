import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Address to Coordinates'),
        ),
        body: Center(
          child: AddressToCoordinates(),
        ),
      ),
    );
  }
}

class AddressToCoordinates extends StatefulWidget {
  @override
  _AddressToCoordinatesState createState() => _AddressToCoordinatesState();
}

class _AddressToCoordinatesState extends State<AddressToCoordinates> {
  TextEditingController _addressController = TextEditingController();
  String _result = '';

  Future<void> _convertAddressToCoordinates() async {
    try {
      List<Location> locations = await locationFromAddress(_addressController.text);

      if (locations.isNotEmpty) {
        Location first = locations.first;
        setState(() {
          _result = 'Latitude: ${first.latitude}, Longitude: ${first.longitude}';
        });
      } else {
        setState(() {
          _result = 'No coordinates found for the given address';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Enter an address',
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _convertAddressToCoordinates,
            child: Text('Get Coordinates'),
          ),
          SizedBox(height: 16.0),
          Text(
            _result,
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}
