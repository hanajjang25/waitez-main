import 'package:flutter/material.dart';

class setting extends StatefulWidget {
  @override
  _settingState createState() => _settingState();
}

class _settingState extends State<setting> {
  bool smsAlert = false;
  bool appAlert = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          ListTile(
            title: Text('SMS알림'),
            trailing: Switch(
              value: smsAlert,
              onChanged: (value) {
                setState(() {
                  smsAlert = value;
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('앱 알림'),
            trailing: Switch(
              value: appAlert,
              onChanged: (value) {
                setState(() {
                  appAlert = value;
                });
              },
            ),
          ),
          Divider(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: '대기 순번',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '이력 조회',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '즐겨 찾기',
          ),
        ],
      ),
    );
  }
}
