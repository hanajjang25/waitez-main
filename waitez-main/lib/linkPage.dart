import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_database/firebase_database.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Waitez'),
          Wrap(
            children: [
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text('로그인')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('회원가입')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/waitingNumber');
                  },
                  child: Text('대기순번')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  child: Text('home')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/homeStaff');
                  },
                  child: Text('직원home')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  child: Text('이력조회')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/map');
                  },
                  child: Text('지도')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sendingMessage');
                  },
                  child: Text('문자')),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/nonMemberWaitingNumber');
                  },
                  child: Text('비회원대기순번')),
            ],
          ),
        ]),
      ),
    );
  }
}
