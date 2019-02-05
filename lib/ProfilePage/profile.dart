import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:async/async.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart';
import '../HomePage/pages/showImage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../HomePage/ChatPage/PrivateChatPage/privateChatePage.dart';

class ProfilePage extends StatefulWidget {
  final String phone;
  final String checkUserProfilePin;
  ProfilePage({
    Key key,
    this.phone,
    this.checkUserProfilePin,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //#connectivity
  var _connectionStatus = 'Unknown';
  // bool gotUser = false;
  var profileData ;
  bool isLoading = false;
  Connectivity connectivity;
  StreamSubscription<ConnectivityResult> subscription;

  final formKey = GlobalKey<FormState>();
  String Year,
      Stream,
      Name,
      Mobile,
      PinCode,
      UserId,
      ImageNow,
      Email,
      Company,
      Designation,
      Location,
      College;
  String url;
  String userPin;

  @override
  void initState() {
    super.initState();
    print('checkUserProfilePin::---------->${widget.checkUserProfilePin}');
    connectivity = new Connectivity();
    subscription =
        connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectionStatus = result.toString();
      print('****' + _connectionStatus);
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        setState(() {});
      }
    });
    this.getShared(); //
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Enter Valid Email';
    else
      return null;
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    print('GOT IMAGE:: ${image}');
    uploadImageFile(image).then((onValue) {
      print('Image Uploaded....*****');
      imageCache.clear();
      print('cache clear');
      setState(() {});
    });
  }

  Future uploadImageFile(image) async {
    var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));

    var length = await image.length();

    var uri = Uri.parse("http://54.200.143.85:4200/uploadProfileImage");

    var request = new http.MultipartRequest("POST", uri);
    request.headers["pin"] = this.userPin;
    var multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    // send
    var response = await request.send();

    response.stream.transform(utf8.decoder).listen((value) {});
  }

  getShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.userPin = prefs.getString('userPin');
      print('UserPin:::***** ${this.userPin}');
    });
  }

  Future<void> getUser(user) async {
    print('in get user profile..');
    http.Response response = await http.post(
        "http://54.200.143.85:4200/getProfile",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pin": '${user}'}));

    if (response.statusCode == HttpStatus.OK) {
      var result = jsonDecode(response.body);
      print('User profile ---> :  ${result}');
      this.profileData = result['data'];
      print('User profile profileData-------> :  ${this.profileData}');
      // setState(() {
      //   gotUser = true;
      // });
      return result;
    }
  }

  void _register() {
    if (formKey.currentState.validate()) {
      print('form key valid');
      formKey.currentState.save();
      var body = jsonEncode({
        'Year': Year,
        'Stream': Stream,
        'Name': Name,
        'Mobile': Mobile,
        'PinCode': this.userPin,
        'Email': Email,
        'Company': Company,
        'Designation': Designation,
        'Location': Location,
        'College': College
      });
      url = "http://54.200.143.85:4200/updateProfile";
      http
          .post(url, headers: {"Content-Type": "application/json"}, body: body)
          .then((response) {
        // print('res:..${jsonDecode(response.body)}');
        Fluttertoast.showToast(
            msg: "Profile successfully Updated",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIos: 2);
        Navigator.pushReplacementNamed(context, '/homepage');
      });
    }
  }

  Future<void> _onTapChatUser() async {
    setState(() {
          this.isLoading = true;
        });
    print('${widget.checkUserProfilePin}');
    print('${this.profileData[0]['Name']}');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userpin = prefs.getString('userPin');
    String userName = prefs.getString('userName');
    String userNumber = prefs.getString('userPhone');
    var bodyPMsg = jsonEncode({
      "senderPin": userpin,
      "receiverPin": widget.checkUserProfilePin,
      "senderName": userName,
      "receiverName": this.profileData[0]['Name'],
      "senderNumber": userNumber,
      "receiverNumber": this.profileData[0]['Mobile']
    });
    http
        .post("http://54.200.143.85:4200/startChat",
            headers: {"Content-Type": "application/json"}, body: bodyPMsg)
        .then((response) {
      var res = jsonDecode(response.body);
      print(res);
      var chatId = res["data"][0]["chat_id"];
      print(chatId);
      setState(() {
          this.isLoading = false;
        });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
              chatId: chatId,
              chatType: 'private',
              name: this.profileData[0]['Name'],
              receiverPin: widget.checkUserProfilePin,
              mobile: this.profileData[0]['Mobile'])
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
        actions: <Widget>[
          widget.checkUserProfilePin != null 
              ? new IconButton(
                  icon: Icon(Icons.chat),
                  onPressed: () {
                    // print('-------------------->${profileData}');
                    _onTapChatUser();
                  },
                )
              : Text('')
        ],
      ),
      resizeToAvoidBottomPadding: true,
      body: 
      !isLoading ?
      widget.checkUserProfilePin == null
          ?
//logged user profile
          FutureBuilder(
              future: getUser(this.userPin),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var mydata = snapshot.data;
                  print(
                      'data ******:: http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}');
                  return ListView(padding: EdgeInsets.all(15.0), children: [
                    Form(
                      key: formKey,
                      child: Container(
                        padding: EdgeInsets.all(15.0),
                        child: Column(children: <Widget>[
                          Table(columnWidths: {
                            1: FractionColumnWidth(.5)
                          }, children: [
                            TableRow(children: [
                              TableCell(
                                child: new Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ShowImage(
                                                    url:
                                                        "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageThen']}",
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 130.0,
                                          height: 130.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.indigo[900],
                                            // border:
                                          ),
                                          child: Container(
                                            margin: EdgeInsets.all(3.0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey,
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: NetworkImage(
                                                    "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageThen']}"),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                              ),
                              TableCell(
                                child: Stack(children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      print("Container clicked");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ShowImage(
                                                url:
                                                    "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}",
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 130.0,
                                      height: 130.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.indigo[900],
                                        // border:
                                      ),
                                      child: Container(
                                        margin: EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(
                                                "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}"),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  new Positioned(
                                    bottom: 0.0,
                                    right: 15.0,
                                    child: GestureDetector(
                                      onTap: () => getImage(),
                                      child: Container(
                                        width: 50.0,
                                        height: 50.0,
                                        decoration: new BoxDecoration(
                                          color: Colors.indigo[900],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add_a_photo,
                                          size: 26,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ]),
                            TableRow(children: [
                              TableCell(
                                  child: Container(
                                padding: EdgeInsets.only(top: 10),
                                child: new Text(
                                  "Then",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )),
                              TableCell(
                                child: Container(
                                  padding: EdgeInsets.only(top: 10),
                                  child: new Text(
                                    mydata['imageAvailable'] ? "Now" : "Upload",
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Padding(
                              padding:
                                  EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0)),
                          Table(columnWidths: {
                            1: FractionColumnWidth(.7)
                          }, children: [
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Name :'),
                              ),
                              TextFormField(
                                enabled: false,
                                initialValue: mydata['data'][0]['Name'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter Your Name'
                                    : null,
                                onSaved: (input) => Name = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('College :'),
                              ),
                              TextFormField(
                                enabled: false,
                                initialValue: mydata['data'][0]['College'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter College Name'
                                    : null,
                                onSaved: (input) => College = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Year :'),
                              ),
                              TextFormField(
                                enabled: false,
                                initialValue: mydata['data'][0]['Year'],
                                validator: (input) =>
                                    input.isEmpty ? 'Please Enter Year' : null,
                                onSaved: (input) => Year = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Stream :'),
                              ),
                              TextFormField(
                                enabled: false,
                                initialValue: mydata['data'][0]['Stream'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter Your Stream'
                                    : null,
                                onSaved: (input) => Stream = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Email :'),
                              ),
                              TextFormField(
                                initialValue: mydata['data'][0]['Email'],
                                keyboardType: TextInputType.emailAddress,
                                validator: validateEmail
                                    //  (input) => input.isEmpty
                                    //     ? 'Please Enter Your Email'
                                    //     : null
                                    ,
                                onSaved: (input) => Email = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Company :'),
                              ),
                              TextFormField(
                                initialValue: mydata['data'][0]['Company'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter Your Company'
                                    : null,
                                onSaved: (input) => Company = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Designation :'),
                              ),
                              TextFormField(
                                initialValue: mydata['data'][0]['Designation'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter Your Designation'
                                    : null,
                                onSaved: (input) => Designation = input,
                              ),
                            ]),
                            TableRow(children: [
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                                child: Text('Location :'),
                              ),
                              TextFormField(
                                initialValue: mydata['data'][0]['Location'],
                                validator: (input) => input.isEmpty
                                    ? 'Please Enter Your Location'
                                    : null,
                                onSaved: (input) => Location = input,
                              ),
                            ]),
                            //  TableRow(children: [
                            //   Container(
                            //     padding:
                            //         EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                            //     child: Text('Logout :'),
                            //   ),
                            //   FlatButton(
                            //     child: Text(
                            //       'Save',
                            //       style: TextStyle(
                            //           color: Colors.white, fontSize: 15),
                            //     ),
                            //     splashColor: Colors.green,
                            //     color: Colors.indigo[400],
                            //     shape: RoundedRectangleBorder(
                            //         borderRadius:
                            //             BorderRadius.circular(10.0)),
                            //     onPressed: _register,
                            //   ),
                            // ]),
                          ]),
                          Table(columnWidths: {
                            1: FractionColumnWidth(.5)
                          }, children: [
                            TableRow(children: [
                              Container(
                                margin: EdgeInsets.all(3.0),
                                child: FlatButton(
                                  child: Text(
                                    'Save',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                  splashColor: Colors.green,
                                  color: Colors.indigo[900],
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  onPressed: () {
                                    _register();
                                  },
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(3.0),
                                child: FlatButton(
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                  splashColor: Colors.green,
                                  color: Colors.indigo[900],
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  onPressed: () {
                                    logout();
                                  },
                                ),
                              )
                            ])
                          ])

                          // Center(
                          //     child: new Column(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: <Widget>[
                          //     Padding(padding: EdgeInsets.all(15.0)),
                          //     FlatButton(
                          //       child: Text(
                          //         'Save',
                          //         style: TextStyle(
                          //             color: Colors.white, fontSize: 15),
                          //       ),
                          //       splashColor: Colors.green,
                          //       color: Colors.indigo[400],
                          //       shape: RoundedRectangleBorder(
                          //           borderRadius:
                          //               BorderRadius.circular(10.0)),
                          //       onPressed: _register,
                          //     )
                          //   ],
                          // ))
                        ]),
                      ),
                    )
                  ]);
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })
//other user profile
          : FutureBuilder(
              future: getUser(widget.checkUserProfilePin),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var mydata = snapshot.data;
                  print(
                      'data ******:: http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}');
                  return ListView(padding: EdgeInsets.all(15.0), children: [
                    Container(
                      padding: EdgeInsets.all(15.0),
                      child: Column(children: <Widget>[
                        Table(columnWidths: {
                          1: FractionColumnWidth(.5)
                        }, children: [
                          TableRow(children: [
                            TableCell(
                              child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        // print(document['msg']);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowImage(
                                                  url:
                                                      "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageThen']}",
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                          width: 130.0,
                                          height: 130.0,
                                          decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey,
                                              image: new DecorationImage(
                                                  fit: BoxFit.fill,
                                                  image: NetworkImage(
                                                      "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageThen']}")))),
                                    ),
                                  ]),
                            ),
                            TableCell(
                              child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        // print(document['msg']);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowImage(
                                                  url:
                                                      "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}",
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 130.0,
                                        height: 130.0,
                                        decoration: new BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                            image: new DecorationImage(
                                                fit: BoxFit.fill,
                                                image: NetworkImage(
                                                    "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageNow']}"))),
                                      ),
//                                        Container(
//                                            width: 130.0,
//                                            height: 130.0,
//                                            decoration: new BoxDecoration(
//                                                shape: BoxShape.circle,
//                                                image: new DecorationImage(
//                                                    fit: BoxFit.fill,
//                                                    image: NetworkImage(
//                                                        "http://54.200.143.85:4200/profiles${mydata['data'][0]['ImageThen']}")))),
                                    ),
                                  ]),
                            ),
                          ]),
                          TableRow(children: [
                            TableCell(
                                child: Container(
                              padding: EdgeInsets.only(top: 10),
                              child: new Text(
                                "Then",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )),
                            TableCell(
                              child: Container(
                                padding: EdgeInsets.only(top: 10),
                                child: new Text(
                                  mydata['imageAvailable']
                                      ? "Now"
                                      : "Not Available",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ]),
                        ]),
                        Padding(
                            padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0)),
                        Table(columnWidths: {
                          1: FractionColumnWidth(.7)
                        }, children: [
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('College :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['College'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter College Name'
                                  : null,
                              onSaved: (input) => College = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Year :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Year'],
                              validator: (input) =>
                                  input.isEmpty ? 'Please Enter Year' : null,
                              onSaved: (input) => Year = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Stream :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Stream'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter Your Stream'
                                  : null,
                              onSaved: (input) => Stream = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Name :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Name'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter Your Name'
                                  : null,
                              onSaved: (input) => Name = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Email :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Email'],
                              keyboardType: TextInputType.emailAddress,
                              validator: validateEmail
                                  //  (input) => input.isEmpty
                                  //     ? 'Please Enter Your Email'
                                  //     : null
                                  ,
                              onSaved: (input) => Email = input,
                            ),
                          ]),
                          // TableRow(children: [
                          //   Container(
                          //     padding:
                          //         EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                          //     child: Text('Mobile :'),
                          //   ),
                          //   Row(
                          //     children: [
                          //       Container(
                          //         child: TextFormField(
                          //           enabled: false,
                          //           initialValue: mydata['data'][0]['Mobile'],
                          //         ),
                          //         width: 130.0,
                          //         height: 44.0,
                          //       ),
                          //       Container(
                          //         child: IconButton(
                          //           icon: Icon(
                          //             Icons.call,
                          //             color: Colors.green.shade900,
                          //           ),
                          //           onPressed: () {
                          //             //mydata['data'][0]['Mobile']
                          //           },
                          //         ),
                          //         decoration: BoxDecoration(
                          //           border: Border(
                          //             bottom: BorderSide(
                          //               color: Colors.black38,
                          //               width: 0.35,
                          //             ),
                          //           ),
                          //         ),
                          //         width: 40.0,
                          //         height: 44.0,
                          //       ),
                          //       Container(
                          //         child: IconButton(
                          //           icon: Icon(
                          //             Icons.video_call,
                          //             color: Colors.green.shade900,
                          //           ),
                          //           color: Colors.blue,
                          //           onPressed: () {
                          //             //mydata['data'][0]['Mobile']
                          //           },
                          //         ),
                          //         decoration: BoxDecoration(
                          //           border: Border(
                          //             bottom: BorderSide(
                          //               color: Colors.black38,
                          //               width: 0.35,
                          //             ),
                          //           ),
                          //         ),
                          //         width: 40.0,
                          //         height: 40.5,
                          //       ),
                          //     ],
                          //   )
                          // ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Company :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Company'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter Your Company'
                                  : null,
                              onSaved: (input) => Company = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Designation :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Designation'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter Your Designation'
                                  : null,
                              onSaved: (input) => Designation = input,
                            ),
                          ]),
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
                              child: Text('Location :'),
                            ),
                            TextFormField(
                              enabled: false,
                              initialValue: mydata['data'][0]['Location'],
                              validator: (input) => input.isEmpty
                                  ? 'Please Enter Your Location'
                                  : null,
                              onSaved: (input) => Location = input,
                            ),
                          ]),
                        ]),
                        // Center(
                        //     child: new Column(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: <Widget>[
                        //     Padding(padding: EdgeInsets.all(15.0)),
                        //     FlatButton(
                        //       child: Text(
                        //         'Save',
                        //         style:
                        //             TextStyle(color: Colors.white, fontSize: 15),
                        //       ),
                        //       splashColor: Colors.green,
                        //       color: Colors.indigo[900],
                        //       shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(10.0)),
                        //       onPressed: _register,
                        //     )
                        //   ],
                        // ))
                      ]),
                    ),
                    // )
                  ]);
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })
              :
               Center(
                    child: CircularProgressIndicator(),
                  )
              ,
    );
  }

  logout() {
    FirebaseAuth.instance.signOut().then((action) {
      clearSharedPref();
      Navigator.pushReplacementNamed(context, '/loginpage');
    }).catchError((e) {
      print("*err:*" + e);
    });
  }

  clearSharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
