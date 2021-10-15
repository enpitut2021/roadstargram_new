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
    marker = FirebaseFirestore.instance.collection('markerTest');
  }

  Future<void> addMarker(lat, lon, text, goodDeg, {iine = 0, hashtag = const ["test"]}) {
    return marker.add({
      'lat': lat,
      'lon': lon,
      'text': text,
      'goodDeg':goodDeg, //1:good,0:soso,-1:bad
      'iine': iine,
      'hashtag': hashtag,
    })
    .then((value) => {
      print("Marker added: ${value.id}")
    })
    .catchError((error) => print("Failed to add marker: $error"));
  }

  Future<void> updateIine(id, iine) {
    return marker.doc(id).update({
      'iine': iine,
    }).then((value) => {
      print("Marker iine updated: $id")
    }).catchError((error) => print("Failed to update marker: $error"));
  }
}




