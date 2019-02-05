import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../showImage.dart';
import './filter.dart';

class ImagesData {
  final String imageUrl;
  final String senderName;
  final String timestamp;
  ImagesData({
    this.imageUrl,
    this.senderName,
    this.timestamp,
  });

  factory ImagesData.fromJson(Map<String, dynamic> json) {
    return ImagesData(
      imageUrl: json['url'] as String,
      senderName: json['senderName'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

List<ImagesData> parseUsers(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<ImagesData>((json) => ImagesData.fromJson(json)).toList();
}

class ImagesPage extends StatefulWidget {
  @override
  _ImagesPageState createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  List<ImagesData> data;
  bool showFilter = false;
  bool isLoading = false;
  // int _currentIndex = 0;
  var res;
  Set<String> resultFromFilter = new Set<String>();

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
  }

  @override
  void dispose() {
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        body: !isLoading
            ? 
            FutureBuilder<List<ImagesData>>(
                future: fetchImages(http.Client()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) print(snapshot.error);
                  return snapshot.hasData
                      ? bodyMd(snapshot.data, context)
                      : Center(child: CircularProgressIndicator());
                },
              )
            : Center(child: CircularProgressIndicator()),
        // bottomNavigationBar: BottomNavigationBar(
        //   onTap: onTabTapped,
        //   currentIndex: _currentIndex,
        //   items: [
        //     BottomNavigationBarItem(
        //       icon: new Icon(Icons.filter),
        //       title: new Text('Filter'),
        //     ),
        //     BottomNavigationBarItem(
        //       icon: new Icon(Icons.sort),
        //       title: new Text('Sort'),
        //     ),
        //   ],
        // )

        floatingActionButton:  FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child:
        //  Icon(
        //   Icons.camera_alt,
        //   color: Colors.white,
        //   size: 25.0,
        // ),
        Text('Filters'),
        onPressed:  () {
          onTabTapped();
        },
      ),
        );
  }

  void onTabTapped() async {
    // print('${index}');
    // if (index == 0) {
      print('RES :: ${res}');
      resultFromFilter = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FilterPage(data: res, resultToFilter: resultFromFilter)));
      print('pop Result : ${resultFromFilter}');
      setState(() {
        // this.isLoading = true;
      });
      if (resultFromFilter == null) {
        print('pop res is null');
        resultFromFilter = new Set<String>();
      }
    // }

    // setState(() {
    //   _currentIndex = index;
    // });
  }

  Future<List<ImagesData>> fetchImages(http.Client client) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userPin = (prefs.getString('userPin'));
    final result = await client.post("http://54.200.143.85:4200/getImages",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"PinCode": '${userPin}'}));

    res = jsonDecode(result.body);
    print('in fetch photo res:');

    if (resultFromFilter.length == 0) {
      print('resultFromFilter.type==> : ${resultFromFilter.runtimeType}');
      return compute(parseUsers, jsonEncode(res));
    } else {
      //filter res
      print('resultFromFilter.type== : ${resultFromFilter.runtimeType}');
      // resultFromFilter.
      var arr = await filterResult(res, resultFromFilter);
      return compute(parseUsers, jsonEncode(arr));
    }
  }

  filterResult(res, resultFromFilter) {
    var newList = [];
    for (var i = 0; i < res.length; i++) {
      if (resultFromFilter.contains(res[i]['senderName'])) {
        newList.add(res[i]);
      }
    }
    
    return newList;
  }

  Widget bodyMd(snapshot, context) {
    showFilter = true;
    data = snapshot;
    print('data.....${data}');
    return 
    GridView.count(
      padding: EdgeInsets.all(10.0),
      crossAxisSpacing: 8.0,
      crossAxisCount: 2,
      children: imagesGrid(data, context),
    );
  }

  List<Widget> imagesGrid(imagesData, context) {
    print('-------------------------------------------${imagesData.length}');
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < imagesData.length; i++) {
      print('dataList : ${imagesData[i].imageUrl}');
      btnlist.add(
        GestureDetector(
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowImage(
                        url: imagesData[i].imageUrl,
                      ),
                ),
              ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imagesData[i].imageUrl),
              ),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.only(bottom: 8.0),
            child: Stack(
              children: <Widget>[
                new Positioned(
                  //   child: StreamBuilder(
                  //     stream: Firestore.instance
                  //         .collection('groups')
                  //         .document(imagesData[i].groupName)
                  //         .collection(imagesData[i].groupName).where('timestamp', isEqualTo: imagesData[i].timestamp)

                  //         // .orderBy('timestamp', descending: true)
                  //         // .limit(20)
                  //         // .snapshots(),
                  //     // .document(imagesData[i].timestamp)
                  //     .snapshots(),
                  //     builder: (context, snapshot) {
                  //       if (!snapshot.hasData) {
                  //         return Center(child: CircularProgressIndicator());
                  //       } else if (snapshot.hasError) {
                  //         print("ERROR::" + snapshot.error.toString());
                  //       } else {
                  //         print('-->${snapshot.data.documents.toString()}');
                  //         // var l = snapshot.data.documents;
                  //         // return Text(snapshot.data.documents[1].document['senderName']);
                  //         // return ListView.builder(
                  //         //   padding: EdgeInsets.all(10.0),
                  //         //   itemBuilder: (context, index) =>
                  //         //       buildItem(index, snapshot.data.documents[index]),
                  //         //   itemCount: snapshot.data.documents.length,
                  //         //   reverse: true,
                  //         // );

                  //         return new ListView(
                  // children: snapshot.data.documents.map((DocumentSnapshot document) {
                  //   return new ListTile(
                  //     title: new Text(document['senderName']),
                  //     // subtitle: new Text(document['author']),
                  //   );
                  // }).toList());

                  //         //  return new ListView.builder(
                  //         //  shrinkWrap: true,
                  //         //  itemCount: snapshot.data.documents.length,
                  //         //   itemBuilder: (context, index) {
                  //         //     DocumentSnapshot ds = snapshot.data.documents[index];
                  //         //     return new Row(
                  //         //       textDirection: TextDirection.ltr,
                  //         //        children: <Widget>[
                  //         //       Expanded (child:Text(ds["msg"]) ),
                  //         //     ],
                  //         //     );
                  //         //   },
                  //         //  );
                  //       }
                  //     },
                  //   ),
                  // child: ListTile(
                  //   leading:
                  //       new Text('''Navjeet Singh''', //expand containers width
                  //           style: new TextStyle(
                  //             color: Colors.white,
                  //           )),
                  // ),
                  // child: new Container(
                  child: new Text(
                      imagesData[i]
                          .senderName
                          .toString(), //expand containers width
                      style: new TextStyle(
                          color: Colors.indigo[50], fontSize: 18.0)),
                  left: 3.0,
                  bottom: 2.0,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return btnlist;
  }
}
