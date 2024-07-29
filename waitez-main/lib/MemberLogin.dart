import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<login> {
  int authWay = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isFormValid = false;

  void _updateFormValidity() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  Future<String> emailLogin({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      user = _auth.currentUser;

      if (user != null) {
        await user!.reload();
        user = _auth.currentUser;

        user = userCredential.user;
        authWay = 1;

        // Fetch user's noShowCount and lastLogin
        var userDoc = await _firestore.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          var userData = userDoc.data()!;
          int noShowCount = userData['noShowCount'] ?? 0;
          Timestamp lastLogin = userData['lastLogin'] ?? Timestamp.now();

          // Check if noShowCount % 4 == 0 and if lastLogin is within the last week
          if (noShowCount % 4 == 0 && noShowCount != 0) {
            DateTime lastLoginDate = lastLogin.toDate();
            DateTime now = DateTime.now();
            if (now.difference(lastLoginDate).inDays < 7) {
              return "blocked"; // User is blocked due to noShowCount
            }
          }

          await _saveLoginStatus(true);
          await _updateLoginState(user!.uid, true); // 로그인 상태 업데이트

          return "success";
        } else {
          return "userNotFound";
        }
      } else {
        return "userNotFound";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "userNotFound";
      } else if (e.code == 'wrong-password') {
        return "wrongPassword";
      }
      return "fail";
    } catch (e) {
      print('Exception: $e');
      return "fail";
    }
  }

  Future<void> _updateLoginState(String userId, bool isLoggedIn) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLoggedIn': isLoggedIn,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating login state: $e');
    }
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateFormValidity);
    _passwordController.removeListener(_updateFormValidity);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                ),
              ),
              Column(
                children: [
                  SizedBox(height: 200),
                  Text(
                    'Waitez',
                    style: TextStyle(
                      color: Color(0xFF4169E1),
                      fontSize: 50,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Transform.translate(
                    offset: Offset(-10, 0),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Color(0xFF89909E),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 80),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                color: Color(0xFF6495ED),
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(40,0,40,0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.fromLTRB(40,0,40,0),
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                      ),
                      obscureText: true,
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.only(left: 200),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/findPassword');
                      },
                      child: Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          color: Color(0xFF6495ED),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isFormValid
                        ? () async {
                            if (_emailController.text.trim().isEmpty ||
                                _passwordController.text.trim().isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Error'),
                                    content:
                                        Text('Please check email and password'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            String loginResult = await emailLogin(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            if (loginResult == "success") {
                              var email = _emailController.text.trim();
                              var userDoc = await _firestore
                                  .collection('users')
                                  .where('email', isEqualTo: email)
                                  .get();

                              if (userDoc.docs.isNotEmpty) {
                                var userData = userDoc.docs.first.data();
                                if (userData.containsKey('nickname')) {
                                  if (userData.containsKey('resNum') &&
                                      userData['resNum'] != null &&
                                      userData['resNum'].isNotEmpty) {
                                    Navigator.pushNamed(context, '/homeStaff');
                                  } else {
                                    Navigator.pushNamed(context, '/home');
                                  }
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('로그인실패'),
                                        content: Text('이메일 및 비밀번호가 일치하지 않습니다.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('로그인 오류'),
                                      content: Text('아이디 및 비밀번호가 일치하지 않습니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } else if (loginResult == "blocked") {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('로그인 오류'),
                                    content:
                                        Text('누적된 노쇼로 인해 일주일 동안 로그인할 수 없습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              String errorMessage;
                              switch (loginResult) {
                                case 'userNotFound':
                                  errorMessage = '회원이 존재하지 않습니다.';
                                  break;
                                case 'wrongPassword':
                                  errorMessage = '비밀번호가 일치하지 않습니다.';
                                  break;
                                case 'fail':
                                default:
                                  errorMessage = '로그인에 실패하였습니다. 다시 시도하세요.';
                                  break;
                              }
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('로그인 오류'),
                                    content: Text(errorMessage),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }
                        : null,
                    child: Text('login'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          _isFormValid ? Color(0xFF1A94FF) : Color(0xFFF4F4F4)),
                      foregroundColor: MaterialStateProperty.all(
                          _isFormValid ? Colors.white : Colors.black),
                      minimumSize: MaterialStateProperty.all(Size(200, 50)),
                      padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(horizontal: 30)),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), 
                  Padding(
                      padding: EdgeInsets.fromLTRB(40,10,40,10),
                      child: Divider(color: Colors.grey, thickness: 1.0)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/nonMemberInfo');
                      },
                      child: Text(
                        '비회원으로 예약하기',
                        style: TextStyle(
                          color: Color(0xFF4682B4),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
