import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roadstargram/markerDB.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
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
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch(e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  static final CameraPosition _kTsukubaStaion = CameraPosition(//TsukubaStation
    //target: LatLng(35.17176088096857, 136.88817886263607),
    target: LatLng(36.082528276755205, 140.11170887850292),
    zoom: 14.4746,
  );

  static final CameraPosition _kITF = CameraPosition(//ITF
      bearing: 192.8334901395799,
      //target: LatLng(35.184910766826086, 136.8996468623372),
      target: LatLng(36.10678749790326, 140.10190729280725),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  void showAllMarker() {
    final marker = FirebaseFirestore.instance.collection('marker');
    marker.get().then((QuerySnapshot querySnapshot) {
      int i=0;
      querySnapshot.docs.forEach((doc) {
        //print(doc["lat"]);
        setState(() {
          _markers.add(
              Marker(
                markerId: MarkerId(i.toString()),
                position: LatLng(doc["lat"], doc["lon"]),
              )
          );
        });
        i++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kTsukubaStaion,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          showAllMarker();

          setState(() {
            _markers.add(
                Marker(
                  markerId: MarkerId('marker_ITF'),
                  position: LatLng(36.10678749790326, 140.10190729280725),
                )
            );
          });
        },
        onTap: (LatLng latLang) {
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
                    child: Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _markers.add(
                            Marker(
                                markerId: MarkerId('marker_' + num.toString()),
                                position: latLang,
                                infoWindow: InfoWindow(title: _textController.text)
                            )
                        );
                      });
                      MarkerDB marker = MarkerDB();
                      marker.addMarker(latLang.latitude, latLang.longitude, _textController.text);
                      print('Clicked: $latLang, id: $num');
                      num = num + 1;
                    },
                  ),
                ],
              );
            },
          );


        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheNagoyajo,
        label: Text('To the ITF!'),
        icon: Icon(Icons.directions_bike),
      ),
    );
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