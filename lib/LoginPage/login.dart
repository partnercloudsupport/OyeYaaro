import 'dart:async';
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:connect_yaar/ProfilePage/profile.dart';
// import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_yaar/UserPinPage/userPin.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _smsCodeController = TextEditingController(); //

  String phoneNo;
  String smsCode;
  String verificationId;
  bool userVerified = false;
  bool loading = false;
  bool smsCode_Sent = false;
  bool verifybtn;

  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    // this.getSharedInstances();
    super.initState();
    verifybtn = false;
  }

  // getSharedInstances() async { // no use
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     print('init login setstate()....');
  //     var userPhone = (prefs.getString('userPhone') ?? '');
  //     print('in login userPhone: ${userPhone}');
  //   });
  // }

  List<DropdownMenuItem<String>> _country_codes = [];
  String _country_code = null;
  String url;

  void loadData() {
    _country_codes = [];
    _country_codes.add(
      new DropdownMenuItem(child: new Text('India'), value: '+91'),
    );
    _country_codes.add(
        new DropdownMenuItem(child: new Text('United States'), value: '+1'));
    _country_codes
        .add(new DropdownMenuItem(child: new Text('Japan'), value: '+08'));
  }

  Future<void> verifyPhone(_scaffoldKey) async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
      print('**in -> 1.AutoRetrivalTimeOut**' + verId);
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      print("2.smsSent_verifyid" + this.verificationId);

      this.smsCode_Sent = true;
      smsCodeDialog(_scaffoldKey).then((value) {
        print('** Done clicked **');
      });
    };

    final PhoneVerificationCompleted verifiedSuccess = (FirebaseUser user) {
      print('**4.verified**');
      // print('**4.verified** ${this.smsCode_Sent}');
      userVerified = true; //
//if verified and otp sent wait 10 sec and login
      if (this.smsCode_Sent == false) {
        print('smscode not sent ');
        this.loading = false;
        final snackBar = SnackBar(
          content: Text("Phone Number verified Successfully."),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
        register();
      } else {
        print('sent');
        final snackBar = SnackBar(
          content: Text("verified"),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('*5*Err ${exception.message}');

      final snackBar = SnackBar(
        content: Text(exception.message),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      this.loading = false;
      setState(() {});
    };

    await FirebaseAuth.instance
        .verifyPhoneNumber(
            phoneNumber: this._country_code + this.phoneNo,
            codeAutoRetrievalTimeout: autoRetrieve,
            codeSent: smsCodeSent,
            timeout: const Duration(seconds: 10),
            verificationCompleted: verifiedSuccess,
            verificationFailed: veriFailed)
        .then((value) {
      print('**************AFTER VF***********');
    });
  }

  smsCodeDialog(_scaffoldKey) {
    print('smsCode == :${this.smsCode_Sent}');
    this.loading = false;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter 6-digit Code'),
            content: TextField(
              decoration: InputDecoration(
                labelText: 'Enter OTP',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (value) {
                this.smsCode = value;
                //on 6th input auto nav
              },
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text('Resend'),
                onPressed: () {
                  Navigator.of(context).pop();
                  verifyPhone(_scaffoldKey);
                },
              ),
              new FlatButton(
                child: Text('Done'),
                onPressed: () {
                  // Navigator.pop(context);
                  setState(() {
                    this.loading = true;
                  });
                  print(this.smsCode.length);
                  if (this.smsCode.length == 6) {
                    FirebaseAuth.instance.currentUser().then((user) {
                      print('user ${user}');
                      if (user != null) {
                        register();
                        print('user:${user}');
                        print("phone" + this.phoneNo);
                      } else {
                        // final snackBar = SnackBar(
                        //   content: Text("Login failed."),
                        // );
                        // _scaffoldKey.currentState.showSnackBar(snackBar);
                        // Navigator.of(context).pop();
                        signIn(this.smsCode);
                      }
                    });
                  } else {
                    setState(() {
                      this.loading = false;
                    });
                    print("incorrect otp");
                    final snackBar = SnackBar(
                      content: Text("Enter 6-digit OTP"),
                    );
                    _scaffoldKey.currentState.showSnackBar(snackBar);
                    // Navigator.of(context).pop();
                  }
                },
              )
            ],
          );
        });
  }

  Future<void> register() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.loading = false;
      print('in register setState set...');
      prefs.setString('userPhone', this.phoneNo);
      print('phone after set reg ${this.phoneNo}');
    });
    print('after setting phone');
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserPinPage(
              phone: this.phoneNo,
            ),
      ),
    );
  }

  setUserTokenAndID(token, id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('UserToken', token);
    prefs.setInt('UserId', id);
    print(
        'set :..token: ${prefs.getString('UserToken')},id: ${prefs.getInt('UserId')}');
  }

  signIn(smscode) {
    FirebaseAuth.instance
        .signInWithPhoneNumber(verificationId: verificationId, smsCode: smsCode)
        .then((user) {
      print('auth user is ---- > $user');
      this.register();
    }, onError: (e) {
      print('....$e');
      setState(() {
        this.loading = false;
      });

      // if (userVerified == true) {
      //   final snackBar = SnackBar(
      //     content: Text(''),
      //   );
      //   _scaffoldKey.currentState.showSnackBar(snackBar);
      // }

      // if(e== 'PlatformException(exception, The sms code has expired. Please re-send the verification code to try again., null)'){
      //   final snackBar = SnackBar(
      //   content: Text('Got platform Ex'),
      // );
      // _scaffoldKey.currentState.showSnackBar(snackBar);
      // }
      print("incorrect otp");
      final snackBar = SnackBar(
        content: Text("$e"),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Navigator.of(context).pop();
    });
  }

  phoneConfirmAlert(_scaffoldKey) {
    if (formKey.currentState.validate()) {
      if (this._country_code == null) {
        final snackBar = SnackBar(content: Text("Select country code!"));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      } else {
        formKey.currentState.save();
        // this.phoneNo = this._country_code + this.phoneNo;
        return showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'Number Confirmation',
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  '${this._country_code}-${this.phoneNo} Is your phone number correct?', //use rich text
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                contentPadding: EdgeInsets.all(10.0),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Edit'),
                    onPressed: () {
                      // this.phoneNo = "";
                      Navigator.of(context).pop();
                    },
                  ),
                  new FlatButton(
                    child: Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        this.loading = true;
                      });
                      verifyPhone(_scaffoldKey);
                      // signIn(this.smsCode);

                      // register();
                    },
                  )
                ],
              );
            });
      }
    } else
      print("invalid form");
  }

  @override
  Widget build(BuildContext context) {
    loadData();
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
          title: new Text('Verify Your Phone Number'), centerTitle: true),
      resizeToAvoidBottomPadding: true,
      body: body(),
      //use this in Album pages
      //    bottomNavigationBar: BottomAppBar(
      //   child: new Row(
      //     mainAxisSize: MainAxisSize.max,
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: <Widget>[
      //       IconButton(icon: Icon(Icons.menu), onPressed: () {},),
      //       // IconButton(icon: Icon(Icons.search), onPressed: () {},),
      //     ],
      //   ),
      // ),
    );
  }

  Widget body() {
    if (loading == false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Expanded(
              child: ListView(
            padding: EdgeInsets.all(15.0),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 25.0),
              ),
              Text(
                "Please choose your country and enter your phone number",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(width: 1.0, color: Colors.black38),
                        bottom: BorderSide(width: 1.0, color: Colors.black38))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: _country_code,
                    items: _country_codes,
                    hint: new Text(
                      'Select Country',
                      style: TextStyle(color: Colors.black38),
                    ),
                    onChanged: (value) {
                      _country_code = value;
                      setState(() {
                        _country_code = value;
                      });
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 1.0, color: Colors.black38))),
                child: Form(
                    key: formKey,
                    autovalidate: true,
                    child: Column(children: <Widget>[
                      Table(
                        columnWidths: {1: FractionColumnWidth(.8)},
                        children: [
                          TableRow(children: [
                            Container(
                              padding:
                                  EdgeInsets.fromLTRB(10.0, 11.0, 0.0, 0.0),
                              child: Text(
                                (_country_code == null)
                                    ? ('+1')
                                    : _country_code,
                              ),
                            ),
                            TextField(
                                //TextFormField
                                decoration: InputDecoration(
                                  hintText: 'Enter Phone Number',
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (input) {
                                  print(input);
                                  if (input.length == 10) {
                                    setState(() {
                                      verifybtn = true;
                                      this.phoneNo = input;
                                      phoneConfirmAlert(
                                        _scaffoldKey,
                                      );
                                    });
                                  } else {
                                    setState(() {
                                      verifybtn = false;
                                    });
                                  }
                                }),
                          ]),
                        ],
                      ),
                    ])),
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  'You will receive an OTP on the mobile number you have..',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ],
          )),
          Container(
            padding: EdgeInsets.only(bottom: 2.0),
            child: SizedBox(
              height: 55.0,
              child: RaisedButton(
                child: Text(
                  'Verify',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                splashColor: Colors.green,
                color: Colors.indigo[400],
                // shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(30.0)),
                onPressed: !verifybtn
                    ? null
                    : () {
                        print('${this._country_code}-${this.phoneNo}');
                        phoneConfirmAlert(
                          _scaffoldKey,
                        );
                      },
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  //bottomSheet (list of clgs to share video)
  shareWith() {
    showModalBottomSheet(
        context: context,
        // barrierDismissible: false,
        builder: (builder) {
          return new Container();
        });
  }
}
