import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class findPasswordEmail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 비밀번호 재설정 이메일을 다시 보내는 함수
    void resendResetEmail() async {
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      if (user != null) {
        try {
          await _auth.sendPasswordResetEmail(email: user.email!);
          print('Password reset email sent');
        } catch (e) {
          print('Error sending password reset email: $e');
        }
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(
                  left: 180,
                  top: 295,
                  child: Container(
                    width: 82,
                    height: 82,
                    child: Image.asset('assets/images/sendmail.png'),
                  ),
                ),
                Positioned(
                  left: 170,
                  top: 400,
                  child: Text(
                    '이메일 전송',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 0.06,
                    ),
                  ),
                ),
                Positioned(
                  left: 80,
                  top: 450,
                  child: SizedBox(
                    width: 283,
                    child: Text(
                      '이메일을 확인 후\n 새비밀번호를 만드세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 200), // 상단 여백 설정
                  child: Center(
                    // 전체 내용을 가운데 정렬
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 최소 크기로 자식들을 가운데 정렬
                      children: [
                        Text(
                          "이메일을 받지 못했나요? ",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 1.2, // 텍스트 높이 조정
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        TextButton(
                          onPressed: () {
                            resendResetEmail();
                          },
                          style: TextButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            '재전송',
                            style: TextStyle(
                              color: Color(0xFF1A94FF),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 500), // 상단 여백 설정
                  child: Center(
                    // 버튼을 가운데 정렬
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A94FF), // 버튼의 배경색 설정
                        padding: EdgeInsets.symmetric(
                            horizontal: 64, vertical: 16), // 내부 패딩 설정
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // 버튼의 모서리를 둥글게 처리
                        ),
                        minimumSize: Size(256, 48), // 버튼의 최소 크기 설정
                      ),
                      child: Text(
                        '로그인 페이지로 이동',
                        style: TextStyle(
                          color: Colors.white,
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
        ],
      ),
    );
  }
}
