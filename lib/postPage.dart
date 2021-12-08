import 'package:flutter/material.dart';
import 'package:roadstargram/markerDB.dart';

class PostPage extends StatefulWidget {
  final List<double> lats, lons;
  const PostPage(this.lats, this.lons);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  var _textController = TextEditingController();
  int _type = 1;
  var markerDB = MarkerDB();
  String? _selectSeason = null;
  String? _selectTime = null;
  String? _selectWho = null;
  String? _selectWeather = null;

  @override
  void initState() {
    super.initState();
  }

  _handleRadio(value) {
    setState(() {_type = value;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title : Text("道のレビューを追加")
      ),
      body : Center(
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '#景色がキレイ #インスタ映え',
              ),
              autofocus: true,
              // keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                // ElevatedButton(
                //   child: Text("季節"),
                //   onPressed: () {
                //     showDialog(
                //       context: context,
                //         builder: (_) {
                //            return AlertDialog(
                //              title: Text("レビューを入力"),
                //              content: SingleChildScrollView(
                //               child: ListTileTheme(
                //                 contentPadding: EdgeInsets.fromLTRB(14.0, 0.0, 24.0, 0.0),
                //                 child: ListBody(
                //                   children: [
                //                     MultiSelectDialog(
                //                       items:
                //                     )
                //                   ],
                //                 ),
                //               ),
                //            ),
                //            );
                //          }
                //     );
                //   }
                // ),
                DropdownButton<String>(
                  value: _selectSeason,
                  hint: new Text("季節"),
                  onChanged: (String? value) => {
                    setState(() {
                      _selectTime = value!;
                    }),
                  },
                  items: <String>['春', '夏', '秋', '冬']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectWeather,
                  hint: new Text("天候"),
                  onChanged: (String? value) => {
                    setState(() {
                      _selectWeather = value!;
                    }),
                  },
                  items: <String>['晴れ', '雨', '曇り', '雪']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectTime,
                  hint: new Text("時間帯"),
                  onChanged: (String? value) => {
                    setState(() {
                      _selectTime = value!;
                    }),
                  },
                  items: <String>['早朝', '朝', '昼', '夜', '深夜']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectWho,
                  hint: new Text("誰と"),
                  onChanged: (String? value) => {
                    setState(() {
                      _selectWho = value!;
                    }),
                  },
                  items: <String>['1人', '友達', '家族', '恋人']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            new RadioListTile(
              secondary: Icon(Icons.thumb_up),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text('Good'),
              subtitle: Text('いいね！'),
              value: 1,
              groupValue: _type,
              onChanged: _handleRadio,
            ),
            new RadioListTile(
              secondary: Icon(Icons.thumb_down),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text('Bad'),
              subtitle: Text('微妙...'),
              value: -1,
              groupValue: _type,
              onChanged: _handleRadio,
            ),
            ElevatedButton(
              child: Text("レビューを投稿する"),
              onPressed: (){
                markerDB.addMarker(
                  widget.lats,
                  widget.lons,
                  _getNoHashTag(_textController.text),
                  _type,
                  _getHashTag(_textController.text),
                );
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
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
}