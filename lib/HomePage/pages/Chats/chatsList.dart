import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../HomePage/ChatPage/PrivateChatPage/privateChatePage.dart';
import '../../../ProfilePage/profile.dart';

class ListViewPosts extends StatelessWidget {
  final List<ChatModel> posts;

  ListViewPosts({Key key, this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
          itemCount: posts.length,
          padding: EdgeInsets.fromLTRB(0.0, 0.1, 0.0, 0.1),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                ListTile(
                    leading: GestureDetector(
                        child: Container(
                          width: 65.0,
                          height: 65.0,
                           decoration:  BoxDecoration(
                              color: Colors.white,
                             shape: BoxShape.circle,
                             border:  Border.all(color: Colors.black)
                           ),
                          child: Container(
                            margin: EdgeInsets.all(1.0),
                            decoration:  BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                              image:  DecorationImage(
                                fit: BoxFit.cover,
                                image:  NetworkImage(
                                    "http://54.200.143.85:4200/profiles/then/${posts[position].receiverPin}.jpg"),
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                      checkUserProfilePin:
                                          posts[position].receiverPin)));
                        }),
                    subtitle: Text(
                      '${this.posts[position].senderGroup[0]}',
                      style: new TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    title: GestureDetector(
                      child: new Text(
                        '${posts[position].receiverName[0].toUpperCase()}${posts[position].receiverName.substring(1)}',
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    onTap: () => _onTapChatUser(context, position)),
                Divider(height: 5.0),
              ],
            );
          }),
    );
  }

  Future<void> _onTapChatUser(context, position) async {
    print("****" + this.posts[position].chat_id);
    print(this.posts[position].receiverName);
    print(this.posts[position].receiverPin);
    print('group array : ${this.posts[position].senderGroup}');

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
              chatId: this.posts[position].chat_id,
              chatType: 'private',
              name: this.posts[position].receiverName,
              receiverPin: this.posts[position].receiverPin,
              mobile: this.posts[position].receiverPhone),
        ));
  }
}
