import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RestaurantEdit.dart';

class staffBottom extends StatelessWidget {
  void _showNumberConfirmDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('등록번호'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('등록번호를 입력해주세요.'),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '등록번호'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '등록번호를 입력해주세요.';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return '숫자만 입력이 가능합니다.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String registrationNumber = _controller.text;
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      // Firestore에서 사용자 이메일로 사업자등록번호 확인
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      if (userDoc.exists &&
                          userDoc.data()!.containsKey('resNum')) {
                        String userRegistrationNumber = userDoc['resNum'];
                        if (userRegistrationNumber == registrationNumber) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => editregRestaurant(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('등록번호가 일치하지 않습니다.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('등록번호 필드가 존재하지 않습니다.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
                    );
                  }
                }
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

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
            Navigator.pushNamed(context, '/homeStaff');
            break;
          case 1:
            Navigator.pushNamed(context, '/regRestaurant');
            break;
          case 2:
            Navigator.pushNamed(context, '/MenuRegList');
            break;
          case 3:
            _showNumberConfirmDialog(context);
            break;
          case 4:
            Navigator.pushNamed(context, '/menuEdit');
            break;
          case 5:
            Navigator.pushNamed(context, '/staffProfile');
            break;
          default:
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '음식점 등록'),
        BottomNavigationBarItem(icon: Icon(Icons.lunch_dining), label: '메뉴 등록'),
        BottomNavigationBarItem(icon: Icon(Icons.edit), label: '음식점 수정'),
        BottomNavigationBarItem(icon: Icon(Icons.local_dining), label: '메뉴 수정'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '프로필'),
      ],
    );
  }
}
