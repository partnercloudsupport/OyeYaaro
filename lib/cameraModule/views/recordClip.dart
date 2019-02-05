import 'dart:async';

import 'package:flutter/material.dart';
import '../controllers/commonFunctions.dart';
import 'package:camera/camera.dart';
import './audioList.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../mdels/config.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;
import 'package:marquee/marquee.dart';



class RecordClip extends StatefulWidget {
  @override
  _RecordClipState createState() => _RecordClipState();
}

class _RecordClipState extends State<RecordClip> {
  List<CameraDescription> cameras;
  bool _isReady = false;
  bool _toggleCamera = false;
  CameraController controller;
  String filePath;
  String commonDir;
  String audioFile;
  String filename;
  bool _isRecording = false;
  int timer;
  String time;
  int _duration;
  String audioDisplay;

  AudioPlayer audioPlayer;
  @override
  void initState() {
    super.initState();
    getPermissions();
    initializeCameras();
    CommonFunctions.createdirectories();
    initializeDir();
    filename = (new DateTime.now().millisecondsSinceEpoch).toString();
    //Future.delayed(const Duration(seconds: 1), () => "1");
    audioPlayer = new AudioPlayer();
    _duration = 30;
    audioDisplay = 'Not Selected';
    time = '0.0';
  }

  @override
  void dispose() {
    super.dispose();
    if (audioPlayer != null) audioPlayer.stop();
    disposeCtrl();
  }

  disposeCtrl() async{
    if (controller != null) await controller.dispose();
  }

  getPermissions() async {
    
  }
  initializeDir() async {
    commonDir = (await getApplicationDocumentsDirectory()).path;
    filePath = '$commonDir${Config.videoRecordTempPath}/$filename.mp4';
    (await getApplicationDocumentsDirectory())
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
      print(entity.path);
    });
  }

  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
      controller = CameraController(cameras[1], ResolutionPreset.high);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isReady = true;
        });
      });
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
    }
  }

  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container();
    } else {
      if (cameras.isEmpty) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No Camera Found',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        );
      }
      if (!controller.value.isInitialized) {
        return Container();
      }

      return Container(
        child: Stack(
          children: <Widget>[
            //CameraPreview(controller),
            new Transform.scale(
                scale: 1.1 / controller.value.aspectRatio,
                child: new Center(
                  child: new AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: new CameraPreview(controller)),
                )),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 120.0,
                padding: EdgeInsets.all(20.0),
                color: Color.fromRGBO(00, 00, 00, 0.7),
                child: Stack(
                  children: <Widget>[
                    /* Align(
                      alignment: Alignment.bottomLeft,
                      child :Container(
                        width:  125.0,
                        child: Marquee(
                        text: "khkjsk",
                      ),
                      )
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child :Container(
                        width:  45.0,
                        child: Text(
                          time,

                          textAlign : TextAlign.center
                        ),
                      ),
                    ), */
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          onTap: () {
                            _navigateAndDisplaySelection(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/ic_music_select.png',
                              //color: Colors.grey[200],
                              width: 42.0,
                              height: 42.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Material(
                        color: Colors.transparent,
                        child: _buildChild(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          onTap: () {
                            if (!_toggleCamera) {
                              onCameraSelected(cameras[1]);
                              setState(() {
                                _toggleCamera = true;
                              });
                            } else {
                              onCameraSelected(cameras[0]);
                              setState(() {
                                _toggleCamera = false;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/ic_switch_camera_3.png',
                              color: Colors.grey[200],
                              width: 42.0,
                              height: 42.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildChild() {
    if (!_isRecording) {
      return InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: () {
          onVideoRecordButtonPressed();
        },
        child: Container(
          padding: EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/video-camera-icon.png',
            width: 72.0,
            height: 72.0,
          ),
        ),
      );
    } else {
      return InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: () {
          onStopButtonPressed();
        },
        child: Container(
          padding: EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/stop-flat.png',
            width: 72.0,
            height: 72.0,
          ),
        ),
      );
    }
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        CommonFunctions.showSnackbar(
            context, 'Camera Error: ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
    }

    if (mounted) setState(() {});
  }

  _navigateAndDisplaySelection(BuildContext context) async {
    /* final result = await Navigator.push(
      context,
      // We'll create the SelectionScreen in the next step!
      MaterialPageRoute(builder: (context) => SelectionPage()),

    ); */

    final downloadedSongPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioList(),
        ));
    print('path = --------------- ${downloadedSongPath}');
    audioFile = downloadedSongPath;
    if (downloadedSongPath != null && downloadedSongPath != '') {
      setState(() {
        audioDisplay = path.basenameWithoutExtension(downloadedSongPath);
      });
    }

    //CommonFunctions.showSnackbar(context, audioFile);
  }

  void onStopButtonPressed() {
    if (audioPlayer != null) {
      audiostop();
    }
    stopVideoRecording().then((_) {
      if (mounted)
        setState(() {
          _isRecording = false;
        });
    });
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
      CommonFunctions a = new CommonFunctions();
      print('check0');
      String res = await a.mergeAudio(filePath, audioFile);
      print('check1');
      await a.moveProcessedFile(res);
      Future.delayed(const Duration(seconds: 2), () => "1");
      print('navigating to back...*****************************************');
      Navigator.pop(context);
    } on CameraException catch (e) {
      return null;
    }
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      CommonFunctions.showSnackbar(context, 'Error: select a camera first.');
      return null;
    }
    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }
    startCountdown();
    audioplay();

    setState(() {
      _isRecording = true;
    });

    try {
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
      return null;
    }
    return filePath;
  }

  Future<void> audioplay() async {
    if (audioFile != null || audioFile != "") {
      //await audioPlayer.setUrl(audioFile);

      audioPlayer.play(audioFile, isLocal: true);
      await audioPlayer.setReleaseMode(ReleaseMode.LOOP);

     // audioPlayer.durationHandler = (d) => setState(() {
            //if (!d.isNegative) _duration = d.inSeconds;
        //  });
    }
  }

  Future<void> audiostop() async {
    print("stop url----- ");
    await audioPlayer.stop();
  }

  startCountdown() {
   return Timer.periodic(
        Duration(seconds: 1),
        (Timer t) => () {
              handleTimeout(t);
            });
  }

  void handleTimeout(Timer t) {
    // callback function
    print('working ${t.tick}');
    setState(() {
      time = t.tick.toString();
    });
    if (t.tick == _duration) {
      t.cancel();
    }
  }
}
