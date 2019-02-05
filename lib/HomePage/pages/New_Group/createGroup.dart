import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connect_yaar/HomePage/homepage.dart';
import '../../groupInfoTabsPage.dart';
import '../../ChatPage/PrivateChatPage/privateChatePage.dart';
import 'package:share/share.dart';
import '../../../ProfilePage/profile.dart';
// import 'package:material_search/material_search.dart';
import '../../../PlayAudio/audioList.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateGroup extends StatefulWidget {
  // final String val;
  // final List<dynamic> year;
  // final List<dynamic> branch;
  // CreateGroup(
  //     {Key key,
  //     @required this.val,
  //     @required this.year,
  //     @required this.branch});

  @override
  CreateGroupState createState() => new CreateGroupState();
}

class CreateGroupState extends State<CreateGroup> {
  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  var downloadedSongPath;

  //service res
  String val = '';
  List<dynamic> year = [];
  List<dynamic> branch = [];

// search related vars
  final globalKey = new GlobalKey<ScaffoldState>();
  TextEditingController _controller = new TextEditingController();
  TextEditingController _controllerCollege = new TextEditingController();

  List<dynamic> collegelist; // = List<dynamic>();
  // bool _isSearching;
  bool typing = false;
  // String _searchText = "";
  List<dynamic> searchresult = List<dynamic>();
  List<dynamic> searchresultforClg = List<dynamic>();

  // List<StudentData> collegeStudentList = List<StudentData>();

  List<dynamic> collegeStudentList = List<dynamic>();
  bool showStudentSearch = false;
  bool showSearchGroupDropdown = false;

  // String collegeName = '';

  List<DropdownMenuItem<String>> _years = [];
  List<DropdownMenuItem<String>> _branches = [];
  double opacity = 1.0;
  bool showLoading = false;
  SharedPreferences prefs;
  String _year = null;
  String _branch = null;
  bool openGrpButton;
  // String _message = null;
  // String admin_id = null;
  // String userPin;

  String _check, token, groupName;
  int _count = 0;

  @override
  void initState() {
    // super.initState();
    this.val = ""; //
    this.year = []; //
    this.branch = []; //

    values();

    //call student list
    // showLoading = true;
    //  collegeStudentList =
    // getStudentList();
  }

  /* Future<List<StudentData>> */ getStudentList() async {
    // print('val:${this.val}');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPin = prefs.getString('userPin');

    http.Response response = await http.post(
        "http://54.200.143.85:4200/studentList",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"college": '${this.val}', "userPin": userPin}));
    var res = jsonDecode(response.body);
    print("Student list res:********* ${res['data'].runtimeType}");
    this.collegeStudentList = res['data'];
    // print("collegeStudentList:********* ${this.collegeStudentList}");

    setState(() {
      showLoading = false;
    });
  }

  void values() {
    //now  colleges added manually when multiple colleged added in db use new service
    collegelist = List();
    collegelist.addAll([
      "PEC",
    ]); //"MIT", "Pune", "PICTE", "Pune", "COEP", "Pune", "PEC,punjab"

    for (int i = 0; i < collegelist.length; i++) {
      String data = collegelist[i];
      // if (data.toLowerCase().contains(searchText.toLowerCase())) {
      searchresultforClg.add(data);
      // }
    }
  }

  Future<void> _checkGroup() async {
    if (this._branch == null) {
      Fluttertoast.showToast(
        msg: "Please Select branch",
      );
    } else if (this._year == null) {
      Fluttertoast.showToast(
        msg: "Please Select Year",
      );
    } else if (formKey.currentState.validate()) {
      formKey.currentState.save();
      setState(() {
        showLoading = true;
        _count = 0;
      });
      // print('in check..');

      _check = this.val + " " + _branch + " " + _year;

      var body3 = jsonEncode({
        "clg": "${this.val}",
        "branch": "${_branch}",
        "year": "${_year}",
      });

      http
          .post("http://54.200.143.85:4200/checkGroup",
              headers: {"Content-Type": "application/json"}, body: body3)
          .then((response) {
        var res = jsonDecode(response.body);
        setState(() {
          showLoading = false;
        });

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrpInfoTabsHome(
                  peerId: res['data']['dialog_id'],
                  chatType: 'group',
                  groupName: res['data']['name']),
            ));
      });
    }
  }

  void loadData() {
    _years = [];
    _branches = [];

    for (var i = 0; i < this.year.length; i++) {
      _years.add(DropdownMenuItem(
          child: Text(this.year[i].toString()),
          value: this.year[i].toString()));
    }

    for (var i = 0; i < this.branch.length; i++) {
      _branches.add(DropdownMenuItem(
          child: Text(this.branch[i].toString()),
          value: this.branch[i].toString()));
    }
  }

  Widget appBarTitle(String val) {
    return Text(
      val,
      style: new TextStyle(color: Colors.white),
    );
  }

  // goToSongList() async {
  //   downloadedSongPath = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => AudioList(),
  //       ));
  //   print('path = --------------- ${downloadedSongPath}');
  // }

  @override
  Widget build(BuildContext context) {
    loadData();
    return Scaffold(
        resizeToAvoidBottomPadding: true,
        appBar: AppBar(
            centerTitle: true,
            title: this.val == ''
                ? appBarTitle('Search College')
                : appBarTitle(this.val),
            actions: <Widget>[
              // IconButton(
              //   icon: const Icon(Icons.queue_music),
              //   onPressed: () {
              //     goToSongList();
              //   },
              // )
            ]),
        body: !showLoading
            ? Column(
                children: <Widget>[
                  !showStudentSearch
                      ? Container(
                          margin: EdgeInsets.all(
                              22.0), //fromLTRB(22.0, 22.0, 22.0, 0.0),
                          padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                          child:
                              // Row(children: <Widget>[
                              TextField(
                                  autofocus: true,
                                  controller: _controllerCollege,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter College Name here..'),
                                  onChanged: (input) {
                                    searchOperationForCollege(
                                        input); //new search op
                                  }),
                          decoration: BoxDecoration(
                              color: Colors.grey[350],
                              borderRadius: BorderRadius.circular(50.0)),
                        )
                      :
                      // Row(
                      //     children: <Widget>[
                      Container(
                          margin: EdgeInsets.all(
                              22.0), //fromLTRB(22.0, 22.0, 22.0, 0.0),
                          padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: TextField(
                                    autofocus: false,
                                    controller: _controller,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Search by student name..'),
                                    onChanged: (input) {
                                      searchOperation(input);
                                    }),
                              ),
                              this.typing && showStudentSearch
                                  ? IconButton(
                                      icon: Icon(Icons.close),
                                      tooltip: 'Increase volume by 10%',
                                      onPressed: () {
                                        print('close studeny list');
                                        setState(() {
                                          this.typing = false;
                                          this.showSearchGroupDropdown = true;
                                          this._controller.text = "";
                                        });
                                      },
                                    )
                                  : Text('')
                            ],
                          ),
                          decoration: BoxDecoration(
                              color: Colors.grey[350],
                              borderRadius: BorderRadius.circular(50.0)),
                        ),
                  //   ],
                  // ),

                  this.typing && showStudentSearch
                      ? Flexible(
                          child: ListView.builder(
                            itemCount: searchresult.length,
                            itemBuilder: (BuildContext context, int index) {
                              bool isActive = searchresult[index]['joined'];
                              return Column(children: <Widget>[
                                ListTile(
                                    leading: GestureDetector(
                                        child: CircleAvatar(
                                          foregroundColor:
                                              Theme.of(context).primaryColor,
                                          backgroundColor: Colors.grey,
                                          backgroundImage: NetworkImage(
                                              "http://54.200.143.85:4200/profiles${searchresult[index]['ImageThen']}"),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfilePage(
                                                          checkUserProfilePin:
                                                              searchresult[
                                                                      index][
                                                                  'PinCode'])));
                                        }),
                                    title: searchresult[index]['Name'] == null
                                        ? Text(
                                            'Name not found',
                                          )
                                        : Text(searchresult[index]['Name']),
                                    subtitle: searchresult[index]['Groups'][0]
                                                ['group_name'] ==
                                            null
                                        ? Text(
                                            'College not found',
                                          )
                                        : Text(searchresult[index]['Groups'][0]
                                            ['group_name']),
                                    trailing: isActive
                                        ? FlatButton(
                                            child: Text(
                                              'Chat',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            splashColor: Colors.green,
                                            color: Colors.indigo[900],
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        30.0)),
                                            onPressed: () {
                                              chat(
                                                  context,
                                                  searchresult[index]
                                                      ['PinCode'],
                                                  searchresult[index]['Name'],
                                                  searchresult[index]
                                                      ['Mobile']);
                                            })
                                        : FlatButton(
                                            child: Text(
                                              'Invite',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            splashColor: Colors.green,
                                            color: Colors.indigo[900],
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        30.0)),
                                            onPressed: () {
                                              invite(searchresult[index]
                                                  ['PinCode']);
                                            })),
                                Divider(height: 5.0),
                              ]);
                            },
                          ),
                        )
                      : this.typing || !showStudentSearch
                          ? Flexible(
                              child: ListView.builder(
                                // shrinkWrap: true,
                                itemCount: searchresultforClg.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String listData = searchresultforClg[index];
                                  return GestureDetector(
                                      child: ListTile(
                                          title: Text(listData.toString())),
                                      onTap: () {
                                        tapOnCollege(listData.toString());
                                      });
                                },
                              ),
                            )
                          : Container(),
                  // Text('clg else'),

                  //dropdowns
                  showSearchGroupDropdown
                      ? Flexible(
                          fit: FlexFit.tight,
                          child: ListView(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.fromLTRB(
                                    20.0, 0.0, 20.0, 20.0), //all(20.0),
                                child: Form(
                                  key: formKey,
                                  autovalidate: true,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      FormField(
                                        builder: (FormFieldState state) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Branch',
                                            ),
                                            child:
                                                new DropdownButtonHideUnderline(
                                              child: new DropdownButton(
                                                value: _branch,
                                                items: _branches,
                                                hint: new Text('Select branch'),
                                                onChanged: (value) {
                                                  _branch = value;
                                                  setState(() {
                                                    // create = false;
                                                    // join = false;
                                                    _count = 0;
                                                    _branch = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      new FormField(
                                        builder: (FormFieldState state) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Year',
                                            ),
                                            child:
                                                new DropdownButtonHideUnderline(
                                              child: new DropdownButton(
                                                value: _year,
                                                items: _years,
                                                hint: new Text('Select year'),
                                                onChanged: (value) {
                                                  _year = value;
                                                  setState(() {
                                                    _count = 0;
                                                    _year = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      new Padding(
                                        padding:
                                            const EdgeInsets.only(top: 60.0),
                                      ),
                                      SizedBox(
                                        width: 210.0, // double.infinity / 2,
                                        height: 50.0,
                                        child: FlatButton(
                                          child: Text(
                                            'Search Group', //'Find Group',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),

                                          splashColor: Colors.green,
                                          color: Colors.indigo[900],
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          onPressed:
                                              _checkGroup, //openGrpButton? _checkGroup :null,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  // Text("drop else")
                ],
              )
            : Center(child: CircularProgressIndicator()));
  }

  invite(userPin) {
    Share.share(
        'You are invited to join your classmates @OyeYaaro. Download  this App by www.webworldindia.com/connectyaar/app use PIN #${userPin} to login.See you in the room chat! ');
  }

  Future<void> chat(context, id, name, Mobile) async {
    // print(id);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userpin = prefs.getString('userPin');
    String userName = prefs.getString('userName');
    String userNumber = prefs.getString('userPhone');
    var bodyPMsg = jsonEncode({
      "senderPin": userpin,
      "receiverPin": id,
      "senderName": userName,
      "receiverName": name,
      "senderNumber": userNumber,
      "receiverNumber": Mobile
    });
    http
        .post("http://54.200.143.85:4200/startChat",
            headers: {"Content-Type": "application/json"}, body: bodyPMsg)
        .then((response) {
      var res = jsonDecode(response.body);
      print(res);
      var chatId = res["data"][0]["chat_id"];
      print(chatId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
              chatId: chatId,
              chatType: 'private',
              name: name,
              receiverPin: id,
              mobile: Mobile),
        ),
      );
    });
  }

  void searchOperationForCollege(String searchText) {
    print('typing..for college');
    setState(() {
      this.typing = true;
    });
    searchresultforClg.clear();
    for (int i = 0; i < collegelist.length; i++) {
      String data = collegelist[i];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        searchresultforClg.add(data);
      }
    }
    print('searchR: ${searchresult}');
  }

  void searchOperation(String searchText) {
    print('typing..');
    setState(() {
      this.typing = true;
      showSearchGroupDropdown = false;
    });

    searchresult.clear();
    //now iterate for student list
    for (int i = 0; i < this.collegeStudentList.length; i++) {
      print('NAME:: ${this.collegeStudentList[i]['Name']}');
      // break;
      String data = this.collegeStudentList[i]['Name'];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        print('....${this.collegeStudentList[i]}');
        searchresult
            .add(this.collegeStudentList[i]); //this.collegeStudentList[i]
      }
    }

    print('searchR: ${searchresult}');
  }

  tapOnCollege(value) async {
    // print(value);

    setState(() {
      this.val = value;
      showLoading = true;
      this.typing = false;
      this._controllerCollege.text = value;
      this.showStudentSearch = true;
      showSearchGroupDropdown = true;

      // searchresult.clear();
    });
    // print("in navigate: ${value}");
    var body = jsonEncode({
      "College": "${value}",
    });
    http
        .post("http://54.200.143.85:4200/yearAndBatch",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      setState(() {
        // showLoading = false;
        // this.openGrpButton = true;
      });
      var res = jsonDecode(response.body);
      // print('res: ${res}');
      // print('PEC Colleges : ${res['data']['Years']}');
      // print('PEC Streams : ${res['data']['Streams']}');
      setState(() {
        this.year = res['data']['Years'];
        this.branch = res['data']['Streams'];
      });

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => CreateGroup(
      //         // val: value,
      //         // year: res['data']['Years'],
      //         // branch: res['data']['Streams']
      //         ),
      //   ),
      // );

      //studentListView service
      getStudentList();
    });
  }
}

//
// class StudentData {
//   final String name;
//   final String college;
//   final bool isActive;
//   StudentData({this.name, this.college, this.isActive});

//   factory StudentData.fromJson(Map<String, dynamic> json) {
//     return StudentData(
//         name: json['Name'] as String,
//         college: json['Groups']['group_name'] as String,
//         isActive: json['Groups']['invite'] as bool);
//   }
// }

// A function that will convert a response body into a List<Photo>
// List<StudentData> parseUsers(String responseBody) {
//   final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
//   return parsed.map<StudentData>((json) => StudentData.fromJson(json)).toList();
// }
