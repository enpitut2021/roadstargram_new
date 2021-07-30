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

  static final CameraPosition _kNSK = CameraPosition(
    target: LatLng(35.17176088096857, 136.88817886263607),
    zoom: 14.4746,
  );

  static final CameraPosition _kNagoyajo = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(35.184910766826086, 136.8996468623372),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kNSK,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          setState(() {
            _markers.add(
                Marker(
                  markerId: MarkerId('marker_1'),
                  position: LatLng(35.184910766826086, 136.8996468623372),
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
        label: Text('To the 名古屋城!'),
        icon: Icon(Icons.directions_bike),
      ),
    );
  }

  Future _goToTheNagoyajo() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kNagoyajo));
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