import 'package:flutter/material.dart';
import 'package:roadstargram/markerDB.dart';

enum RadioValue { GOOD, BAD }

class PostPage extends StatefulWidget {
  final List<double> lats, lons;
  const PostPage(this.lats, this.lons);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  var _textController = TextEditingController();
  RadioValue _type = RadioValue.GOOD;
  var markerDB = MarkerDB();

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
            new RadioListTile(
              secondary: Icon(Icons.thumb_up),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text('Good'),
              subtitle: Text('Goodアイコンの表示'),
              value: RadioValue.GOOD,
              groupValue: _type,
              onChanged: _handleRadio,
            ),
            new RadioListTile(
              secondary: Icon(Icons.thumb_down),
              activeColor: Colors.blue,
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text('Bad'),
              subtitle: Text('Favoriteアイコンの表示'),
              value: RadioValue.BAD,
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
                  1,
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