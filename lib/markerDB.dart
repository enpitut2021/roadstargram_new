import 'package:cloud_firestore/cloud_firestore.dart';

// MarkerDB marker = MarkerDB();
// データ追加
// marker.addMarker(lat, lon, text);
// データ取り出し
// docList = marker.readAllMarker();
// docList.forEach((doc) => {
//  doc["lat"]  doc["lon"] doc["text"]...};

class MarkerDB {
  late CollectionReference marker;

  MarkerDB() {
    marker = FirebaseFirestore.instance.collection('marker');
  }

  Future<void> addMarker(lat, lon, text,goodDeg, {iine = 0}) {
    return marker.add({
      'lat': lat,
      'lon': lon,
      'text': text,
      'goodDeg':goodDeg, //1:good,0:soso,-1:bad
      'iine': iine,
    })
    .then((value) => {
      print("Marker added: ${value.id}")
    })
    .catchError((error) => print("Failed to add marker: $error"));
  }
}




