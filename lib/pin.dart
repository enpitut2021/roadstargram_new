import 'package:cloud_firestore/cloud_firestore.dart';

class Pin {
  final double lat;
  final double lon;
  final String text;
  late CollectionReference pin;

  Pin(this.lat, this.lon, this.text) {
    pin = FirebaseFirestore.instance.collection('pin');
  }

  Future<void> addPin() {
    return pin.add({
      'lat': this.lat,
      'lon': this.lon,
      'text': this.text,
    })
    .then((value) => print("Pin added"))
    .catchError((error) => print("Failed to add pin: $error"));
  }
}