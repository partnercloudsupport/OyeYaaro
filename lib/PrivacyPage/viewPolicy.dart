import 'package:flutter/material.dart';

class ViewPolicy extends StatefulWidget {
  @override
  ViewPolicyState createState() => new ViewPolicyState();
}

class ViewPolicyState extends State<ViewPolicy> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Terms & Privacy Policies'),
      ),
      body: Center(
        // child: Text("Working.."),
      ),
    );
  }
}
