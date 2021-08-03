import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roadstargram/markerDB.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(home: Text("Error"));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              title: 'Flutter Google Maps Demo',
              home: MapSample(),
            );
          }
          return MaterialApp(home: CircularProgressIndicator());
        });
  }
}

class MapSample extends StatefulWidget {
  @override
  State createState() => MapSampleState();
}

class MapSampleState extends State {
  Completer _controller = Completer();
  Set<Marker> _markers = {};
  var num = 0;
  bool _is_tapped = false;
  List<double> lats = [];
  List<double> lons = [];
  final markerStream =
      FirebaseFirestore.instance.collection('marker').snapshots();
  final MarkerDB markerDB = MarkerDB();

  static final CameraPosition _kTsukubaStaion = CameraPosition(
    //TsukubaStation
    //target: LatLng(35.17176088096857, 136.88817886263607),
    target: LatLng(36.082528276755205, 140.11170887850292),
    zoom: 14.4746,
  );

  static final CameraPosition _kITF = CameraPosition(
      //ITF
      bearing: 192.8334901395799,
      //target: LatLng(35.184910766826086, 136.8996468623372),
      target: LatLng(36.10678749790326, 140.10190729280725),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  double getMarkerColor(int color) {
    if (color == 1) {
      return BitmapDescriptor.hueRed; //good評価
    } else if (color == 0) {
      return BitmapDescriptor.hueGreen; //normal評価
    } else {
      return BitmapDescriptor.hueBlue; //bad評価
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: markerStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          return new Scaffold(
            body: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kTsukubaStaion,
              markers: snapshot.data?.docs.map((DocumentSnapshot doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    int iineNum = data["iine"] ?? 0;
                    return Marker(
                      markerId: MarkerId(doc.id),
                      position: LatLng(data["lat"], data["lon"]),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          getMarkerColor(data["goodDeg"])),
                      infoWindow: InfoWindow(
                          title: data["text"],
                          snippet: "いいね数：$iineNum",
                          onTap: () {
                            iineNum++;
                            print(iineNum);
                            markerDB.updateIine(doc.id, iineNum);
                          }),
                    );
                  }).toSet() ??
                  Set<Marker>(),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _markers.add(Marker(
                  markerId: MarkerId('marker_ITF'),
                  position: LatLng(36.10678749790326, 140.10190729280725),
                ));
              },
              onTap: (LatLng latLang) {
                if (!_is_tapped) {
                  _is_tapped = true;
                  lons.add(latLang.longitude);
                  lats.add(latLang.latitude);
                  print(lons);
                  print(lats);
                } else {
                  _is_tapped = false;
                  lons = [];
                  lats = [];
                  var _textController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text("レビューを入力"),
                        content: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: '景色がキレイ',
                          ),
                          autofocus: true,
                          // keyboardType: TextInputType.number,
                        ),
                        actions: <Widget>[
                          // ボタン領域
                          FlatButton(
                            child: Text("Good!!"),
                            onPressed: () {
                              Navigator.pop(context);
                              markerDB.addMarker(latLang.latitude,
                                  latLang.longitude, _textController.text, 1);
                              print('Clicked: $latLang, id: $num');
                              num = num + 1;
                            },
                          ),
                          FlatButton(
                            child: Text("Bad"),
                            onPressed: () {
                              Navigator.pop(context);
                              markerDB.addMarker(
                                  latLang.latitude,
                                  latLang.longitude,
                                  _textController.text,
                                  -1); //固定値でgood1
                              print('Clicked: $latLang, id: $num');
                              num = num + 1;
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _goToTheNagoyajo,
              label: Text('To the ITF!'),
              icon: Icon(Icons.directions_bike),
            ),
          );
        });
  }

  Future _goToTheNagoyajo() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kITF));
  }
/*
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      var options = MarkerOptions(
          position: LatLng(35.6580339,139.7016358),
          infoWindowText: InfoWindowText("タイトル", "説明分等")
      );
      mapController.addMarker(options);
    });

   */
}
