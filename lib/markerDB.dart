import 'package:cloud_firestore/cloud_firestore.dart';
// Pin pin = Pin(lat, lon, text);
// pin.addPin();

class MarkerDB {
  final double lat;
  final double lon;
  final String text;
  late CollectionReference marker;

  MarkerDB(this.lat, this.lon, this.text) {
    marker = FirebaseFirestore.instance.collection('marker');
  }

  Future<void> addMarker() {
    return marker.add({
      'lat': this.lat,
      'lon': this.lon,
      'text': this.text,
    })
    .then((value) => print("Marker added"))
    .catchError((error) => print("Failed to add marker: $error"));
  }
}