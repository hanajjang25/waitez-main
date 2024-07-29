import 'package:flutter/material.dart';

class nonMemberBottom extends StatelessWidget {
  const nonMemberBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 13, // 선택된 아이템과 비선택된 아이템의 텍스트 크기를 같게
      unselectedFontSize: 13,
      onTap: (int index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/nonMemberHome');
            break;
          case 1:
            Navigator.pushNamed(context, '/search');
            break;
          default:
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'reservation'),
      ],
    );
  }
}
