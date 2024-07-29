import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _resNumController = TextEditingController();
  final TextEditingController _phoneNumController = TextEditingController();

  final FocusNode _nicknameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmFocusNode = FocusNode();
  final FocusNode _resNumFocusNode = FocusNode();
  final FocusNode _phoneNumFocusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();

  bool _passwordsMatch = true;
  bool _emailVerified = false;
  User? _currentUser;

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch =
          _passwordController.text == _passwordConfirmController.text;
    });
  }

  Future<void> _sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      _showErrorDialog("이메일 전송", "이메일을 확인하고 인증을 완료해주세요.");
    } catch (e) {
      _showErrorDialog("오류", "이메일 인증 중 오류가 발생했습니다: $e");
    }
  }

  Future<bool> _isEmailInUse(String email) async {
    List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  Future<bool> _isNicknameInUse(String nickname) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> _isPhoneNumInUse(String phoneNum) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('phoneNum', isEqualTo: phoneNum)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<String> emailSignUp({
    required String nickname,
    required String email,
    required String password,
    required String phoneNum,
    String? resNum,
  }) async {
    try {
      // Check if nickname already exists
      bool nicknameInUse = await _isNicknameInUse(nickname);
      if (nicknameInUse) {
        return "nickname-already-in-use"; // Nickname already exists
      }

      // Check if business registration number already exists
      if (resNum != null && resNum.isNotEmpty) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .where('resNum', isEqualTo: resNum)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return "resNum-exists"; // Business registration number already exists
        }
      }

      // Check if email already exists
      bool emailInUse = await _isEmailInUse(email);
      if (emailInUse) {
        return "email-already-in-use"; // Email already exists
      }

      // Check if phone number already exists
      bool phoneNumInUse = await _isPhoneNumInUse(phoneNum);
      if (phoneNumInUse) {
        return "phoneNum-already-in-use"; // Phone number already exists
      }

      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'nickname': nickname,
          'email': email,
          'phoneNum': phoneNum,
          'resNum': resNum,
        });

        return "success"; // Registration successful
      } else {
        return "fail"; // Registration failed
      }
    } on FirebaseAuthException catch (e) {
      return "fail"; // Other errors
    } catch (e) {
      return "fail"; // General error
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("확인"),
          ),
        ],
      ),
    );
  }

  bool _validateNickname(String nickname) {
    final RegExp nicknameExp = RegExp(r'^[가-힣]+$');
    return nicknameExp.hasMatch(nickname) &&
        nickname.length >= 2 &&
        nickname.length <= 7;
  }

  bool _validatePhoneNum(String phoneNum) {
    final RegExp phoneExp = RegExp(r'^010-\d{4}-\d{4}$');
    return phoneExp.hasMatch(phoneNum);
  }

  bool _validatePassword(String password) {
    final RegExp passwordExp = RegExp(r'^(?=.*[a-z]).{6,10}$');
    return passwordExp.hasMatch(password);
  }

  bool _validateResNum(String resNum) {
    final RegExp resNumExp = RegExp(r'^\d*$');
    return resNumExp.hasMatch(resNum);
  }

  bool _isFormValid() {
    bool nicknameValid = _validateNickname(_nicknameController.text);
    bool passwordValid = _validatePassword(_passwordController.text);
    bool phoneNumValid = _validatePhoneNum(_phoneNumController.text);
    bool passwordsMatch = _passwordsMatch;
    bool emailVerified = _emailVerified;

    print("Nickname valid: $nicknameValid");
    print("Password valid: $passwordValid");
    print("Phone number valid: $phoneNumValid");
    print("Passwords match: $passwordsMatch");
    print("Email verified: $emailVerified");

    return nicknameValid &&
        passwordValid &&
        passwordsMatch &&
        phoneNumValid &&
        emailVerified;
  }

  void _scrollToFocusedNode(FocusNode focusNode) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollToFocusedNode(_nicknameFocusNode);
    _scrollToFocusedNode(_emailFocusNode);
    _scrollToFocusedNode(_passwordFocusNode);
    _scrollToFocusedNode(_passwordConfirmFocusNode);
    _scrollToFocusedNode(_resNumFocusNode);
    _scrollToFocusedNode(_phoneNumFocusNode);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _resNumController.dispose();
    _phoneNumController.dispose();

    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    _resNumFocusNode.dispose();
    _phoneNumFocusNode.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.white, // 배경 색상 설정
                ),
              ),
              Column(children: [
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
                SizedBox(height: 20),
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
                                color: Color(0xFF6495ED),
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
                            Navigator.pushNamed(context, '/');
                          },
                          child: Text(
                            '로그인',
                            style: TextStyle(
                              color: Color(0xFF89909E),
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
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: TextField(
                            controller: _nicknameController,
                            focusNode: _nicknameFocusNode,
                            decoration: InputDecoration(
                              labelText: '닉네임',
                              errorText: _nicknameFocusNode.hasFocus ||
                                      _nicknameController.text.isNotEmpty
                                  ? _validateNickname(
                                          _nicknameController.text)
                                      ? null
                                      : '한글만 입력 가능하며 2글자 이상 7글자 이하이어야 합니다'
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  decoration: InputDecoration(
                                    labelText: '이메일',
                                    
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              ElevatedButton(
                                onPressed: () async {
                                  // 이메일 인증 버튼 눌렀을 때 동작
                                  String email =
                                      _emailController.text.trim();
                                  bool emailInUse =
                                      await _isEmailInUse(email);
                                  if (emailInUse) {
                                    _showErrorDialog(
                                        "오류", "이미 등록되어 있는 메일이 있습니다.");
                                    return;
                                  }
                            
                                  try {
                                    UserCredential userCredential =
                                        await _auth
                                            .createUserWithEmailAndPassword(
                                      email: email,
                                      password: 'temporaryPassword',
                                    );
                                    User? user = userCredential.user;
                                    if (user != null) {
                                      await _sendEmailVerification(user);
                                      setState(() {
                                        _emailVerified = true;
                                        _currentUser = user;
                                      });
                                    } else {
                                      _showErrorDialog(
                                          "오류", "이메일 인증에 실패했습니다.");
                                    }
                                  } catch (e) {
                                    _showErrorDialog(
                                        "오류", "이메일 인증 중 오류가 발생했습니다: $e");
                                  }
                                },
                                child: Text(
                                  '이메일 인증',
                                  style: TextStyle(color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(
                                          Color(0xFFbbdefb)),
                        
                                  minimumSize: MaterialStateProperty.all(
                                      Size(50, 45)),
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.symmetric(horizontal: 10)),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: TextField(
                            controller: _phoneNumController,
                            focusNode: _phoneNumFocusNode,
                            decoration: InputDecoration(
                              labelText: '전화번호',
                              errorText: _phoneNumFocusNode.hasFocus ||
                                      _phoneNumController.text.isNotEmpty
                                  ? _validatePhoneNum(
                                          _phoneNumController.text)
                                      ? null
                                      : '010-0000-0000 형식으로 입력해주세요'
                                  : null,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                              PhoneNumberTextInputFormatter(),
                            ],
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              
                              errorText: _passwordFocusNode.hasFocus ||
                                      _passwordController.text.isNotEmpty
                                  ? _validatePassword(
                                          _passwordController.text)
                                      ? null
                                      : '비밀번호는 6글자 이상 10글자 이하이고 영어 소문자를 포함해야 합니다'
                                  : null,
                            ),
                            obscureText: true,
                            onChanged: (value) {
                              _checkPasswordsMatch();
                              setState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: TextField(
                            controller: _passwordConfirmController,
                            focusNode: _passwordConfirmFocusNode,
                            decoration: InputDecoration(
                              labelText: '비밀번호 재입력',
                              
                              errorText:
                                  _passwordConfirmFocusNode.hasFocus ||
                                          _passwordConfirmController
                                              .text.isNotEmpty
                                      ? _passwordsMatch
                                          ? null
                                          : '비밀번호가 일치하지 않습니다'
                                      : null,
                            ),
                            obscureText: true,
                            onChanged: (value) {
                              _checkPasswordsMatch();
                              setState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(40, 10, 40, 5),
                          child: TextField(
                            controller: _resNumController,
                            focusNode: _resNumFocusNode,
                            decoration: InputDecoration(
                              labelText: '사업자등록번호 (선택사항)',
                              errorText: _resNumFocusNode.hasFocus ||
                                      _resNumController.text.isNotEmpty
                                  ? _validateResNum(_resNumController.text)
                                      ? null
                                      : '숫자만 입력 가능합니다'
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            // 입력된 값들 가져오기
                            String nickname =
                                _nicknameController.text.trim();
                            String email = _emailController.text.trim();
                            String password = _passwordController.text;
                            String passwordConfirm =
                                _passwordConfirmController.text;
                            String phoneNum =
                                _phoneNumController.text.trim();
                            String resNum = _resNumController.text.trim();
                            
                            // 필드가 비어있는지 확인
                            if (nickname.isEmpty ||
                                !_validateNickname(nickname)) {
                              _showErrorDialog("오류", "닉네임을 올바르게 입력해주세요.");
                              return;
                            }
                            
                            if (email.isEmpty) {
                              _showErrorDialog("오류", "이메일 주소를 입력해주세요.");
                              return;
                            }
                            
                            if (password.isEmpty ||
                                !_validatePassword(password)) {
                              _showErrorDialog("오류", "비밀번호를 올바르게 입력해주세요.");
                              return;
                            }
                            
                            if (passwordConfirm.isEmpty) {
                              _showErrorDialog("오류", "비밀번호 재입력을 해주세요.");
                              return;
                            }
                            
                            if (password != passwordConfirm) {
                              _showErrorDialog("오류", "비밀번호가 일치하지 않습니다.");
                              return;
                            }
                            
                            if (phoneNum.isEmpty ||
                                !_validatePhoneNum(phoneNum)) {
                              _showErrorDialog("오류", "전화번호를 올바르게 입력해주세요.");
                              return;
                            }
                            
                            if (!_emailVerified) {
                              _showErrorDialog("오류", "이메일 인증을 완료해주세요.");
                              return;
                            }
                            
                            if (resNum.isNotEmpty &&
                                !_validateResNum(resNum)) {
                              _showErrorDialog(
                                  "오류", "사업자등록번호를 올바르게 입력해주세요.");
                              return;
                            }
                            
                            // 회원가입 시도
                            String result = await emailSignUp(
                              nickname: nickname,
                              email: email,
                              password: password,
                              phoneNum: phoneNum,
                              resNum: resNum.isNotEmpty ? resNum : null,
                            );
                            
                            // 등록 결과에 따라 처리
                            switch (result) {
                              case "success":
                                if (_currentUser != null) {
                                  await _currentUser!
                                      .updatePassword(password);
                                }
                                Navigator.pushNamed(context, '/');
                                break;
                              case "nickname-already-in-use":
                                _showErrorDialog("오류", "동일한 닉네임이 존재합니다.");
                                break;
                              case "email-already-in-use":
                                _showErrorDialog(
                                    "오류", "이미 등록되어 있는 메일이 있습니다.");
                                break;
                              case "phoneNum-already-in-use":
                                _showErrorDialog("오류", "이미 전화번호가 존재합니다.");
                                break;
                              case "resNum-exists":
                                _showErrorDialog(
                                    "오류", "이미 존재하는 사업자등록번호입니다.");
                                break;
                              case "fail":
                                if (_currentUser != null) {
                                  await _currentUser!.delete();
                                }
                            
                                break;
                              default:
                                break;
                            }
                          },
                          child: Text(
                            '회원가입',
                            style: TextStyle(
                              color: _isFormValid()
                                  ? Colors.white
                                  : Color(0xFF89909E),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              _isFormValid()
                                  ? Color(0xFF1A94FF)
                                  : Color(0xFFF4F4F4),
                            ),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.black),
                            minimumSize:
                                MaterialStateProperty.all(Size(200, 50)),
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
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final int oldTextLength = oldValue.text.length;
    final int newTextLength = newValue.text.length;

    final StringBuffer newText = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < newTextLength; i++) {
      if (i == 3 || i == 7) {
        newText.write('-');
        if (i <= selectionIndex) selectionIndex++;
      }
      newText.write(newValue.text[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
