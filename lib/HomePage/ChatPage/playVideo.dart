import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class PlayScreen extends StatefulWidget {
  String url;
  String type;
  PlayScreen({Key key, this.url, this.type}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  // TargetPlatform _platform;
  VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {     
    print('URL****URL${widget.url}');
    super.initState();

    if (widget.type == 'file') {
      print('file');

      var file = new File(widget.url);
      _controller = VideoPlayerController.file(file)
        ..addListener(() {
          print('in addListner...');
          final bool isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        })
        ..initialize().then((_) {
          setState(() {});
        });

    } else {
      print('network');
      _controller = VideoPlayerController.network(
        widget.url + '?raw=true',
      )
        ..addListener(() {
          final bool isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        })
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: new AppBar(
        title: new Text(
          'Video',
          style: TextStyle(
              fontSize: 22.0),
        ),
       ),
      body:
           Center(
            child: _controller.value.initialized
                ? AspectRatio(
                    aspectRatio:_controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                :  Center(child: CircularProgressIndicator()),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: _controller.value.isPlaying
                ? _controller.pause
                : _controller.play,
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),

      //     new Chewie(
      //   _controller,
      //   aspectRatio: 3 / 2,
      //   autoPlay: true,
      //   looping: true,
      //   placeholder: new Container(
      //     color: Colors.grey,
      //   ),
      //   autoInitialize: true,
      // ),
    );
  }
}
