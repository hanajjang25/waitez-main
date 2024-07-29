import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'reservationBottom.dart';

class Reservation extends StatefulWidget {
  @override
  _ReservationState createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  int numberOfPeople = 0;
  bool isPeopleSelectorEnabled = false;
  bool isFirstClick = true;

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _saveReservation(BuildContext context, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String nickname = '';
      if (userDoc.exists) {
        nickname = userDoc.data()?['nickname'] ?? '';
      } else {
        final nonMemberQuery = await FirebaseFirestore.instance
            .collection('non_members')
            .where('uid', isEqualTo: user.uid)
            .get();
        if (nonMemberQuery.docs.isNotEmpty) {
          final nonMemberData = nonMemberQuery.docs.first.data();
          nickname = nonMemberData['nickname'] ?? '';
        } else {
          print('User document does not exist.');
          return;
        }
      }

      // Check for existing dine-in reservations for the current day
      if (type == '매장') {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final reservationQuery = await FirebaseFirestore.instance
            .collection('reservations')
            .where('nickname', isEqualTo: nickname)
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('type', isEqualTo: 1) // Dine-in type
            .where('status', isEqualTo: 'confirmed')
            .get();

        if (reservationQuery.docs.isNotEmpty) {
          showSnackBar(context, '매장은 최대 1개까지 예약이 가능합니다.');
          return;
        }
      }

      final reservationData = {
        'nickname': nickname,
        'type': type == '매장' ? 1 : 2,
        'timestamp': Timestamp.now(),
        'numberOfPeople': type == '매장' ? numberOfPeople : null,
        'status': 'confirmed', // 추가된 필드: 예약 상태를 "confirmed"로 설정
      };

      final recentReservationQuery = await FirebaseFirestore.instance
          .collection('reservations')
          .where('nickname', isEqualTo: nickname)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (recentReservationQuery.docs.isNotEmpty) {
        final recentReservationDoc =
            recentReservationQuery.docs.first.reference;
        await recentReservationDoc.update(reservationData);
      } else {
        // Save the reservation data to Firestore
        await FirebaseFirestore.instance
            .collection('reservations')
            .add(reservationData);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InfoInputScreen(numberOfPeople: numberOfPeople),
        ),
      );
    } else {
      print('User is not logged in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '매장/포장 선택',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
            height: 0.07,
            letterSpacing: -0.27,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (isFirstClick) {
                  setState(() {
                    isPeopleSelectorEnabled = true;
                    isFirstClick = false;
                  });
                  showSnackBar(context, '인원수를 선택하세요');
                } else {
                  if (numberOfPeople > 0) {
                    _saveReservation(context, '매장');
                  }
                  if (numberOfPeople > 10) {
                    showSnackBar(context, '인원수는 10명을 초과할 수 없습니다.');
                  } else {
                    showSnackBar(context, '인원수를 선택하세요');
                  }
                }
              },
              child: Text('매장'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue[500]),
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
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('인원수'),
                SizedBox(width: 50),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: isPeopleSelectorEnabled
                          ? () {
                              setState(() {
                                if (numberOfPeople > 0) {
                                  numberOfPeople--;
                                }
                              });
                            }
                          : null,
                    ),
                    Text('$numberOfPeople'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: isPeopleSelectorEnabled && numberOfPeople < 10
                          ? () {
                              setState(() {
                                if (numberOfPeople < 10) {
                                  numberOfPeople++;
                                }
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _saveReservation(context, '포장');
              },
              child: Text('포장'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue[500]),
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
          ],
        ),
      ),
      bottomNavigationBar: reservationBottom(),
    );
  }
}

class InfoInputScreen extends StatefulWidget {
  final int numberOfPeople;

  InfoInputScreen({required this.numberOfPeople});

  @override
  _InfoInputScreenState createState() => _InfoInputScreenState();
}

class _InfoInputScreenState extends State<InfoInputScreen> {
  late int numberOfPeople;
  final TextEditingController _nicknameController =
      TextEditingController(text: '');
  final TextEditingController _phoneController =
      TextEditingController(text: '');
  final TextEditingController _altPhoneController =
      TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    numberOfPeople = widget.numberOfPeople;
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _nicknameController.text = data['nickname'] ?? '';
            _phoneController.text = data['phoneNum'] ?? '';
          });
        } else {
          final nonMemberQuery = await FirebaseFirestore.instance
              .collection('non_members')
              .where('uid', isEqualTo: user.uid)
              .get();
          if (nonMemberQuery.docs.isNotEmpty) {
            final nonMemberData = nonMemberQuery.docs.first.data();
            setState(() {
              _nicknameController.text = nonMemberData['nickname'] ?? '';
              _phoneController.text = nonMemberData['phoneNum'] ?? '';
            });
          } else {
            print('Non-member document does not exist.');
          }
        }
      } else {
        print('User is not logged in.');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  String _formatPhoneNumber(String value) {
    value = value.replaceAll('-', ''); // 기존의 대시를 제거
    if (value.length > 3) {
      value = value.substring(0, 3) + '-' + value.substring(3);
    }
    if (value.length > 8) {
      value = value.substring(0, 8) + '-' + value.substring(8);
    }
    return value;
  }

  Future<void> _saveReservationInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore 트랜잭션 사용하여 업데이트
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final reservationQuery = await FirebaseFirestore.instance
              .collection('reservations')
              .where('nickname', isEqualTo: _nicknameController.text)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          // 디버깅: 쿼리 결과 로그 출력
          print('Query Result Count: ${reservationQuery.docs.length}');
          reservationQuery.docs.forEach((doc) {
            print('Document ID: ${doc.id}, Data: ${doc.data()}');
          });

          if (reservationQuery.docs.isNotEmpty) {
            final reservationDoc = reservationQuery.docs.first.reference;
            transaction.update(reservationDoc, {
              'numberOfPeople': numberOfPeople,
              'altPhoneNum': _altPhoneController.text,
            });

            print('Reservation updated successfully');
          } else {
            print('No recent reservation found for this user.');
          }
        });

        Navigator.pushNamed(context, '/waitingNumber');
      } else {
        print('User is not logged in.');
      }
    } catch (e) {
      print('Error saving reservation info: $e');
    }
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
        child: SingleChildScrollView(
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
                readOnly: true, // 텍스트 필드를 읽기 전용으로 설정
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
                decoration: InputDecoration(),
                readOnly: true, // 텍스트 필드를 읽기 전용으로 설정
              ),
              SizedBox(height: 30),
              Text(
                '보조전화번호',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                ),
              ),
              TextFormField(
                controller: _altPhoneController,
                decoration: InputDecoration(
                  hintText: '010-0000-0000',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) {
                      String newText = _formatPhoneNumber(newValue.text);
                      return TextEditingValue(
                        text: newText,
                        selection:
                            TextSelection.collapsed(offset: newText.length),
                      );
                    },
                  ),
                ],
                keyboardType: TextInputType.number,
                readOnly: false, // 보조 전화번호는 편집 가능하도록 설정
              ),
              SizedBox(height: 100),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveReservationInfo();
                    Navigator.pushNamed(
                      context,
                      '/reservationMenu',
                    );
                  },
                  child: Text('다음'),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blue[500]),
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
      ),
      bottomNavigationBar: reservationBottom(),
    );
  }
}
