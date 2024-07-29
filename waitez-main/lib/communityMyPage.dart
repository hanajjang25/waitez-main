import 'package:flutter/material.dart';
import 'UserBottom.dart';

class communityMyPage extends StatefulWidget {
  const communityMyPage({super.key});

  @override
  State<communityMyPage> createState() => _communityMyPageState();
}

class _communityMyPageState extends State<communityMyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 30),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '커뮤니티',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.27,
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
                width: 500,
                child: Divider(color: Colors.black, thickness: 1.0)),
          ],
        ),
      ),
      bottomNavigationBar: menuButtom(),
    );
    ;
  }
}
