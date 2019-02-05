import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../HomePage/ChatPage/playVideo.dart';
import '../../../models/group_model.dart';
import 'package:http/http.dart' as http;
import '../../../cameraModule/views/recordClip.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info'); //1
  Directory directory;
  Directory thumbailDirectory;

  List<bool> showShareVideoCheckBox = <bool>[];
  List<GroupModel> groupList;
  File videoFile;
  SharedPreferences prefs;
  String myId;
  String myName;
  String userPhone;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    directory = new Directory('/storage/emulated/0/OyeYaaro/Videos');
    // thumbailDirectory = new Directory('/storage/emulated/0/OyeYaaro/Thumbnails');
    readLocal();
  }

  Future<List<String>> listDir() async {
    print(
        'inlistDir() ...*****************************************:${showShareVideoCheckBox.length}');
    print('1.DIR *** ${directory}');
    List<String> videos = <String>[]; //
    // showShareVideoCheckBox = <bool>[];
    var exists = await directory.exists();
    print('2.exist ');

    if (exists) {
      print('showShareVideoCheckBox::${showShareVideoCheckBox.length}');
      print('videos::${videos.length}');

      // var addCheckbox = showShareVideoCheckBox.length;
      directory.listSync(recursive: true, followLinks: true).forEach((f) {
        print("3.PATH*****:" + f.path);
        if (f.path.toString().endsWith('.mp4')) {
          print("***adding : ${f.path}");
          videos.add(f.path);

          // //thumbnails
          // createThumbnails('/storage/emulated/0/ShortVideo/Record',
          //     f.path.toString()); //thumbnails
          // // print('addbox::${addCheckbox}');
          // if (addCheckbox == 0) {
          showShareVideoCheckBox.add(false);
          // }
        }
      });
      print('ShowvisL:${showShareVideoCheckBox.length}');
      return videos;
    } else {
      videos.add('empty');
      print('ShowvisL:${showShareVideoCheckBox.length}');
      return videos;
    }
  }

  // void createThumbnails(folder, videoPath) async {
  //   String thumb = await Thumbnails.getThumbnail(
  //       thumbnailFolder: folder,
  //       videoFile: videoPath,
  //       imageType: ThumbFormat.PNG,
  //       quality: 30);
  //   print('path to File******************************: $thumb');
  // }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: new FutureBuilder<List<String>>(
              future: listDir(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasError)
                  return Text("Error => ${snapshot.error}");
                return snapshot.hasData
                    ? body(snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            ),
          ),
          //  FlatButton(
          //   child: Text(
          //     'Camera',
          //     style: TextStyle(color: Colors.white, fontSize: 18),
          //   ),
          //   splashColor: Colors.green,
          //   color: Colors.indigo[900],
          //   shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(8.0)),
          //   onPressed: () {
          //     //write function logic here
          //     opneCamera("+917040470678"); //3 //userPhone
          //   },
          // ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 25.0,
        ),
        onPressed: () {
          //write function logic here
          opneCamera(); //3 //userPhone
        },
      ),
    );
  }

  Widget body(dataList) {
    if (dataList.length != 0) {
      if (dataList[0] == 'empty') {
        return Center(
          child: Text('${directory.toString()} Path not Exist'),
        );
      } else {
        return GridView.count(
          primary: false,
          padding:  EdgeInsets.all(8.0),
          crossAxisSpacing: 8.0,
          crossAxisCount: 2,
          children: videoGrid(dataList),
        );
      }
    } else {
      return Center(
        child: Text('Folder is Empty'),
      );
    }
  }

  List<Widget> videoGrid(dataList) {
    var count = 0;
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < dataList.length; i++) {
      print('dataList : ${dataList[i]}');
      count++;
      btnlist.add(Container(
        margin: EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: FileImage(
                File('/storage/emulated/0/OyeYaaro/Thumbnails/' +
                    (dataList[i].toString().split("/").last)
                        .replaceAll('mp4', 'png')),
              ),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(10.0)),
        child: GestureDetector(
          onTapUp: (TapUpDetails details) {
            print('videoName::${dataList[i]}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayScreen(url: dataList[i], type: 'file'),
              ),
            );
          },
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: 0.0,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: -10.0,
                top: -10.0,
                child: Checkbox(
                    // tristate: false,
                    // activeColor: Colors.white,
                    value: showShareVideoCheckBox[i],
                    onChanged: (bool value) {
                      print('checkbox called');
                      setState(() {
                        showShareVideoCheckBox[i] = !showShareVideoCheckBox[i];

                        if (showShareVideoCheckBox[i]) {
                          print('got true');
                          openOptions(dataList[i], i);
                        }
                      });
                    }),
              )
            ],
          ),
        ),
      ));
    }
    return btnlist;
  }

  openOptions(video, i) {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
            // color: Colors.red,
            decoration: new BoxDecoration(
                color: Colors.transparent,
                borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(10.0),
                    topRight: const Radius.circular(10.0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () {
                    //delete video
                    File f = new File.fromUri(Uri.file(video));
                    f.delete();
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Navigator.pop(context);
                    shareVideo(video, i); //file object
                  },
                )
              ],
            ),
            height: 60.0,
          );
        }).then((onValue) {
      setState(() {
        showShareVideoCheckBox[i] = false;
      });
    });
  }

  shareVideo(video, i) {
    print('calleed shareVideo()');
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
              // color: Colors.red,
              height: 200.0,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Share With ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      LayoutBuilder(builder: (context, constraint) {
                        return new Icon(Icons.group, size: 30.0);
                      })
                    ],
                  ),
                  FutureBuilder<List<GroupModel>>(
                    future: fetchGroups(http.Client()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        print("Error....${snapshot.error}");
                      return snapshot.hasData
                          ? Expanded(
                              child: groupListView(snapshot.data, video, i))
                          : Center(child: CircularProgressIndicator());
                    },
                  )
                ],
              ));
        }).then((onValue) {
      setState(() {
        showShareVideoCheckBox[i] = false;
      });
    });
  }

  Widget groupListView(data, video, i) {
    groupList = data;
    return ListView.builder(
        shrinkWrap: true,
        itemCount: data.length,
        padding: const EdgeInsets.all(5.0),
        itemBuilder: (context, position) {
          return Column(
            children: <Widget>[
              ListTile(
                leading: new CircleAvatar(
                  foregroundColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.lightBlue[100],
                  child: Text(data[position].name[0]),
                ),
                title: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(
                      '${data[position].name}',
                      style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${data[position].message}',
                  style: new TextStyle(
                    fontSize: 18.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onTap: () => _onTapGroup(context, position, video, i),
              ),
              Divider(height: 5.0),
            ],
          );
        });
  }

  Future _onTapGroup(context, position, video, i) async {
    Navigator.pop(context);
    setState(() {
      showShareVideoCheckBox[i] = false;
    });

    // var groupMembers = getGroupsMember(groupList[position].ids);  //err

    final snackBar = SnackBar(
      content: Text('Sending..'),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar); //not work

    var result = await http.get('http://54.200.143.85:4200/time');
    var res = jsonDecode(result.body);
    print('TimeStamp got:-----${res['timestamp']}');
    var timestamp = res['timestamp'];
    print('TimeStamp set:-----${timestamp}');

    videoFile = new File(video);
    var stream =
        new http.ByteStream(DelegatingStream.typed(videoFile.openRead()));
    var length = await videoFile.length();
    var uri = Uri.parse("http://54.200.143.85:4200/uploadVideo");
    var request = new http.MultipartRequest("POST", uri);
    // var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    request.headers["time"] = timestamp;
    request.headers["dialog_id"] = groupList[position].ids;
    request.headers["senderId"] = this.myId;
    request.headers["type"] = "group";

    var multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");
    print(
        '${stream}..${length}..${uri}..${request}..${timestamp}..${groupList[position].ids}');
    request.files.add(multipartFile);
    // send
    var response = await request.send();
    // print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });

    var documentReference = Firestore.instance
        .collection('groups')
        .document(this.groupList[position].ids)
        .collection(this.groupList[position].ids)
        .document(timestamp); //DateTime.now().millisecondsSinceEpoch.toString()

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'senderId': this.myId,
          'idTo': this.groupList[position].ids,
          'timestamp': timestamp,
          'msg':
              "http://54.200.143.85:4200/Media/Videos/${groupList[position].ids}/${timestamp}.mp4",
          'type': 2,
          'members': '', //groupMembers,//err
          'senderName': this.myName,
          'groupName': this.groupList[position].name,
          'thumbnail': "http://54.200.143.85:4200/Media/Frames/" +
              this.groupList[position].ids +
              "/" +
              timestamp +
              "_1.jpg"
        },
      );
    }).then((onValue) {
      print('sent to firebase');
    });
  }

  getGroupsMember(peerId) async {
    try {
      http.Response response = await http.post(
          "http://54.200.143.85:4200/getJoinedArray",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"dialog_id": '${peerId}'}));
      var groupMembers = jsonDecode(response.body);
      if (groupMembers['success'] == true) {
        print('Group members :res*****:${groupMembers['data']}');
        return groupMembers['data'];
      }
    } catch (e) {}
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? ''; //id
    print('MY USER ID: ${this.myId}');
    this.myName = prefs.getString('userName');
    this.userPhone = prefs.getString('userPhone');

    setState(() {});
  }

  Future<void> opneCamera() async {
    /*  var sendMap = <String, dynamic>{
      'from': phone,
    };
    String result;
    try {
      result = await platform.invokeMethod('openCamera', sendMap);
    } on PlatformException catch (e) {}
    return result; */
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordClip()),
    );

    print('came  back cameara...*****************************************');
  }
}
