import 'package:flutter/material.dart';
import 'imageAlbum.dart';
import 'videoAlbum.dart';

class NetworkScreen extends StatefulWidget {
  @override
  _NetworkScreenState createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.indigo[900],
          tabs: <Widget>[
            new Tab(
              text: "IMAGES",
              ),
            new Tab(
              text: "VIDEOS",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          ImagesPage(),
          VideosPage(),
        ],
      ),
       
    );
  }
}
