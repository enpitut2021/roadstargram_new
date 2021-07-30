import 'package:cloud_firestore/cloud_firestore.dart';
// MarkerDB marker = MarkerDB();
// データ追加
// marker.addMarker(lat, lon, text);
// データ取り出し
// doc = marker.readAllMarker();
// doc["lat"]  doc["lon"] doc["text"]

class MarkerDB {
  late CollectionReference marker;

  MarkerDB() {
    marker = FirebaseFirestore.instance.collection('marker');
  }

  Future<void> addMarker(lat, lon, text) {
    return marker.add({
      'lat': lat,
      'lon': lon,
      'text': text,
    })
    .then((value) => print("Marker added"))
    .catchError((error) => print("Failed to add marker: $error"));
  }

  Future<List<QueryDocumentSnapshot>> readAllMarker() {
    List<QueryDocumentSnapshot> docList = [];
    marker.get().then((QuerySnapshot querySnapshot) {
      docList = querySnapshot.docs;
    });
    return Future<List<QueryDocumentSnapshot>>.value(docList);
  }
}