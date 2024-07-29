import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class nonMemberInfo extends StatefulWidget {
  const nonMemberInfo({super.key});

  @override
  _NonMemberInfoState createState() => _NonMemberInfoState();
}

class _NonMemberInfoState extends State<nonMemberInfo> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: '010-');

  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _isNicknameExists(String nickname) async {
    final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    final QuerySnapshot nonMemberSnapshot = await FirebaseFirestore.instance
        .collection('non_members')
        .where('nickname', isEqualTo: nickname)
        .get();
    return userSnapshot.docs.isNotEmpty || nonMemberSnapshot.docs.isNotEmpty;
  }

  Future<bool> _isPhoneExists(String phone) async {
    final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNum', isEqualTo: phone)
        .get();
    final QuerySnapshot nonMemberSnapshot = await FirebaseFirestore.instance
        .collection('non_members')
        .where('phoneNum', isEqualTo: phone)
        .get();
    return userSnapshot.docs.isNotEmpty || nonMemberSnapshot.docs.isNotEmpty;
  }

  Future<void> _saveNonMemberInfo() async {
    try {
      final nickname = _nicknameController.text.trim();
      final phone = _phoneController.text.trim();

      if (nickname.isEmpty || nickname.length < 2 || nickname.length > 7) {
        setState(() {
          _errorMessage = '닉네임은 2글자 이상 7글자 이하로 입력해주세요.';
        });
        return;
      }

      if (phone.isEmpty || !_isValidPhoneNumber(phone)) {
        setState(() {
          _errorMessage = '전화번호를 010-0000-0000 형식으로 입력해주세요.';
        });
        return;
      }

      if (await _isNicknameExists(nickname)) {
        setState(() {
          _errorMessage = '이미 존재하는 닉네임입니다. 다른 닉네임을 입력해주세요';
        });
        return;
      }

      if (await _isPhoneExists(phone)) {
        setState(() {
          _errorMessage = '이미 존재하는 전화번호입니다. 다른 전화번호를 입력해주세요';
        });
        return;
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      User? user = userCredential.user;

      if (user != null) {
        final nonMemberData = {
          'nickname': nickname,
          'phoneNum': phone,
          'timestamp': FieldValue.serverTimestamp(),
          'isSaved': true, // 구별할 수 있는 변수 추가
          'uid': user.uid, // 비회원 로그인 정보 추가
        };

        await FirebaseFirestore.instance
            .collection('non_members')
            .add(nonMemberData);

        print('Non-member info saved successfully');
        Navigator.pushNamed(context, '/nonMemberHome');
      } else {
        print('Error: User is null');
      }
    } catch (e) {
      print('Error saving non-member info: $e');
    }
  }

  bool _isValidPhoneNumber(String phone) {
    final phoneRegExp = RegExp(r'^010-\d{4}-\d{4}$');
    return phoneRegExp.hasMatch(phone);
  }

  String _formatPhoneNumber(String value) {
    value =
        value.replaceAll(RegExp(r'\D'), ''); // Remove all non-digit characters
    if (value.length > 3) {
      value = value.substring(0, 3) + '-' + value.substring(3);
    }
    if (value.length > 8) {
      value = value.substring(0, 8) + '-' + value.substring(8);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('정보입력'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            Text(
              '닉네임',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
              ),
            ),
            TextFormField(
              controller: _nicknameController,
              decoration: InputDecoration(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(7),
              ],
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 30),
            Text(
              '전화번호',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
              ),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '010-0000-0000',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                LengthLimitingTextInputFormatter(13),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) {
                    String newText = _formatPhoneNumber(newValue.text);
                    if (!newText.startsWith('010-')) {
                      newText = '010-' + newText.replaceAll('010-', '');
                    }
                    return TextEditingValue(
                      text: newText,
                      selection:
                          TextSelection.collapsed(offset: newText.length),
                    );
                  },
                ),
              ],
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 30),
            ],
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _saveNonMemberInfo();
                },
                child: Text('다음'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.lightBlueAccent),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                  minimumSize: MaterialStateProperty.all(Size(200, 50)),
                  padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 10)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
