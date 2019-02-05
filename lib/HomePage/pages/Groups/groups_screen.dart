import 'package:flutter/material.dart';
import '../../../models/group_model.dart';
import 'package:http/http.dart' as http;
import 'groupsList.dart';
import '../New_Group/createGroup.dart';
class GroupScreenState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      body: FutureBuilder<List<GroupModel>>(
        future: fetchGroups(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print("Error....${snapshot.error}");
          return snapshot.hasData
              ? ListViewPosts(posts: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
       floatingActionButton: new FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child:
        Image(
          image: new AssetImage("assets/test.png"),
          width: 35.0,
          height: 35.0,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        ),
        //  Icon(
        //   Icons.search,
        //   color: Colors.white,
        // ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroup(
                  ),
            ),
          );
        },
      ),
    );
  }
}
