import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:roadstargram/markerDB.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  bool _is_input_mode = false;
  bool _is_first_tapped = false;
  bool _is_second_tapped = false;
  List<double> lats = [];
  List<double> lons = [];
  String _message = '道入力';
  final markerStream =
      FirebaseFirestore.instance.collection('markerTest').snapshots();
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
      return BitmapDescriptor.hueBlue; //good評価
    } else if (color == 0) {
      return BitmapDescriptor.hueGreen; //normal評価
    } else {
      return BitmapDescriptor.hueRed; //bad評価
    }
  }

  Color getPolylineColor(int color) {
    if (color == 1) {
      return Colors.blue; //good評価
    } else if (color == 0) {
      return Colors.green; //normal評価
    } else {
      return Colors.red; //bad評価
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
          List<DocumentSnapshot> searchedDoc = [];
          snapshot.data?.docs.forEach((DocumentSnapshot doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data["hashtag"]?.contains("test") ?? false) {
              searchedDoc.add(doc);
            }
          });
          return new Scaffold(
            body: new Stack(children: [
              GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kTsukubaStaion,
              polylines: searchedDoc.map((DocumentSnapshot doc) {
                Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;
                List<LatLng> latLngList = [];
                latLngList.add(LatLng(doc["lat"][0], doc["lon"][0]));
                latLngList.add(LatLng(doc["lat"][1], doc["lon"][1]));
                return Polyline(
                  polylineId: PolylineId(doc.id),
                  visible: true,
                  //latlng is List<LatLng>
                  points: latLngList,
                  color: getPolylineColor(doc["goodDeg"]),
                  width: 6,
                );
              }).toSet(),
              markers: searchedDoc.map((DocumentSnapshot doc) {
                Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;
                int iineNum = data["iine"] ?? 0;
                String hashtagStr = "";
                if (data["hashtag"] != null){
                  data["hashtag"]?.forEach((tag) {
                    hashtagStr += "#$tag ";
                  });
                }
                double latavg = (data["lat"][0] + data["lat"][1]) / 2.0;
                double lonavg = (data["lon"][0] + data["lon"][1]) / 2.0;
                return Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(latavg, lonavg),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      getMarkerColor(data["goodDeg"])),
                  infoWindow: InfoWindow(
                      title: "${data["text"]}",
                      snippet: "いいね数：$iineNum\n$hashtagStr",
                      onTap: () {
                        iineNum++;
                        print(iineNum);
                        markerDB.updateIine(doc.id, iineNum);
                      }),
                );
              }).toSet(),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _markers.add(Marker(
                  markerId: MarkerId('marker_ITF'),
                  position: LatLng(36.10678749790326, 140.10190729280725),
                ));
              },
              onTap: (LatLng latLang) {
                if (!_is_input_mode){
                }else if (!_is_first_tapped && !_is_second_tapped) {
                  lats=[];
                  lons=[];
                  Fluttertoast.showToast(msg: "終点を入力してください");
                  _is_first_tapped = true;
                  lons.add(latLang.longitude);
                  lats.add(latLang.latitude);
                  print(lons);
                  print(lats);
                } else if (_is_first_tapped && !_is_second_tapped) {
                  _is_second_tapped = true;
                  lons.add(latLang.longitude);
                  lats.add(latLang.latitude);
                  print(lons);
                  print(lats);
                  var _textController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text("レビューを入力"),
                        content: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: '#景色がキレイ #インスタ映え',
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
                              markerDB.addMarker(
                                lats,
                                lons,
                                _getNoHashTag(_textController.text),
                                1,
                                _getHashTag(_textController.text),
                              );
                              print('Clicked: $latLang, id: $num');
                              num = num + 1;
                            },
                          ),
                          FlatButton(
                            child: Text("Bad"),
                            onPressed: () {
                              Navigator.pop(context);
                              markerDB.addMarker(
                                lats,
                                lons,
                                _getNoHashTag(_textController.text),
                                -1,
                                _getHashTag(_textController.text),
                              );
                              print('Clicked: $latLang, id: $num');
                              num = num + 1;
                            },
                          ),
                        ],
                      );
                    },
                  );
                  _is_first_tapped = false;
                  _is_second_tapped = false;
                  _is_input_mode = false;
                  _changeText();
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
              buildFloatingSearchBar()],),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: (){
                _is_input_mode = !_is_input_mode;
                if(!_is_input_mode){
                  _is_first_tapped = false;
                  lats=[];
                  lons=[];
                } else {
                  Fluttertoast.showToast(msg: "始点を入力してください");
                }
                _changeText();
                },
              label: Text(_message),
              icon: Icon(Icons.directions_bike),
            ),
          );
        });
  }

  Widget buildFloatingSearchBar(){
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {
        // Call your model, bloc, controller here.
      },
      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: Colors.accents.map((color) {
                return Container(height: 112, color: color);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _changeText() {
    setState(() {
      _message = _is_input_mode ? '入力中止' : '道入力';
    });
  }

  String _getNoHashTag(String text) {
    List<String> args = text.split("#");
    return args[0].trimRight();
  }

  List<String> _getHashTag(String text) {
    List<String> args = text.split("#");
    List<String> hashtags = [];
    for(int i=1; i<args.length; i++) {
      if(args[i].isNotEmpty)
        hashtags.add(args[i].trim());
    }
    return hashtags;
  }
}
