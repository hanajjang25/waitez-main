import 'package:flutter/material.dart';

class menuButtom extends StatelessWidget {
  const menuButtom({super.key});

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
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/favorite');
            break;
          case 2:
            Navigator.pushNamed(context, '/search');
            break;
          case 3:
            Navigator.pushNamed(context, '/community');
            break;
          case 4:
            Navigator.pushNamed(context, '/profile');
            break;
          default:
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'favortie'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'reservation'),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'community'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), label: 'profile'),
      ],
    );
  }
}
