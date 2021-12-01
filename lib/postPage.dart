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