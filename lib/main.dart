import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kTsukubaStaion,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
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
          print('Clicked: $latLang, id: $num');
          setState(() {
            _markers.add(
                Marker(
                  markerId: MarkerId('marker_' + num.toString()),
                  position: latLang,
                )
            );
          });
          num = num + 1;
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