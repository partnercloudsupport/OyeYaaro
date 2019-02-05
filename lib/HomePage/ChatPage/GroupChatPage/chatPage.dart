import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart'; //
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect_yaar/models/group_model.dart';
import '../const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../groupInfoTabsPage.dart';
import 'package:async/async.dart';
import '../playVideo.dart';

import 'package:audioplayers/audioplayers.dart';
import '../../pages/showImage.dart';
import 'package:flutter/services.dart';

//#for CustomApp bar(HEADER)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTap;
  final AppBar appBar;
  const CustomAppBar({Key key, this.onTap, this.appBar}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: appBar);
  }

  // TODO: implement preferredSize
  @override
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);
}

class Chat extends StatelessWidget {
  // final String peerId;
  // final String peerAvatar;
  final String peerId;
  final String chatType;
  final String name;
  final List<GroupModel> groupInfo;

  Chat({Key key, this.peerId, this.chatType, this.name, this.groupInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // appBar: CustomAppBar(
      //   appBar: AppBar(
      //     title: Text(
      //       '${this.name}',
      //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //     ),
      //   ),
      //   onTap: () {
      //     Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) =>
      //               GroupChatInfoPage(
      //                   name: this.name,
      //                   groupInfo: this.groupInfo,
      //                   dialogId: this.peerId
      //                   ),
      //         ));
      //   },
      // ),

      appBar: AppBar(
        title: new Text(
          '${this.name}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GrpInfoTabsHome(
                        peerId: peerId, chatType: chatType, groupName: name),
                  ));
            },
          ),
        ],
      ),
      body: new ChatScreen(
          peerId: peerId,
          chatType: chatType,
          groupInfo: groupInfo,
          groupName: name),
    );
  }
}

//......................
class ChatScreen extends StatefulWidget {
  final String peerId;
  final String groupName;
  final String chatType;
  final List<GroupModel> groupInfo;

  ChatScreen(
      {Key key,
      @required this.peerId,
      @required this.chatType,
      @required this.groupInfo,
      @required this.groupName})
      : super(key: key);

  @override
  State createState() => new ChatScreenState(
      peerId: peerId,
      chatType: chatType,
      groupInfo: groupInfo,
      groupName: groupName);
}

enum PlayerState { stopped, playing, paused }

class ChatScreenState extends State<ChatScreen> {
  // VoidCallback listener;
  ChatScreenState({
    Key key,
    @required this.peerId,
    @required this.chatType,
    @required this.groupInfo,
    @required this.groupName,
  }) {
    textEditingController.addListener(() {
      if (textEditingController.text.isEmpty) {
        setState(() {
          isSearching = false;
        });
      } else {
        setState(() {
          isSearching = true;
        });
      }
    });
  }

  // vars
  var downloadedSongPath;
  final String groupName;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  bool isLoading;
  bool showShortSongs;
  bool showShortSongsLongSongs;

  String peerId;
  String chatType;
  String myId;
  String myName;
  String id; //
  String timestamp; //

  List<GroupModel> groupInfo;
  var groupMembersArr = [];
  List<dynamic> listMessage;
  SharedPreferences prefs;
  // String userToken; //

  File imageFile;
  String imageUrl; //

  //#songList
  bool isPlaying = false;
  bool isSearching = false;
  List searchresult = new List();
  List songSearchresult2 = new List();

  List<dynamic> _songList1;
  List<dynamic> _songList2;

  String searchText = ""; //
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;
  Duration duration;
  Duration position;
  get songisPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;
  get durationText => duration?.toString()?.split('.')?.first ?? '';
  get positionText => position?.toString()?.split('.')?.first ?? '';
  // bool songLoading = false;
  // int filteredSongIndex;
  String playingSongInList;

  @override
  void initState() {
    super.initState();
    getGroupsMember();
    isLoading = false;
    isSearching = false;
    imageUrl = '';
    timestamp = '';
    values();
    _initAudioPlayer();
    readLocal();
  }

  Future values() async {
    _songList1 = List();
    _songList2 = List();

    http.post(
      "http://54.200.143.85:4200/getAudioListForChat",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      print("RES:*****${res[0]}");
      _songList1.addAll(res);
      print('RES_List:*****${_songList1}');
    });

    http.post(
      "http://54.200.143.85:4200/getAudioList",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      print("RES_songList2:*****${res[0]}");
      _songList2.addAll(res);
      print('res_SongList2:*****${_songList2}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
  }

  void _initAudioPlayer() {
    audioPlayer = new AudioPlayer();

    audioPlayer.durationHandler = (d) => setState(() {
          duration = d;
        });

    audioPlayer.positionHandler = (p) => setState(() {
          position = p;
        });

    audioPlayer.completionHandler = () {
      onComplete();
      setState(() {
        position = duration;
      });
    };

    audioPlayer.errorHandler = (msg) {
      print('audioPlayer error : $msg');
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      playerState = PlayerState.stopped;
      isPlaying = false;
    });
  }

  getGroupsMember() async {
    try {
      http.Response response = await http.post(
          "http://54.200.143.85:4200/getJoinedArray",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"dialog_id": '${this.peerId}'}));
      var groupMembers = jsonDecode(response.body);
      if (groupMembers['success'] == true) {
        print('Group members :res*****:${groupMembers['data']}');
        groupMembersArr = groupMembers['data'];
        print('Group members :added*****:${groupMembers['data']}');
      }
    } catch (e) {}
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        // isShowSticker = false; //
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? ''; //id
    print('MY USER ID: ${this.myId}');
    this.myName = prefs.getString('userName');
    setState(() {});
  }

  Future getCameraImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      setState(() {
        isLoading = false;
      });
      uploadImageFile();
    }
  }

  Future getGalleryImage() async {
    // image compressor code
    // File compressedFile =await ImagePicker.pickImage(source: ImageSource.gallery);
    // imageFile = await FlutterNativeImage.compressImage(compressedFile.path,
    //     quality: 95, percentage: 95);

    // if (imageFile != null) {
    //   setState(() {
    //     isLoading = false;
    //   });
    //   uploadImageFile();
    // }
    print('in get gallery image');
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        isLoading = false;
      });
      uploadImageFile();
    }
  }

  Future getCameraVideo() async {
    print('in get camera video');
    var originalVideoUrl =
        await ImagePicker.pickVideo(source: ImageSource.camera);
    print('Original Video ******: ${originalVideoUrl.path}');
    setState(() {
      isLoading = false;
    });

    _compressVideo(originalVideoUrl.path).then((value) {
      print('Compress Video: ${value}');
      imageFile = new File(value);
      if (imageFile != null) {
        uploadVideoFile();
      }
    }).catchError((error) {
      print('Error Compressing: ${error}');
    });
  }

  Future getGalleryVideo() async {
    var originalVideoUrl =
        await ImagePicker.pickVideo(source: ImageSource.gallery);
    print('Original Video ******: ${originalVideoUrl.path}');
    setState(() {
      isLoading = false;
    });
    _compressVideo(originalVideoUrl.path).then((value) {
      print('Compress Video: ${value}');
      imageFile = new File(value);
      if (imageFile != null) {
        uploadVideoFile();
      }
    }).catchError((error) {
      print('Error Compressing: ${error}');
    });
  }

  Future<String> _compressVideo(String originalVideoUrl) async {
    print('im compressing your video');
    var compressedVideoUrl;
    var platform = const MethodChannel("plmlogix.recordvideo/info");

    var data = <String, dynamic>{
      'originalVideoUrl': originalVideoUrl,
    };

    try {
      compressedVideoUrl = await platform.invokeMethod('compressVideo', data);
    } catch (e) {
      print(e);
    }
    return compressedVideoUrl;
  }

  // Future getCameraVideo() async {
  //   imageFile = await ImagePicker.pickVideo(source: ImageSource.camera);
  //   // print('IMAGEFILE ******: ${imageFile}');
  //   if (imageFile != null) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     uploadVideoFile();
  //   }
  // }

  // Future getGalleryVideo() async {
  //   print('in get gallery video');
  //   imageFile = await ImagePicker.pickVideo(source: ImageSource.gallery);
  //   if (imageFile != null) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     uploadVideoFile();
  //   }
  // }

  Future uploadVideoFile() async {
    setState(() {
      this.isLoading = true;
    });

    var result = await http.get('http://54.200.143.85:4200/time');
    var res = jsonDecode(result.body);
    print('TimeStamp got:-----${res['timestamp']}');
    timestamp = res['timestamp'];
    print('TimeStamp set:-----${timestamp}');

    print('VideoFILE ******: ${imageFile}');
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse("http://54.200.143.85:4200/uploadVideo");

    var request = new http.MultipartRequest("POST", uri);
    request.headers["time"] = timestamp;
    request.headers["dialogId"] = peerId;
    request.headers["senderId"] = this.myId;
    request.headers["type"] = "group";

    var multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    request.send().then((onValue) {
      // setState(() {
      //   this.isLoading = false;
      // });
    });

    onSendMessage(
        "http://54.200.143.85:4200/Media/Videos/${peerId}/${timestamp}.mp4",
        2,
        timestamp);
  }

  Future uploadImageFile() async {
    print('in upload image ()..');
    setState(() {
      this.isLoading = true;
    });

    var result = await http.get('http://54.200.143.85:4200/time');
    var res = jsonDecode(result.body);
    print('..............${res['timestamp'].runtimeType}');
    timestamp = res['timestamp'];

    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));

    var length = await imageFile.length();

    var uri = Uri.parse("http://54.200.143.85:4200/uploadImage");

    var request = new http.MultipartRequest("POST", uri);
    // timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    request.headers["time"] = timestamp;
    request.headers["dialogId"] = peerId;
    request.headers["senderId"] = this.myId;
    request.headers["type"] = "group";
    request.headers["sendername"] = this.myName;

    var multipartFile =
        http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    var response = await request.send();

    response.stream.transform(utf8.decoder).listen((value) {});
    setState(() {
      // isLoading = false;
      onSendMessage(
          "http://54.200.143.85:4200/Media/Images/${peerId}/${timestamp}.jpeg",
          1,
          timestamp);
    });
  }

  void onTextMessage(String content, int type) async {
    var result = await http.get('http://54.200.143.85:4200/time');
    var res = jsonDecode(result.body);
    print('..............${res['timestamp'].runtimeType}');
    timestamp =
        // DateTime.now().millisecondsSinceEpoch.toString();
        res['timestamp'];

    if (content.trim() != '') {
      textEditingController.clear();
      var documentReference = Firestore.instance
          .collection('groups')
          .document(this.peerId)
          .collection(this.peerId)
          .document(
              timestamp); //DateTime.now().millisecondsSinceEpoch.toString()
      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': this.myId,
            'idTo': this.peerId,
            'timestamp': timestamp,
            'msg': content,
            'type': type,
            'members': groupMembersArr,
            'senderName': this.myName,
            'groupName': groupName
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  void onSendMessage(String content, int type, time) {
    print('in ontextMsg.......send: ${content}');
    print('TimeStamp got in onSend():-----${timestamp}');

    // timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('groups')
          .document(this.peerId)
          .collection(this.peerId)
          .document(time);

      if (type == 2) {
        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'senderId': this.myId,
              'idTo': this.peerId,
              'timestamp': time,
              'msg': content,
              'type': type,
              'members': groupMembersArr,
              'senderName': this.myName,
              'groupName': groupName,
              'thumbnail': "http://54.200.143.85:4200/Media/Frames/" +
                  this.peerId +
                  "/" +
                  time +
                  "_1.jpg"
            },
          );
        }).then((onValue) {
          setState(() {
            this.isLoading = false;
          });
          print(
              'video added in firebase..------------------------------------------------');
        });
        listScrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        //img
        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'senderId': this.myId,
              'idTo': this.peerId,
              'timestamp': time,
              'msg': content,
              'type': type,
              'members': groupMembersArr,
              'senderName': this.myName,
              'groupName': groupName
            },
          );
        }).then((onValue) {
          setState(() {
            this.isLoading = false;
          });
          print(
              'img added in firebase..------------------------------------------------');
        });
      }
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['senderId'] == this.myId) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ?
              // ClipPath(
              //   clipper: CustomShapeClipper(),
              //     child:
              Container(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(document['senderName'],
                                style: new TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            DateFormat('dd MMM kk:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(document['timestamp']) * 1000)),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      new Container(
                        margin: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          document['msg'],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                  width: 200.0,
                  margin: EdgeInsets.only(
                    bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: greyColor2,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )
              : document['type'] == 1
                  // Image
                  ? Container(
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(document['senderName'],
                                    overflow: TextOverflow.ellipsis,
                                    style: new TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(document['timestamp']) *
                                            1000)),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          Padding(padding: EdgeInsets.symmetric(vertical: 5.0)),
                          Material(
                            child: GestureDetector(
                              onTap: () {
                                print(document['msg']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShowImage(
                                          url: document['msg'],
                                        ),
                                  ),
                                );
                              },
                              child: CachedNetworkImage(
                                placeholder: Container(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        themeColor),
                                  ),
                                  width: 200.0,
                                  height: 200.0,
                                  padding: EdgeInsets.all(70.0),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[100],
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                  ),
                                ),
                                errorWidget: Material(
                                  child: Image.asset(
                                    'images/no_img.png',
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                ),
                                imageUrl: document['msg'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                      width: 200.0,
                      margin: EdgeInsets.only(
                        bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      ),
                      decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.circular(8.0)),
                    )

                  // Video
                  : document['type'] == 2
                      ? Container(
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(document['senderName'],
                                        style: new TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Text(
                                    // document['timestamp'],
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5.0)),
                              Container(
                                  width: double.infinity,
                                  height: 142.0,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    ),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image:
                                          NetworkImage(document['thumbnail']),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      size: 60.0,
                                      color: Colors.white,
                                    ),
                                    onTap: () {
                                      print('opening video');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayScreen(
                                              url: document['msg'],
                                              type: 'network'),
                                        ),
                                      );
                                    },
                                  )),
                            ],
                          ),
                          width: 250.0,
                          height: 180.0,
                          decoration: BoxDecoration(
                            color: greyColor2,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                          margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                            // right: 10.0
                          ),
                        )

                      // playSong  audio long....short
                      : document['type'] == 3
                          ? Container(
                              height: 103.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(document['senderName'],
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  Container(
                                    height: 60.0,
                                    width: 60.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    child: GestureDetector(
                                      child: playPauseIcon(document['msg']
                                              .toString()
                                              .replaceAll(
                                                  'http://54.200.143.85:4200/AudioChat/',
                                                  '')) //isPlaying
                                          ? Container(
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  LayoutBuilder(builder:
                                                      (context, constraint) {
                                                    return new Icon(
                                                      Icons.pause,
                                                      size: 40.0,
                                                      color: Colors.white,
                                                    );
                                                  }),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  Image.asset(
                                                      'assets/short.png',
                                                      width: 40.0,
                                                      height: 40.0)
                                                ],
                                              ),
                                            ),
                                      onTapUp: (TapUpDetails details) {
                                        print("onTapUp");
                                        isPlaying
                                            ? stop()
                                            : play(
                                                document['msg'].toString(),
                                                document['msg']
                                                    .toString()
                                                    .replaceAll(
                                                        'http://54.200.143.85:4200/AudioChat/',
                                                        ''));
                                      },
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            )
                          :
                          // playSong  audio ...long   type = 4
                          Container(
                              height: 103.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  Container(
                                    height: 60.0,
                                    width: 60.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    child: GestureDetector(
                                      child: playPauseIcon(document['msg']
                                              .toString()
                                              .replaceAll(
                                                  'http://54.200.143.85:4200/Audio/',
                                                  ''))
                                          ? Container(
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  LayoutBuilder(builder:
                                                      (context, constraint) {
                                                    return new Icon(
                                                      Icons.pause,
                                                      size: 40.0,
                                                      color: Colors.white,
                                                    );
                                                  }),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0),
                                                ),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  LayoutBuilder(builder:
                                                      (context, constraint) {
                                                    return new Icon(
                                                      Icons.music_note,
                                                      size: 40.0,
                                                      color: Colors.white,
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                      onTapUp: (TapUpDetails details) {
                                        print("onTapUp");
                                        isPlaying
                                            ? stop()
                                            : play(
                                                document['msg'].toString(),
                                                document['msg']
                                                    .toString()
                                                    .replaceAll(
                                                        'http://54.200.143.85:4200/Audio/',
                                                        ''));
                                      },
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                        child:
                        
                         CachedNetworkImage(
                          placeholder: Container(
                            width: 50.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                          ),
                          imageUrl: 'http://54.200.143.85:4200/profiles/then/' +
                              document['senderId'] +
                              '.jpg',
                          width: 50.0,
                          height: 50.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(50.0),
                        ),
                        
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(width: 50.0),
                document['type'] == 0
                    //txt
                    ? Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  DateFormat('dd MMM kk:mm').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(document['timestamp']) *
                                              1000)),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            new Container(
                              margin: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                document['msg'],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 5.0 : 10.0,
                            left: 5.0),
                      )
                    : document['type'] == 1
                        //img
                        ? Container(
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(document['senderName'],
                                          style: new TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      DateFormat('dd MMM kk:mm').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              int.parse(document['timestamp']) *
                                                  1000)),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                                Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 5.0)),
                                Material(
                                  child: GestureDetector(
                                    onTap: () {
                                      print(document['msg']);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShowImage(
                                                url: document['msg'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: CachedNetworkImage(
                                      placeholder: Container(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  themeColor),
                                        ),
                                        width: 200.0,
                                        height: 200.0,
                                        padding: EdgeInsets.all(70.0),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo[100],
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8.0),
                                          ),
                                        ),
                                      ),
                                      errorWidget: Material(
                                        child: Image.asset(
                                          'images/no_img.png',
                                          width: 200.0,
                                          height: 200.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                      ),
                                      imageUrl: document['msg'],
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                  clipBehavior: Clip.hardEdge,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                            width: 200.0,
                            decoration: BoxDecoration(
                                color: Colors.indigo[100],
                                borderRadius: BorderRadius.circular(8.0)),
                            margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 5.0 : 10.0,
                                left: 5.0),
                          )

                        // video
                        : document['type'] == 2
                            ? Container(
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(document['senderName'],
                                              style: new TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5.0)),
                                    Container(
                                      width: double.infinity,
                                      height: 142.0,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15.0),
                                        ),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(
                                              document['thumbnail']),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          size: 60.0,
                                          color: Colors.white,
                                        ),
                                        onTap: () {
                                          print(
                                              'opening video : ${document['thumbnail']}');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PlayScreen(
                                                  url: document['msg'],
                                                  type: 'network'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                width: 250.0,
                                height: 180.0,
                                decoration: BoxDecoration(
                                  color: Colors.indigo[100],
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15.0),
                                  ),
                                ),
                                padding:
                                    EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                                margin: EdgeInsets.only(
                                    bottom:
                                        isLastMessageRight(index) ? 5.0 : 10.0,
                                    left: 5.0),
                              )

                            //audio long....short
                            : document['type'] == 3
                                ? Container(
                                    height: 103.0,
                                    width: 130.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(
                                        bottom: isLastMessageRight(index)
                                            ? 5.0
                                            : 10.0,
                                        left: 5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                  document['senderName'],
                                                  style: new TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: 60.0,
                                          width: 60.0,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            child: playPauseIcon(document['msg']
                                                    .toString()
                                                    .replaceAll(
                                                        'http://54.200.143.85:4200/AudioChat/',
                                                        ''))
                                                ? Container(
                                                    margin: EdgeInsets.all(3),
                                                    padding: EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8.0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: <Widget>[
                                                        LayoutBuilder(builder:
                                                            (context,
                                                                constraint) {
                                                          return new Icon(
                                                            Icons.pause,
                                                            size: 40.0,
                                                            color: Colors.white,
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  )
                                                : Container(
                                                    margin: EdgeInsets.all(3),
                                                    padding: EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8.0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: <Widget>[
                                                        Image.asset(
                                                            'assets/short.png',
                                                            width: 40.0,
                                                            height: 40.0)
                                                      ],
                                                    ),
                                                  ),
                                            onTapUp: (TapUpDetails details) {
                                              print("onTapUp");
                                              isPlaying
                                                  ? stop()
                                                  : play(
                                                      document['msg']
                                                          .toString(),
                                                      document['msg']
                                                          .toString()
                                                          .replaceAll(
                                                              'http://54.200.143.85:4200/AudioChat/',
                                                              ''));
                                            },
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  )
//type 4....long
                                : Container(
                                    height: 103.0,
                                    width: 130.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(
                                        bottom: isLastMessageRight(index)
                                            ? 5.0
                                            : 10.0,
                                        left: 5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                  document['senderName'],
                                                  style: TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 2.0)),
                                        GestureDetector(
                                          child: Row(
                                            children: <Widget>[
                                              playPauseIcon(document['msg']
                                                      .toString()
                                                      .replaceAll(
                                                          'http://54.200.143.85:4200/Audio/',
                                                          '')) //isPlaying
                                                  ? Container(
                                                      margin: EdgeInsets.all(3),
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8.0),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraint) {
                                                            return Icon(
                                                              Icons.pause,
                                                              size: 40.0,
                                                              color:
                                                                  Colors.white,
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    )
                                                  : Container(
                                                      margin: EdgeInsets.all(3),
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8.0),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraint) {
                                                            return Icon(
                                                              Icons.music_note,
                                                              size: 40.0,
                                                              color:
                                                                  Colors.white,
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    )
                                            ],
                                          ),
                                          onTapUp: (TapUpDetails details) {
                                            print("onTapUp");
                                            isPlaying
                                                ? stop()
                                                : play(
                                                    document['msg'].toString(),
                                                    document['msg']
                                                        .toString()
                                                        .replaceAll(
                                                            'http://54.200.143.85:4200/Audio/',
                                                            ''));
                                          },
                                        ),
                                        Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  ),
              ],
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool playPauseIcon(songName) {
    print(
        '--------------------------------------------------------------${songName}');
    if (songName == playingSongInList && isPlaying) {
      return true;
    } else
      return false;
  }

  //song play stop pause
  Future<int> play(url, songName) async {
    print('in play():${songName}');
    final result = await audioPlayer.play(url, isLocal: false);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        isPlaying = true;
        playingSongInList = songName;
        print('playing');
      });
    return result;
  }

  Future<int> pause() async {
    final result = await audioPlayer.pause();
    if (result == 1) setState(() => playerState = PlayerState.paused);
    return result;
  }

  Future<int> stop() async {
    final result = await audioPlayer.stop();
    if (result == 1) {
      setState(() {
        playerState = PlayerState.stopped;
        position = new Duration();
        isPlaying = false;
      });
    }
    return result;
  }

  bool isLastMessageLeft(int index) {
    // print('in last msg idx == ${index}..${listMessage.runtimeType}');
    print(
        '${index}:${listMessage[index]['msg']}:${listMessage[index]['senderId'] == this.myId}:${listMessage.length}');
    // print('index -1 : ${listMessage[index - 1]['senderId'] == this.myId}');
    // if(index == listMessage.length-1 && listMessage[index]['senderId'] != this.myId){
    //   print('-----------------------------------------------------------------------${index}');
    //   return true;
    // }else
    if ((index > 0 &&
            index < listMessage.length - 1 &&
            listMessage != null &&
            listMessage[index + 1]['senderName'] !=
                listMessage[index]['senderName']
        // listMessage[index + 1]['senderId'] != this.myId
        ) ||
        (index == listMessage.length - 1 &&
            listMessage[index]['senderId'] != this.myId)) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['senderId'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    // if (isShowSticker) {
    //   setState(() {
    //     isShowSticker = false;
    //   });
    // } else {
    Navigator.pop(context);
    // }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              songList(width), //short

              songlist2(width), //long

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  songList(width) {
    //type 3
    if (isSearching) {
      //isSearching // == true && showShortSongsLongSongs == true
      return Container(
        color: Colors.deepPurple[50],
        height: 50.0,
        width: width,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: searchresult.length,
          itemBuilder: (BuildContext context, int index) {
            String listData = searchresult[index];
            return GestureDetector(
              child: Row(
                children: <Widget>[
                  playPauseIcon(listData)
                      ? Icon(Icons.pause_circle_outline)
                      : Image.asset('assets/short.png',
                          width: 25.0, height: 25.0),
                  //Icon(Icons.play_circle_outline),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 5.0, 0.0),
                  ),
                  Text(
                    listData.replaceAll('.mp3', ''),
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                  )
                ],
              ),
              onTapUp: (TapUpDetails details) {
                print("onTapUp");
                isPlaying
                    ? stop()
                    : play(
                        "http://54.200.143.85:4200/AudioChat/" +
                            listData.toString(),
                        listData);
              },
              onLongPress: () {
                print("onLongPress");
                onTextMessage(
                    "http://54.200.143.85:4200/AudioChat/" +
                        listData.toString(),
                    3);
              },
            );
          },
        ),
      );
    } else
      return Container();
    // Text('');
  }

  songlist2(width) {
    if (isSearching) {
      //== true && showShortSongs  == true
      return Container(
        color: Colors.blue[50],
        height: 50.0,
        width: width,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: songSearchresult2.length,
          itemBuilder: (BuildContext context, int index) {
            String listData = songSearchresult2[index];
            return GestureDetector(
              child: Row(
                children: <Widget>[
                  playPauseIcon(listData)
                      ? Icon(Icons.pause_circle_outline)
                      : Icon(Icons.music_note), //play_circle_outline
                  Text(
                    listData.replaceAll('.mp3', ''),
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                  )
                ],
              ),
              onTapUp: (TapUpDetails details) {
                print("onTapUp");
                isPlaying
                    ? stop()
                    : play(
                        "http://54.200.143.85:4200/Audio/" +
                            listData.toString(),
                        listData);
              },
              onLongPress: () {
                print("onLongPress"); //add loading true

                onTextMessage(
                    "http://54.200.143.85:4200/Audio/" + listData.toString(),
                    4);
              },
            );
          },
        ),
      );
    } else
      return Container();
    //  Text('');
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    // valueColor: AlwaysStoppedAnimation<Color>(themeColor)
                    ),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Column(
        children: <Widget>[
          !isSearching
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // Button send image
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.image),
                          onPressed: getGalleryImage,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.video_library),
                          onPressed: getGalleryVideo,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.photo_camera),
                          onPressed: getCameraImage,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.videocam),
                          onPressed: getCameraVideo,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                  ],
                )
              : Text(''),
          Row(
            children: <Widget>[
              // new Container(
              //   child: new IconButton(
              //     icon: new Icon(Icons.image),
              //     onPressed:
              //         // openOptions(),
              //         openBottomSheet(),
              //     color: primaryColor,
              //   ),
              // ),
              // Button send image
              Padding(
                padding: EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
              ),
              Flexible(
                child: Container(
                    decoration: BoxDecoration(
                        color: greyColor2,
                        borderRadius: BorderRadius.circular(50.0)),
                    padding: EdgeInsets.all(15.0),
                    // margin: EdgeInsets.all(1.0),
                    child: GestureDetector(
                      child: TextField(
                        style: TextStyle(color: primaryColor, fontSize: 15.0),
                        controller: textEditingController,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        onChanged: searchOperation,
                        focusNode: focusNode,
                        onTap: () {
                          print('ontapp...................---------------');
                          this.isSearching = true;
                          // this.showShortSongs = true;
                          // this.showShortSongsLongSongs = true;
                          searchOperation('a');
                        },
                      ),
                    )),
              ),
              // Button send message
              // Material(
              // child:
              Container(
                decoration: BoxDecoration(
                    color: Colors.indigo[900],
                    borderRadius: BorderRadius.circular(50.0)),
                margin: new EdgeInsets.symmetric(horizontal: 8.0),
                child: new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: () => onTextMessage(textEditingController.text, 0),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
          ),
        ],
      ),
      width: double.infinity,
      height: isSearching == true ? 70.0 : 105.0,
      decoration: new BoxDecoration(
        border: new Border(top: new BorderSide(color: greyColor2, width: 0.9)),
        color: Colors.white,
      ),
    );
  }

  openBottomSheet() {
    print('in bottomsheet');
    // showModalBottomSheet(
    //     context: context,
    //     builder: (builder) {
    //       return Text('hjkhkhk');
    //     });
  }

  // not done
  openOptions() {
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
                    // File f = new File.fromUri(Uri.file(video));
                    // f.delete();
                    // Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    // Navigator.pop(context);
                    // shareVideo(video, i); //file object
                  },
                )
              ],
            ),
            height: 60.0,
          );
        });
  }
  //

  Widget buildListMessage() {
    return Flexible(
      child: this.peerId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('groups')
                  .document(this.peerId)
                  .collection(this.peerId)
                  .orderBy('timestamp', descending: true)
                  // .limit(2)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  print(
                      'Snapshot Length :***********8 ${snapshot.data.documents.length}');
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.only(left: 3.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    songSearchresult2.clear();

    if (isSearching != null) {
      //make it false !null
      for (int i = 0; i < _songList1.length; i++) {
        String data = _songList1[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          searchresult.add(data); //remove .mp4  nt here
        }
      }

      // if(searchresult.isEmpty){
      //   this.showShortSongs = false;
      // }

      for (int i = 0; i < _songList2.length; i++) {
        String data = _songList2[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          songSearchresult2.add(data);
          print('****songSearchresult2 added :: ${songSearchresult2}');
          //remove .mp4  nt here
        }
        //   if(songSearchresult2.isEmpty){
        //   this.showShortSongsLongSongs = false;
        // }
      }

      if (searchresult.length == 0 && songSearchresult2.length == 0) {
        isSearching = false;
      }
    }

    print('****songSearchresult2 :: ${songSearchresult2}');
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = new Path();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClip) => false;
}
