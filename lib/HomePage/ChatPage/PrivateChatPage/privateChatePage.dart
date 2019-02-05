// mismatch in isplaying and songisplaying
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../const.dart';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/services.dart';
import '../playVideo.dart';
import 'userInfoPage.dart';

import 'package:audioplayers/audioplayers.dart';
// import '../../../PlayAudio/play.dart';
import '../../pages/showImage.dart';
import '../../../ProfilePage/profile.dart';

//..
class ChatPrivate extends StatefulWidget {
  // static const platform = const MethodChannel('plmlogix.recordvideo/info');
  final String chatId;
  final String name;
  final String chatType, receiverPin;
  final String mobile;

  ChatPrivate(
      {Key key,
      @required this.chatId,
      @required this.chatType,
      @required this.name,
      @required this.receiverPin,
      @required this.mobile})
      : super(key: key);

  @override
  State createState() => new ChatPrivateState(
      chatId: chatId,
      chatType: chatType,
      name: name,
      receiverPin: receiverPin,
      mobile: mobile);
}

enum PlayerState { stopped, playing, paused }

class ChatPrivateState extends State<ChatPrivate> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info');
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  ChatPrivateState(
      {Key key,
      @required this.chatId,
      @required this.chatType,
      @required this.name,
      @required this.receiverPin,
      @required this.mobile}) {
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

  String chatId;
  String receiverPin;
  String chatType, mobile;
  String name;

  String id;
  String myId;
  String myName;
  String myPhone;
  var listMessage, timestamp;
  SharedPreferences prefs;
  String userToken;

  File imageFile;
  bool isLoading;
  String imageUrl;
  VideoPlayerController controller;
  bool isPlaying = false;

  //#songList
  bool isSearching = false;
  List searchresult = new List();

  List songSearchresult2 = new List();

  List<dynamic> _songList1;
  List<dynamic> _songList2;

  String searchText = "";
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

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    print('in privateChat');
    isSearching = false;
    isLoading = false;
    imageUrl = '';
    timestamp = '';
    values();
    _initAudioPlayer();
    readLocal();
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
    //on audioplaying complete
    setState(() {
      playerState = PlayerState.stopped;
      isPlaying = false;
    });
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? ''; //id
    this.userToken = prefs.getString('UserToken');
    this.myName = prefs.getString('userName');
    this.myPhone = prefs.getString('userPhone');
    setState(() {});
    print('MY USER ID: ${this.myId}');
    print('MY phone:***** ${this.myPhone}');
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
    //   File compressedFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    //  imageFile = await FlutterNativeImage.compressImage(
    //      compressedFile.path,
    //      quality: 80,
    //      percentage: 50);

    //  if (imageFile != null) {
    //    setState(() {
    //      isLoading = false;
    //    });
    //    uploadImageFile();
    //  }
    print('in get gallery private');
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
  //   if (imageFile != null) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     uploadVideoFile();
  //   }
  // }

  // Future getGalleryVideo() async {
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
    request.headers["dialogId"] = chatId;
    request.headers["senderId"] = this.myId;
    request.headers["type"] = "private";

    // print("^^^^^^^^^${timestamp}");
    var multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    // send
    var response = await request.send();
    print('multipart response::${response.statusCode}');

    response.stream.transform(utf8.decoder).listen((value) {
      //
      print(value);
    });
    // StorageReference reference =
    //     FirebaseStorage.instance.ref().child(timestamp + "test"); //
    setState(() {
      // isLoading = false;
      print('${imageUrl}');
      onSendMessage(
          "http://54.200.143.85:4200/Media/Videos/${chatId}/${timestamp}.mp4",
          2,
          timestamp);
    });
  }

  Future uploadImageFile() async {
    print('in uploal private');
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
    request.headers["dialogId"] = chatId;
    request.headers["senderId"] = this.myId;
    request.headers["type"] = "private";
    request.headers["sendername"] = this.myName;

    // print("^^^^^^^^^${timestamp}");
    var multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    // send
    var response = await request.send();
    print(response.statusCode);

    response.stream.transform(utf8.decoder).listen((value) {
      //
      print(value);
    });
    // StorageReference reference =
    //     FirebaseStorage.instance.ref().child(timestamp); //
    setState(() {
      // isLoading = false;
      print('${imageUrl}');
      onSendMessage(
          "http://54.200.143.85:4200/Media/Images/${chatId}/${timestamp}.jpeg",
          1,
          timestamp);
    });
  }

  void onTextMessage(String content, int type) async {
    var result = await http.get('http://54.200.143.85:4200/time');
    var res = jsonDecode(result.body);
    print('..............${res['timestamp'].runtimeType}');
    timestamp = res['timestamp'];

    // timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('Private')
          .document(this.chatId)
          .collection(this.chatId)
          .document(
              timestamp); //DateTime.now().millisecondsSinceEpoch.toString()

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': this.myId,
            'idTo': this.chatId,
            'receiverPin': this.receiverPin,
            'timestamp': timestamp,
            'msg': content,
            'type': type,
            'senderName': this.myName
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

    if (content.trim() != '') {
      textEditingController.clear();
      var documentReference = Firestore.instance
          .collection('Private')
          .document(this.chatId)
          .collection(this.chatId)
          .document(time); //DateTime.now().millisecondsSinceEpoch.toString()

      if (type == 2) {
        //vid
        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'senderId': this.myId,
              'receiverPin': this.receiverPin,
              'idTo': this.chatId,
              'timestamp': time,
              'msg': content,
              'type': type,
              'senderName': this.myName,
              'thumbnail': "http://54.200.143.85:4200/Media/Frames/" +
                  this.chatId +
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
      } else {
        //img
        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'senderId': this.myId,
              'receiverPin': this.receiverPin,
              'idTo': this.chatId,
              'timestamp': time,
              'msg': content,
              'type': type,
              'senderName': this.myName
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
      print('msg sent' + this.myName);
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  //  void onSendMessage(String content, int type, time) {
  //   print('in ontextMsg.......send: ${content}');
  //   print('TimeStamp got in onSend():-----${timestamp}');

  //   // timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  //   if (content.trim() != '') {
  //     textEditingController.clear();

  //     var documentReference = Firestore.instance
  //         .collection('groups')
  //         .document(this.peerId)
  //         .collection(this.peerId)
  //         .document(time);

  //     if (type == 2) {
  //       Firestore.instance.runTransaction((transaction) async {
  //         await transaction.set(
  //           documentReference,
  //           {
  //             'senderId': this.myId,
  //             'idTo': this.peerId,
  //             'timestamp': time,
  //             'msg': content,
  //             'type': type,
  //             'members': groupMembersArr,
  //             'senderName': this.myName,
  //             'groupName': groupName,
  //             'thumbnail': "http://54.200.143.85:4200/Media/Frames/" +
  //                 this.peerId +
  //                 "/" +
  //                 time +
  //                 "_1.jpg"
  //           },
  //         );
  //       }).then((onValue) {
  //         setState(() {
  //           this.isLoading = false;
  //         });
  //         print(
  //             'video added in firebase..------------------------------------------------');
  //       });
  //     } else {
  //       //img
  //       Firestore.instance.runTransaction((transaction) async {
  //         await transaction.set(
  //           documentReference,
  //           {
  //             'senderId': this.myId,
  //             'idTo': this.peerId,
  //             'timestamp': time,
  //             'msg': content,
  //             'type': type,
  //             'members': groupMembersArr,
  //             'senderName': this.myName,
  //             'groupName': groupName
  //           },
  //         );
  //       }).then((onValue) {
  //         setState(() {
  //           this.isLoading = false;
  //         });
  //         print(
  //             'img added in firebase..------------------------------------------------');
  //       });
  //     }
  //     listScrollController.animateTo(0.0,
  //         duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  //   } else {
  //     Fluttertoast.showToast(msg: 'Nothing to send');
  //   }
  // }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['senderId'] == this.myId) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
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
              // Column(
              //     crossAxisAlignment: CrossAxisAlignment.end,
              //     children: <Widget>[
              //         Text(
              //           DateFormat('dd MMM kk:mm').format(
              //               DateTime.fromMillisecondsSinceEpoch(
              //                   int.parse(document['timestamp']))),
              //           style: TextStyle(
              //               color: greyColor,
              //               fontSize: 12.0,
              //               fontStyle: FontStyle.italic),
              //         ),
              //         Container(
              //           child: Text(
              //             document['msg'],
              //             style: TextStyle(color: primaryColor),
              //           ),
              //           padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              //           width: 200.0,
              //           decoration: BoxDecoration(
              //               color: greyColor2,
              //               borderRadius: BorderRadius.circular(8.0)),
              //           margin: EdgeInsets.only(
              //             bottom: isLastMessageRight(index) ? 20.0 : 10.0,
              //             // right: 10.0
              //           ),
              //         ),
              //       ])

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

                  // Column(
                  //     crossAxisAlignment: CrossAxisAlignment.end,
                  //     children: <Widget>[
                  //         Text(
                  //           DateFormat('dd MMM kk:mm').format(
                  //               DateTime.fromMillisecondsSinceEpoch(
                  //                   int.parse(document['timestamp']))),
                  //           style: TextStyle(
                  //               color: greyColor,
                  //               fontSize: 12.0,
                  //               fontStyle: FontStyle.italic),
                  //         ),
                  //         Container(
                  //           child: GestureDetector(
                  //             onTap: () {
                  //               print(document['msg']);
                  //               Navigator.push(
                  //                 context,
                  //                 MaterialPageRoute(
                  //                   builder: (context) => ShowImage(
                  //                         url: document['msg'],
                  //                       ),
                  //                 ),
                  //               );
                  //             },
                  //             child: Material(
                  //               child: CachedNetworkImage(
                  //                 placeholder: Container(
                  //                   child: CircularProgressIndicator(
                  //                     valueColor: AlwaysStoppedAnimation<Color>(
                  //                         themeColor),
                  //                   ),
                  //                   width: 200.0,
                  //                   height: 200.0,
                  //                   padding: EdgeInsets.all(70.0),
                  //                   decoration: BoxDecoration(
                  //                     color: greyColor2,
                  //                     borderRadius: BorderRadius.all(
                  //                       Radius.circular(8.0),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 errorWidget: Material(
                  //                   child: Image.asset(
                  //                     'images/no_img.png',
                  //                     width: 200.0,
                  //                     height: 200.0,
                  //                     fit: BoxFit.cover,
                  //                   ),
                  //                   borderRadius: BorderRadius.all(
                  //                     Radius.circular(8.0),
                  //                   ),
                  //                   clipBehavior: Clip.hardEdge,
                  //                 ),
                  //                 imageUrl: document['msg'],
                  //                 width: 200.0,
                  //                 height: 200.0,
                  //                 fit: BoxFit.cover,
                  //               ),
                  //               borderRadius:
                  //                   BorderRadius.all(Radius.circular(8.0)),
                  //               clipBehavior: Clip.hardEdge,
                  //             ),
                  //           ),
                  //           margin: EdgeInsets.only(
                  //             bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                  //             // right: 10.0
                  //           ),
                  //         ),
                  //       ])

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
                                  //)  SizedBox(
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
                                  // child: RaisedButton(
                                  //   shape: new RoundedRectangleBorder(
                                  //       borderRadius:
                                  //           new BorderRadius.circular(15.0)),
                                  //   textColor: Colors.white,
                                  //   color: Colors.black87,
                                  //   onPressed: () {
                                  //     print('*******VIDEO....${document['msg']}');
                                  //     Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (context) => PlayScreen(
                                  //             url: document['msg'],
                                  //             type: 'network'),
                                  //       ),
                                  //     );
                                  //   },
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
                                  )
                                  // child: Icon(
                                  //   Icons.play_circle_filled,
                                  //   size: 60.0,
                                  //   color: Colors.white,
                                  // ),
                                  // ),
                                  ),
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
                      //  Column(
                      //     crossAxisAlignment: CrossAxisAlignment.end,
                      //     children: <Widget>[
                      //         Text(
                      //           DateFormat('dd MMM kk:mm').format(
                      //               DateTime.fromMillisecondsSinceEpoch(
                      //                   int.parse(document['timestamp']))),
                      //           style: TextStyle(
                      //               color: greyColor,
                      //               fontSize: 12.0,
                      //               fontStyle: FontStyle.italic),
                      //         ),
                      //         Container(
                      //           child: RaisedButton(
                      //             // padding: const EdgeInsets.all(8.0),
                      //             shape: new RoundedRectangleBorder(
                      //                 borderRadius:
                      //                     new BorderRadius.circular(15.0)),
                      //             textColor: Colors.white,
                      //             color: Colors.black87,
                      //             onPressed: () {
                      //               // print('*******VIDEO....${document['msg']}');
                      //               Navigator.push(
                      //                 context,
                      //                 MaterialPageRoute(
                      //                   builder: (context) => PlayScreen(
                      //                       url: document['msg'],
                      //                       type: 'network'),
                      //                 ),
                      //               );
                      //             },
                      //             child: Icon(
                      //               Icons.play_circle_filled,
                      //               size: 60.0,
                      //               color: Colors.white,
                      //             ),
                      //           ),
                      //           width: 250.0,
                      //           height: 144.0,
                      //           decoration: BoxDecoration(
                      //             color: greyColor2,
                      //             borderRadius: BorderRadius.all(
                      //               Radius.circular(15.0),
                      //             ),
                      //           ),
                      //           margin: EdgeInsets.only(
                      //             bottom:
                      //                 isLastMessageRight(index) ? 20.0 : 10.0,
                      //             // right: 10.0
                      //           ),
                      //         )
                      //       ])
                      //playSongs ....short
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
                                                    return Icon(
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
                          // Column(
                          //     crossAxisAlignment: CrossAxisAlignment.end,
                          //     children: <Widget>[
                          //       Text(
                          //         DateFormat('dd MMM kk:mm').format(
                          //             DateTime.fromMillisecondsSinceEpoch(
                          //                 int.parse(document['timestamp']))),
                          //         style: TextStyle(
                          //             color: greyColor,
                          //             fontSize: 12.0,
                          //             fontStyle: FontStyle.italic),
                          //       ),
                          //       Container(
                          //         height: 60.0,
                          //         width: 60.0,
                          //         decoration: BoxDecoration(
                          //           borderRadius: BorderRadius.all(
                          //             Radius.circular(8.0),
                          //           ),
                          //         ),
                          //         child: GestureDetector(
                          //           child: playPauseIcon(document['msg']
                          //                   .toString()
                          //                   .replaceAll(
                          //                       'http://54.200.143.85:4200/AudioChat/',
                          //                       ''))
                          //               ? Container(
                          //                   margin: EdgeInsets.all(3),
                          //                   padding: EdgeInsets.all(5),
                          //                   decoration: BoxDecoration(
                          //                     color: Colors.black,
                          //                     borderRadius: BorderRadius.all(
                          //                       Radius.circular(8.0),
                          //                     ),
                          //                   ),
                          //                   child: Column(
                          //                     children: <Widget>[
                          //                       LayoutBuilder(builder:
                          //                           (context, constraint) {
                          //                         return new Icon(
                          //                           Icons.pause,
                          //                           size: 40.0,
                          //                           color: Colors.white,
                          //                         );
                          //                       }),
                          //                     ],
                          //                   ),
                          //                 )
                          //               : Container(
                          //                   margin: EdgeInsets.all(3),
                          //                   padding: EdgeInsets.all(5),
                          //                   decoration: BoxDecoration(
                          //                     color: Colors.deepPurple[50],
                          //                     borderRadius: BorderRadius.all(
                          //                       Radius.circular(8.0),
                          //                     ),
                          //                   ),
                          //                   child: Column(
                          //                     children: <Widget>[
                          //                       Image.asset('assets/short.png',
                          //                           width: 40.0, height: 40.0)
                          //                     ],
                          //                   ),
                          //                 ),
                          //           onTapUp: (TapUpDetails details) {
                          //             print("onTapUp");
                          //             isPlaying
                          //                 ? stop()
                          //                 : play(
                          //                     document['msg'].toString(),
                          //                     document['msg'].toString().replaceAll(
                          //                         'http://54.200.143.85:4200/AudioChat/',
                          //                         ''));
                          //           },
                          //         ),
                          //         margin: EdgeInsets.only(
                          //           bottom:
                          //               isLastMessageRight(index) ? 20.0 : 20.0,
                          //         ),
                          //       ),
                          //     ],
                          //   )

                          //type = 4 ...long audio
                          : Container(
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
          // Column(
          //     crossAxisAlignment: CrossAxisAlignment.end,
          //     children: <Widget>[
          //       Text(
          //         DateFormat('dd MMM kk:mm').format(
          //             DateTime.fromMillisecondsSinceEpoch(
          //                 int.parse(document['timestamp']))),
          //         style: TextStyle(
          //             color: greyColor,
          //             fontSize: 12.0,
          //             fontStyle: FontStyle.italic),
          //       ),
          //       Container(
          //         height: 60.0,
          //         width: 60.0,
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.all(
          //             Radius.circular(8.0),
          //           ),
          //         ),
          //         child: GestureDetector(
          //           child: playPauseIcon(document['msg']
          //                   .toString()
          //                   .replaceAll(
          //                       'http://54.200.143.85:4200/Audio/',
          //                       ''))
          //               ? Container(
          //                   margin: EdgeInsets.all(3),
          //                   padding: EdgeInsets.all(5),
          //                   decoration: BoxDecoration(
          //                     color: Colors.black,
          //                     borderRadius: BorderRadius.all(
          //                       Radius.circular(8.0),
          //                     ),
          //                   ),
          //                   child: Column(
          //                     children: <Widget>[
          //                       LayoutBuilder(builder:
          //                           (context, constraint) {
          //                         return new Icon(
          //                           Icons.pause,
          //                           size: 40.0,
          //                           color: Colors.white,
          //                         );
          //                       }),
          //                     ],
          //                   ),
          //                 )
          //               : Container(
          //                   margin: EdgeInsets.all(3),
          //                   padding: EdgeInsets.all(5),
          //                   decoration: BoxDecoration(
          //                     color: Colors.black,
          //                     borderRadius: BorderRadius.all(
          //                       Radius.circular(8.0),
          //                     ),
          //                   ),
          //                   child: Column(
          //                     children: <Widget>[
          //                       LayoutBuilder(builder:
          //                           (context, constraint) {
          //                         return new Icon(
          //                           Icons.music_note,
          //                           size: 40.0,
          //                           color: Colors.white,
          //                         );
          //                       }),
          //                     ],
          //                   ),
          //                 ),
          //           onTapUp: (TapUpDetails details) {
          //             // print("onTapUp");
          //             isPlaying
          //                 ? stop()
          //                 : play(
          //                     document['msg'].toString(),
          //                     document['msg'].toString().replaceAll(
          //                         'http://54.200.143.85:4200/Audio/',
          //                         ''));
          //           },
          //         ),
          //         margin: EdgeInsets.only(
          //           bottom:
          //               isLastMessageRight(index) ? 20.0 : 20.0,
          //         ),
          //       ),
          //     ],
          //   ),
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
                // isLastMessageLeft(index)
                //     ? Material(
                //         child: CachedNetworkImage(
                //           placeholder: Container(
                //             // padding:EdgeInsets.only(right: 15.0),
                //             child: CircularProgressIndicator(
                //               strokeWidth: 1.0,
                //               valueColor:
                //                   AlwaysStoppedAnimation<Color>(themeColor),
                //             ),
                //             width: 40.0,
                //             height: 40.0,
                //             padding: EdgeInsets.all(10.0),
                //           ),
                //           imageUrl:
                //               'http://54.200.143.85:4200/Media/Images/da2dd2kgjpm85w9n/1548247221.jpeg',
                //           width: 40.0,
                //           height: 40.0,
                //           fit: BoxFit.cover,
                //         ),
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(18.0),
                //         ),
                //         clipBehavior: Clip.hardEdge,
                //       )
                //     : Container(width: 35.0),
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
                            bottom: isLastMessageRight(index) ? 10.0 : 20.0,
                            // left: 10.0
                            ),
                      )
                    // Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: <Widget>[
                    //       Text(
                    //         DateFormat('dd MMM kk:mm').format(
                    //             DateTime.fromMillisecondsSinceEpoch(
                    //                 int.parse(document['timestamp']))),
                    //         style: TextStyle(
                    //             color: greyColor,
                    //             fontSize: 12.0,
                    //             fontStyle: FontStyle.italic),
                    //       ),
                    //       Container(
                    //         child: Text(
                    //           document['msg'],
                    //           style: TextStyle(color: primaryColor),
                    //         ),
                    //         padding:
                    //             EdgeInsets.fromLTRB(10.0, 10.0, 15.0, 10.0),
                    //         width: 200.0,
                    //         decoration: BoxDecoration(
                    //             color: Colors.indigo[100],
                    //             borderRadius: BorderRadius.circular(8.0)),
                    //       )
                    //     ],
                    //   )
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
                                bottom: isLastMessageRight(index) ? 10.0 : 20.0,
                                // left: 10.0
                                ),
                          )
                        // Container(
                        //     child: Column(
                        //         crossAxisAlignment: CrossAxisAlignment.start,
                        //         children: <Widget>[
                        //           Text(
                        //             DateFormat('dd MMM kk:mm').format(
                        //                 DateTime.fromMillisecondsSinceEpoch(
                        //                     int.parse(document['timestamp']))),
                        //             style: TextStyle(
                        //                 color: Colors.black,
                        //                 fontSize: 12.0,
                        //                 fontStyle: FontStyle.italic),
                        //           ),
                        //           Padding(
                        //               padding:
                        //                   EdgeInsets.symmetric(vertical: 5.0)),
                        //           Container(
                        //             child: GestureDetector(
                        //               onTap: () {
                        //                 print(document['msg']);
                        //                 Navigator.push(
                        //                   context,
                        //                   MaterialPageRoute(
                        //                     builder: (context) => ShowImage(
                        //                           url: document['msg'],
                        //                         ),
                        //                   ),
                        //                 );
                        //               },
                        //               child: Material(
                        //                 child: CachedNetworkImage(
                        //                   placeholder: Container(
                        //                     child: CircularProgressIndicator(
                        //                       valueColor:
                        //                           AlwaysStoppedAnimation<Color>(
                        //                               themeColor),
                        //                     ),
                        //                     width: 200.0,
                        //                     height: 200.0,
                        //                     padding: EdgeInsets.all(70.0),
                        //                     decoration: BoxDecoration(
                        //                       color: greyColor2,
                        //                       borderRadius: BorderRadius.all(
                        //                         Radius.circular(8.0),
                        //                       ),
                        //                     ),
                        //                   ),
                        //                   errorWidget: Material(
                        //                     child: Image.asset(
                        //                       'images/no_img.png',
                        //                       width: 200.0,
                        //                       height: 200.0,
                        //                       fit: BoxFit.cover,
                        //                     ),
                        //                     borderRadius: BorderRadius.all(
                        //                       Radius.circular(8.0),
                        //                     ),
                        //                     clipBehavior: Clip.hardEdge,
                        //                   ),
                        //                   imageUrl: document['msg'],
                        //                   width: 200.0,
                        //                   height: 200.0,
                        //                   fit: BoxFit.cover,
                        //                 ),
                        //                 borderRadius: BorderRadius.all(
                        //                     Radius.circular(8.0)),
                        //                 clipBehavior: Clip.hardEdge,
                        //               ),
                        //             ),
                        //             decoration: BoxDecoration(
                        //                 color: Colors.indigo[100],
                        //                 borderRadius:
                        //                     BorderRadius.circular(8.0)),
                        //           ),
                        //         ]),
                        //     padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        //     width: 200.0,
                        //     decoration: BoxDecoration(
                        //         color: Colors.indigo[100],
                        //         borderRadius: BorderRadius.circular(8.0)),
                        //   )

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
                                        //)  SizedBox(
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
                                        // child: RaisedButton(
                                        //   shape: new RoundedRectangleBorder(
                                        //       borderRadius:
                                        //           new BorderRadius.circular(
                                        //               15.0)),
                                        //   textColor: Colors.white,
                                        //   color: Colors.black87,
                                        //   onPressed: () {
                                        //     print(
                                        //         '*******VIDEO....${document['msg']}');
                                        //     Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //         builder: (context) => PlayScreen(
                                        //             url: document['msg'],
                                        //             type: 'network'),
                                        //       ),
                                        //     );
                                        //   },
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
                                                builder: (context) =>
                                                    PlayScreen(
                                                        url: document['msg'],
                                                        type: 'network'),
                                              ),
                                            );
                                          },
                                        )
                                        // Icon(
                                        //   Icons.play_circle_filled,
                                        //   size: 60.0,
                                        //   color: Colors.white,
                                        // ),
                                        // ),
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
                                        isLastMessageRight(index) ? 10.0 : 20.0,
                                    // left: 10.0
                                    // right: 10.0
                                    ),
                              )
                            // Container(
                            //     child: Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: <Widget>[
                            //           Text(
                            //             DateFormat('dd MMM kk:mm').format(
                            //                 DateTime.fromMillisecondsSinceEpoch(
                            //                     int.parse(
                            //                         document['timestamp']))),
                            //             style: TextStyle(
                            //                 color: Colors.black,
                            //                 fontSize: 12.0,
                            //                 fontStyle: FontStyle.italic),
                            //           ),
                            //           Padding(
                            //               padding: EdgeInsets.symmetric(
                            //                   vertical: 5.0)),
                            //           SizedBox(
                            //             width: double.infinity,
                            //             height: 144.0,
                            //             child: RaisedButton(
                            //               shape: new RoundedRectangleBorder(
                            //                   borderRadius:
                            //                       new BorderRadius.circular(
                            //                           15.0)),
                            //               textColor: Colors.white,
                            //               color: Colors.black87,
                            //               onPressed: () {
                            //                 print(
                            //                     '*******VIDEO....${document['msg']}');
                            //                 Navigator.push(
                            //                   context,
                            //                   MaterialPageRoute(
                            //                     builder: (context) =>
                            //                         PlayScreen(
                            //                             url: document['msg'],
                            //                             type: 'network'),
                            //                   ),
                            //                 );
                            //               },
                            //               child: Icon(
                            //                 Icons.play_circle_filled,
                            //                 size: 60.0,
                            //                 color: Colors.white,
                            //               ),
                            //             ),
                            //           ),
                            //         ]),
                            //     width: 250.0,
                            //     height: 180.0,
                            //     decoration: BoxDecoration(
                            //       color: Colors.indigo[100],
                            //       borderRadius: BorderRadius.all(
                            //         Radius.circular(15.0),
                            //       ),
                            //     ),
                            //     padding:
                            //         EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                            //     margin: EdgeInsets.only(
                            //         bottom:
                            //             isLastMessageRight(index) ? 10.0 : 10.0,
                            //         right: 10.0),
                            //   )
                            //playSong short song
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
                                        // left: 10.0
                                        ),
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
                                                          return Icon(
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
                                //  Column(
                                //     crossAxisAlignment: CrossAxisAlignment.end,
                                //     children: <Widget>[
                                //       Text(
                                //         DateFormat('dd MMM kk:mm').format(
                                //             DateTime.fromMillisecondsSinceEpoch(
                                //                 int.parse(
                                //                     document['timestamp']))),
                                //         style: TextStyle(
                                //             color: greyColor,
                                //             fontSize: 12.0,
                                //             fontStyle: FontStyle.italic),
                                //       ),
                                //       Container(
                                //         height: 60.0,
                                //         width: 60.0,
                                //         decoration: BoxDecoration(
                                //           borderRadius: BorderRadius.all(
                                //             Radius.circular(8.0),
                                //           ),
                                //         ),
                                //         child: GestureDetector(
                                //           child: playPauseIcon(document['msg']
                                //                   .toString()
                                //                   .replaceAll(
                                //                       'http://54.200.143.85:4200/AudioChat/',
                                //                       ''))
                                //               ? Container(
                                //                   margin: EdgeInsets.all(3),
                                //                   padding: EdgeInsets.all(5),
                                //                   decoration: BoxDecoration(
                                //                     color: Colors.black,
                                //                     borderRadius:
                                //                         BorderRadius.all(
                                //                       Radius.circular(8.0),
                                //                     ),
                                //                   ),
                                //                   child: Column(
                                //                     children: <Widget>[
                                //                       LayoutBuilder(builder:
                                //                           (context,
                                //                               constraint) {
                                //                         return new Icon(
                                //                           Icons.pause,
                                //                           size: 40.0,
                                //                           color: Colors.white,
                                //                         );
                                //                       }),
                                //                     ],
                                //                   ),
                                //                 )
                                //               : Container(
                                //                   margin: EdgeInsets.all(3),
                                //                   padding: EdgeInsets.all(5),
                                //                   decoration: BoxDecoration(
                                //                     color:
                                //                         Colors.deepPurple[50],
                                //                     borderRadius:
                                //                         BorderRadius.all(
                                //                       Radius.circular(8.0),
                                //                     ),
                                //                   ),
                                //                   child: Column(
                                //                     children: <Widget>[
                                //                       Image.asset(
                                //                           'assets/short.png',
                                //                           width: 40.0,
                                //                           height: 40.0)
                                //                     ],
                                //                   ),
                                //                 ),
                                //           onTapUp: (TapUpDetails details) {
                                //             print("onTapUp");
                                //             isPlaying
                                //                 ? stop()
                                //                 : play(
                                //                     document['msg'].toString(),
                                //                     document['msg']
                                //                         .toString()
                                //                         .replaceAll(
                                //                             'http://54.200.143.85:4200/AudioChat/',
                                //                             ''));
                                //           },
                                //         ),
                                //         margin: EdgeInsets.only(
                                //             bottom: isLastMessageRight(index)
                                //                 ? 20.0
                                //                 : 20.0,
                                //             right: 10.0),
                                //       ),
                                //     ],
                                //   )
                                //type = 4 long songs
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
                                        // right: 10.0
                                        // left: 10.0
                                        ),
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
                                                            return new Icon(
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

  bool isLastMessageLeft(int index) {
    print('left last msg idx : ${index}');
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['senderId'] == this.myId) ||
        index == 0)
    // if ((listMessage[index - 1]['senderId'] == this.myId) || index == 0)
     {
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

    // return Future.value(false);
  }

  //open bottom sheet for image video song opening

//
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return new Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: true,
        appBar: new AppBar(
            title: FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        // UserInfoPage(name: this.name, pin: this.receiverPin),
                        ProfilePage(checkUserProfilePin: receiverPin)
                  ),
                );
              },
              textColor: Colors.white,
              splashColor: Colors.indigo[900],
              child: new Text(
                '${this.name}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.call),
                onPressed: () {
                  //audio call md
                  callAudio();
                },
              ),
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
              ),
              IconButton(
                icon: Icon(Icons.video_call),
                onPressed: () {
                  //callVideo md
                  callVideo();
                },
              ),
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
              ),
            ]),
        body: WillPopScope(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildListMessage(),
                  songList(width),

                  songlist2(width),
                  buildInput(),
                ],
              ),
              // Loading
              buildLoading()
            ],
          ),
          onWillPop: onBackPress,
        ));
  }

  songList(width) {
    if (isSearching == true) {
      return Container(
          color: Colors.deepPurple[50],
          height: 40.0,
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                    ),
                    playPauseIcon(listData) //isPlaying
                        ? Icon(Icons.pause_circle_outline)
                        : Image.asset('assets/short.png',
                            width: 25.0, height: 25.0),
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
                  final snackBar = SnackBar(
                    content: Text('Sending  "' +
                        listData.toString().replaceAll('.mp3', ' "')),
                  );
                  _scaffoldKey.currentState.showSnackBar(snackBar);
                  print("onLongPress");
                  onTextMessage(
                      "http://54.200.143.85:4200/AudioChat/" +
                          listData.toString(),
                      3);
                },
              );
            },
          ));
    } else
      return Text('');
  }

  songlist2(width) {
    if (isSearching == true) {
      return Container(
        color: Colors.blue[50],
        height: 40.0,
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                  ),
                  // Icon(Icons.music_note),
                  playPauseIcon(listData) //isPlaying
                      ? Icon(Icons.pause_circle_outline)
                      : Icon(Icons.music_note),
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
                print("onLongPress");
                onTextMessage(
                    "http://54.200.143.85:4200/Audio/" + listData.toString(),
                    4);
              },
            );
          },
        ),
      );
    } else
      return Text('');
  }

  bool playPauseIcon(songName) {
    if (songName == playingSongInList && isPlaying) {
      return true;
    } else
      return false;
  }

  // playSong(songName) {
  //   if (isPlaying == false) {
  //     play("http://54.200.143.85:4200/Audio/" + songName);
  //     setState(() {
  //       isPlaying == true;
  //     });
  //   } else {
  //     stop();
  //   }

  // Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //     builder: (context) => PlayAudio(songName: songName),
  //   ),
  // );
  // try {
  // print('songName:${songName}');
  // var downloadAudio_body = jsonEncode({
  //   "filename": songName,
  // });
  // http
  //     .post(
  //   "http://54.200.143.85:4200/downloadAudio",
  //   headers: {"Content-Type": "application/json"},
  //   body: downloadAudio_body,
  // )
  //     .then((response) {
  //   print("response2:..........${response.body}");
  // });
  // } catch (e) {
  // print('downloadAudio EXCEPTION:${e}');
  // }
  // }

  // audio call
  Future<String> callAudio() async {
    var sendMap = <String, dynamic>{'from': this.mobile, 'to': this.myPhone};
    String result;
    try {
      result = await platform.invokeMethod('audioSinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }

  //video
  Future<String> callVideo() async {
    var sendMap = <String, dynamic>{'from': this.mobile, 'to': this.myPhone};
    String result;
    try {
      result = await platform.invokeMethod('videoSinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }

  //song play stop pause
  Future<int> play(url, songName) async {
    print('in play():${songName}');
    final result = await audioPlayer.play(url, isLocal: false);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        isPlaying = true;
        // filteredSongIndex = index;//
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

  // Widget buildSticker(){}

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
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
                      // focusNode: focusNode,
                      onTap: () {
                        print('ontapp...................---------------');
                        this.isSearching = true;
                        searchOperation('a');
                      },
                    ),
                  ),
                ),
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

  // getSongs(input) {}

  void searchOperation(String searchText) {
    searchresult.clear();
    songSearchresult2.clear();
    if (isSearching != null) {
      for (int i = 0; i < _songList1.length; i++) {
        String data = _songList1[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          searchresult.add(data); //remove .mp4  nt here
        }
      }

      for (int i = 0; i < _songList2.length; i++) {
        String data = _songList2[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          songSearchresult2.add(data);
          print('****songSearchresult2 added :: ${songSearchresult2}');
          //remove .mp4  nt here
        }
      }
      if (searchresult.length == 0 && songSearchresult2.length == 0) {
        isSearching = false;
      }
    }
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
      // response.body[0].f
      // for(var i= 0;i<response.body.length)
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

  Widget buildListMessage() {
    return Flexible(
      child: this.chatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('Private')
                  .document(this.chatId)
                  .collection(this.chatId)
                  .orderBy('timestamp', descending: true)
                  // .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
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
}
