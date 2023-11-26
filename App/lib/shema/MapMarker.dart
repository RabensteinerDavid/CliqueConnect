import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart'; // Import LatLng from 'latlong2' package
import 'package:rrule/rrule.dart';

class MapMarker {
  final String image;
  final String title;
  final String description;
  final Timestamp start;
  final Timestamp end;
  final String address;
  final LatLng location; // Assuming LatLng is from the 'latlong2' package
  final String category;
  final RecurrenceRule? rule;

  MapMarker({
    required this.image,
    required this.title,
    required this.start,
    required this.end,
    required this.description,
    required this.address,
    required this.location,
    required this.category,
    this.rule,
  });
}