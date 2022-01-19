import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:roadstargram/markerDB.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:roadstargram/postPage.dart';
import 'package:url_launcher/url_launcher.dart';

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

class MapSampleState extends State<MapSample> {
  Completer _controller = Completer();
  Set<Marker> _markers = {};
  var num = 0;
  bool _is_input_mode = false;
  bool _is_first_tapped = false;
  bool _is_second_tapped = false;
  bool _show_pin_info = false;
  List<double> lats = [];
  List<double> lons = [];
  String _message = '道入力';
  String _searchText = "";
  String _pin_info_text = "Text";
  String _pin_info_hashtag = "hashtag";
  var _pin_info_iine = 0;
  var _pin_info_docid = "";

  var _selected_lat_start = 0.0;
  var _selected_lon_start = 0.0;
  var _selected_lat_end = 0.0;
  var _selected_lon_end = 0.0;

  List<List<double>> _waypoints = [];

  int _filter_type = 0;
  List<String> _filter_text = ["フィルターなし", "いいレビューのみ", "悪いレビューのみ"];

  final markerStream =
      FirebaseFirestore.instance.collection('marker').snapshots();
  final MarkerDB markerDB = MarkerDB();
  FloatingSearchBarController controller = FloatingSearchBarController();

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
          print(_searchText);
          snapshot.data?.docs.forEach((DocumentSnapshot doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (_searchText == "" ||
                (data["hashtag"]?.contains(_searchText) ?? false)) {
              if (_filter_type == 1 && doc["goodDeg"] == 1 ||
                  _filter_type == 2 && doc["goodDeg"] == -1 ||
                  _filter_type == 0) {
                searchedDoc.add(doc);
              }
            }
          });
          return new Scaffold(
            body: new Stack(
              children: [
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
                    if (data["hashtag"] != null) {
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
                        // infoWindow: InfoWindow(
                        //     title: "${data["text"]}",
                        //     snippet: "いいね数：$iineNum\n$hashtagStr",
                        //     onTap: () {
                        //       iineNum++;
                        //       print(iineNum);
                        //       markerDB.updateIine(doc.id, iineNum);
                        //     }),
                        onTap: () {
                          this.setState(() {
                            _show_pin_info = true;
                            _pin_info_text = data["text"];
                            _pin_info_hashtag = hashtagStr;
                            _pin_info_iine = iineNum;
                            _pin_info_docid = doc.id;
                            _selected_lat_start = data["lat"][0];
                            _selected_lon_start = data["lon"][0];
                            _selected_lat_end = data["lat"][1];
                            _selected_lon_end = data["lon"][1];
                            print(_selected_lat_start);
                            print(_selected_lon_start);
                          });
                        });
                  }).toSet(),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    _markers.add(Marker(
                      markerId: MarkerId('marker_ITF'),
                      position: LatLng(36.10678749790326, 140.10190729280725),
                    ));
                  },
                  onTap: (LatLng latLang) {
                    this.setState(() {
                      _show_pin_info = false;
                    });
                    if (!_is_input_mode) {
                    } else if (!_is_first_tapped && !_is_second_tapped) {
                      lats = [];
                      lons = [];
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PostPage(lats, lons)));
                      _is_first_tapped = false;
                      _is_second_tapped = false;
                      _is_input_mode = false;
                      _changeText();
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                    top: 110,
                    left: 20,
                    child: Container(
                      color: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _filter_type++;
                                  _filter_type %= 3;
                                });
                              },
                              child: const Text("切り替え")),
                          Text(_filter_text[_filter_type]),
                        ],
                      ),
                    )
                ),
                Positioned(
                  top: 110,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () async {
                      final position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      var url =
                          'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=${position.latitude},${position.longitude}';
                      url += '&waypoints=';
                      _waypoints.forEach((w) {
                        url += '${w[0]},${w[1]}%7C';
                      });
                      print(url);
                      if (await canLaunch(url)) {
                        launch(url, forceSafariVC: false);
                      }
                    },
                    child: Text("ドライブ開始(${_waypoints.length~/2})"),
                  ),
                ),
                Positioned(
                  top: 150,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _waypoints.clear();
                      });
                    },
                    child: const Text("ドライブルートのリセット"),
                  ),
                ),
                buildFloatingSearchBar(),
                if (_show_pin_info)
                  DraggableScrollableSheet(
                      initialChildSize: 0.3,
                      maxChildSize: 0.5,
                      minChildSize: 0.1,
                      builder: (BuildContext context,
                          ScrollController scrollController) {
                        return Container(
                            color: Colors.white.withOpacity(1),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 50),
                              children: <Widget>[
                                Container(
                                  height: 50,
                                  color: Colors.white,
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('$_pin_info_text')),
                                ),
                                Container(
                                  height: 50,
                                  color: Colors.white,
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('$_pin_info_hashtag')),
                                ),
                                Container(
                                    height: 50,
                                    color: Colors.white,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton(
                                        child: Text('それな $_pin_info_iine'),
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.lightBlue,
                                          onPrimary: Colors.black,
                                          shape: const StadiumBorder(),
                                        ),
                                        onPressed: () {
                                          _pin_info_iine++;
                                          print(_pin_info_iine);
                                          markerDB.updateIine(_pin_info_docid, _pin_info_iine);
                                        },
                                      ),
                                    )),
                                Container(
                                    height: 50,
                                    color: Colors.white,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton(
                                        child: Row(
                                          children: [
                                            Image.asset('images/icons8-google-maps-48.png'),
                                            Text('Google Mapsで確認する'),
                                          ],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.white,
                                          onPrimary: Colors.black,
                                          shape: const StadiumBorder(),
                                          side: const BorderSide(),
                                        ),
                                        onPressed: () async {
                                          final url = 'https://www.google.com/maps/search/?api=1&query=${_selected_lat_start},${_selected_lon_start}';
                                          if (await canLaunch(url)) {
                                            launch(url, forceSafariVC: false);
                                          }
                                        },
                                      ),
                                    )
                                ),
                                Container(
                                    height: 50,
                                    color: Colors.white,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton(
                                        child: Row(
                                          children: [
                                            Image.asset('images/icons8-root-64.png'),
                                            Text('ドライブルートに追加'),
                                          ],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.white,
                                          onPrimary: Colors.black,
                                          shape: const StadiumBorder(),
                                          side: const BorderSide(),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _waypoints.add([
                                              _selected_lat_start,
                                              _selected_lon_start
                                            ]);
                                            _waypoints.add([
                                              _selected_lat_end,
                                              _selected_lon_end
                                            ]);
                                          });
                                        },
                                      ),
                                    ))
                              ],
                            ));
                      })
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Visibility(
                visible: !_show_pin_info,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _is_input_mode = !_is_input_mode;
                    if (!_is_input_mode) {
                      _is_first_tapped = false;
                      lats = [];
                      lons = [];
                    } else {
                      Fluttertoast.showToast(msg: "始点を入力してください");
                    }
                    _changeText();
                  },
                  label: Text(_message),
                  icon: Icon(Icons.directions_car),
                )),
          );
        });
  }

  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    //FloatingSearchBarController controller = FloatingSearchBarController();

    return FloatingSearchBar(
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      controller: controller,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {
        //_searchText = query;
        // Call your model, bloc, controller here.
      },
      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      onSubmitted: (query) {
        this.setState(() {
          _searchText = query;
          controller.close();
        });
      },
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
            child: search_recommend(),
          ),
        );
      },
    );
  }

  Widget search_recommend() {
    List<String> hashtags = [
      'リセットしますか？',
      '春',
      '夏',
      '秋',
      '冬',
      '晴れ',
      '雨',
      '曇り',
      '雪',
      '早朝',
      '朝',
      '昼',
      '夜',
      '深夜',
      '1人',
      '友達',
      '家族',
      '恋人',
    ];
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: hashtags.map((h) {
          return ListTile(
              title: Text(h),
              onTap: () {
                print(h);
                if (h == hashtags[0]) {
                  //リセットする
                  this.setState(() {
                    _searchText = "";
                    controller.close();
                  });
                } else {
                  this.setState(() {
                    _searchText = h;
                    controller.close();
                  });
                }
                // _searchText += h;
              });
        }).toList()

        // ListView.builder(
        //   itemCount: 10,
        //   itemBuilder: (context, index) {
        //     print('build $index');
        //
        //     return Container(
        //       color: Colors.white,
        //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        //       child: Text(
        //         hashtags[index],
        //       ),
        //     );
        //   },
        // ),
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
    for (int i = 1; i < args.length; i++) {
      if (args[i].isNotEmpty) hashtags.add(args[i].trim());
    }
    return hashtags;
  }

//   Future<void> _setCurrentLocation(ValueNotifier<Position> position,
//       ValueNotifier<Map<String, Marker>> markers) async {
//     final currentPosition = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//
//     const decimalPoint = 3;
//     // 過去の座標と最新の座標の小数点第三位で切り捨てた値を判定
//     if ((position.value.latitude).toStringAsFixed(decimalPoint) !=
//         (currentPosition.latitude).toStringAsFixed(decimalPoint) &&
//         (position.value.longitude).toStringAsFixed(decimalPoint) !=
//             (currentPosition.longitude).toStringAsFixed(decimalPoint)) {
//
//       // 現在地座標のstateを更新する
//       position.value = currentPosition;
//     }
//   }
}
