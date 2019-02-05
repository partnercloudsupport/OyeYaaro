import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import 'package:http/http.dart' as http;
import 'chatsList.dart';
import '../New_Group/createGroup.dart';
// import '../HomePage/pages/New_Group/createGroup.dart';

class ChatScreenState extends StatelessWidget {
  // @override
  // void initState() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ChatModel>>(
        future: fetchPrivateChat(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print("Error....${snapshot.error}");
          print('chat list data : ${snapshot}');
          return snapshot.hasData
              ? ListViewPosts(posts: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor, 
        child: 
        Image(
          image: new AssetImage("assets/searchGroup.png"),
          width: 45.0,
          height: 45.0,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        ),

        // Icon(
        //   Icons.search,
        //   color: Colors.white,
        // ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroup(),
            ),
          );
        },
      ),
    );
  }
}
