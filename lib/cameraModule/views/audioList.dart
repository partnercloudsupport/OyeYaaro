import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../mdels/config.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AudioList extends StatefulWidget {
  @override
  _AudioListState createState() => _AudioListState();
}

enum PlayerState { stopped, playing, paused }

class _AudioListState extends State<AudioList> {
  Directory directory;

  AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;
  String applicationDir;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  bool isPlaying = false;

  int curr_id = -1;

  @override
  void initState() {
    AudioPlayer.logEnabled = true;
    _initAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
  }

  void _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _audioPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    _audioPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });

    _audioPlayer.completionHandler = () {
      onComplete();
      setState(() {
        _position = _duration;
      });
    };

    _audioPlayer.errorHandler = (msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      _playerState = PlayerState.stopped;
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs'),
      ),
      body: FutureBuilder<List<dynamic>>(
          future: getSongs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error while getting Songs');
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                          leading: isPlaying && curr_id == index
                              ? IconButton(
                                  icon: Icon(Icons.pause_circle_outline),
                                  iconSize: 40.0,
                                  color: Colors.black,
                                  onPressed: () {
                                    _stop(); //url snapshot.data[index].toString()
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.play_circle_outline),
                                  iconSize: 40.0,
                                  color: Colors.black,
                                  onPressed: () {
                                    _play(
                                        'http://54.200.143.85:4200/Audio/' +
                                            snapshot.data[index].toString(),
                                        index);
                                  },
                                ),
                          title: Text(
                            snapshot.data[index]
                                .toString()
                                .replaceAll('.mp3', ''),
                            style: TextStyle(fontSize: 18.0),
                          ),
                          trailing: GestureDetector(
                              child: ClipOval(
                            child: Container(
                                color: Colors.black,
                                child: IconButton(
                                  //icon: Icon(Icons.cloud_download),
                                  icon:
                                      new Image.asset("assets/video_call.png"),
                                  iconSize: 25.0,
                                  color: Colors.black,
                                  onPressed: () {
                                    download(
                                        'http://54.200.143.85:4200/Audio/' +
                                            snapshot.data[index].toString());
                                  },
                                )),
                          )),
                        ),
                        Divider()
                      ],
                    );
                  });
            } else {
              print('no data found');
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Future<List<dynamic>> getSongs() async {
    var response = await http.post(
      "http://54.200.143.85:4200/getAudioList",
      headers: {"Content-Type": "application/json"},
    );
    var res = jsonDecode(response.body);
    return res;
  }

  Future<int> _play(url, idx) async {
    print("play url----- : ${url} && index : ${idx}");
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result = await _audioPlayer.play(url, isLocal: false);
    if (result == 1) {
      setState(() {
        isPlaying = true;
        _playerState = PlayerState.playing;
        curr_id = idx;
      });
    }
    print('idx : ${curr_id}');
    return result;
  }

  // Future<int> _pause() async {
  //   final result = await _audioPlayer.pause();
  //   if (result == 1) {
  //      setState(() {
  //       isPlaying = true;
  //       _playerState = PlayerState.playing;
  //     });
  //   }

  //   return result;
  // }

  Future<int> _stop() async {
    print("stop url----- ");

    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        isPlaying = false;
        _playerState = PlayerState.stopped;
        _position = new Duration();
      });
    }
    return result;
  }

  Future<dynamic> download(String url) async {
    applicationDir = (await getApplicationDocumentsDirectory()).path;
    //String nm = url.replaceAll('.mp3', '');
    //print("song name is : "+nm.replaceAll('http://54.200.143.85:4200/Audio/', ''));
    String songnm = url.replaceAll('http://54.200.143.85:4200/Audio/', '');
    String dir = '$applicationDir${Config.musicDownloadFolderPath}';
    print('getApplicationDocumentsDirectory :  ${dir}');
    //await Directory(dir).create(recursive: true);
    String trimmedsongname = songnm.replaceAll(new RegExp(r"\s+\b|\b\s"), "");
    File file = new File('$dir/$trimmedsongname');
    if (file.existsSync()) {
      Navigator.pop(context, file.path);
    }
    var request = await http.get(
      url,
    );
    var bytes = await request.bodyBytes; //close();
    await file.writeAsBytes(bytes);
    print("final path :  " + file.path);
    Navigator.pop(context, file.path);
  }
}
