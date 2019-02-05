import 'package:flutter/material.dart';
import '../../../models/group_model.dart';
import '../../ChatPage/GroupChatPage/chatPage.dart';

class ListViewPosts extends StatelessWidget {
  final List<GroupModel> posts;

  ListViewPosts({Key key, this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: posts.length,
          // padding: const EdgeInsets.all(15.0),
          padding:  EdgeInsets.fromLTRB(5.0, 0.5, 0.0, 0.2),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                ListTile(
                  leading:
                   Container(
                          width: 50.0,
                          height: 50.0,
                           decoration:  BoxDecoration(
                              color: Colors.white,
                             shape: BoxShape.circle,
                             border:  Border.all(color: Colors.black)
                           ),
                          child: Container(
                            margin: EdgeInsets.all(1.0),
                            decoration:  BoxDecoration(
                              color: Colors.indigo[400],
                              shape: BoxShape.circle,
                              // image:  DecorationImage(
                              //   fit: BoxFit.cover,
                              //   image:  NetworkImage(
                              //       "get group image"),
                              // ),
                            ),
                            child: Icon(Icons.group,color: Colors.white,size: 35.0,),
                          ),
                        ),

                  //  CircleAvatar(
                  //   foregroundColor: Colors.white,//.of(context).primaryColor,
                  //   backgroundColor: Colors.indigo[900],
                  //   child: Text(posts[position].name[0],style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 19.5),),
                  // ),
                  title: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(
                        '${posts[position].name}',
                        style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 18.0),
                      ),
                    ],
                  ),
                  // subtitle: Text(
                  //   '${posts[position].message}',
                  //   style: new TextStyle(
                  //     fontSize: 18.0,
                  //     fontStyle: FontStyle.italic,
                  //   ),
                  // ),
                  onTap: () => _onTapGroup(context, position),
                ),
                Divider(height: 5.0),
              ],
            );
          }),
    );
  }

  Future<void> _onTapGroup(context, position) async {
    print('Group chat id:******************** ${this.posts[position].ids}');
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(
                peerId: this.posts[position].ids,
                chatType: 'group',
                name: this.posts[position].name,
                groupInfo: this.posts,
              ),
        ));
  }
}
