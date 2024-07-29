import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class findPassword extends StatefulWidget {
  @override
  _FindPasswordState createState() => _FindPasswordState();
}

class _FindPasswordState extends State<findPassword> {
  final TextEditingController emailController = TextEditingController();
  bool _isEmailFilled = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateEmailState);
  }

  @override
  void dispose() {
    emailController.removeListener(_updateEmailState);
    emailController.dispose();
    super.dispose();
  }

  void _updateEmailState() {
    setState(() {
      _isEmailFilled = emailController.text.isNotEmpty;
    });
  }

  Future<void> sendResetEmail(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Email Sent'),
            content: Text(
                'Password reset email sent to ${emailController.text.trim()}'),
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
      Navigator.pushNamed(context, '/findPassword_email');
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('오류'),
            content: Text('이메일 보내기 실패하였습니다. 이메일을 확인해주세요.'),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 150,
                child: SizedBox(
                  width: 270,
                  child: Text(
                    '이메일을 입력해주세요.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 0.08,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 100,
                child: Text(
                  '비밀번호 찾기',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 0.09,
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 220,
                child: Text(
                  'Email address',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 0.18,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 250, 30, 0),
                child: Container(
                  width: double.infinity,
                  height: 82,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'wait@yonsei.ac.kr',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.24,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFBEC5D1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 330,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, fontFamily: 'Inter'),
                    children: [
                      TextSpan(
                        text: 'Remember the password?',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      WidgetSpan(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            ' Sign in',
                            style: TextStyle(
                              color: Color(0xFF1A94FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 550),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailFilled
                          ? Color(0xFF1A94FF)
                          : Color(0xFFF4F4F4),
                      padding:
                          EdgeInsets.symmetric(horizontal: 120, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isEmailFilled
                        ? () {
                            sendResetEmail(context);
                          }
                        : null,
                    child: Text(
                      '전송',
                      style: TextStyle(
                        color:
                            _isEmailFilled ? Colors.white : Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
