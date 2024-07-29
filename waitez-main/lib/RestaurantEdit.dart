import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'googleMap.dart';

class editregRestaurant extends StatefulWidget {
  const editregRestaurant({super.key});

  @override
  _EditRegRestaurantState createState() => _EditRegRestaurantState();
}

class _EditRegRestaurantState extends State<editregRestaurant> {
  final _formKey = GlobalKey<FormState>();
  String _restaurantId = '';
  String _restaurantName = '';
  String _location = '';
  String _description = '';
  String _registrationNumber = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _photoUrl = '';
  bool _isOpen = false;
  bool _isLoading = true; // 로딩 상태를 나타내는 변수

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 사용자 로그인 상태가 아니면 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
      );
      return;
    }

    try {
      // Firestore에서 닉네임 가져오기
      final firestoreDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final nickname = firestoreDoc.data()?['nickname'] as String?;

      if (nickname == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자의 닉네임을 찾을 수 없습니다.')),
        );
        return;
      }

      // Firestore에서 닉네임과 일치하는 항목 찾기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('nickname', isEqualTo: nickname)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final businessHours = data['businessHours']?.split(' ~ ');

        setState(() {
          _restaurantId = doc.id;
          _restaurantName = data['restaurantName'] ?? '';
          _location = data['location'] ?? '';
          _description = data['description'] ?? '';
          _registrationNumber = data['registrationNumber'] ?? '';
          _photoUrl = data['photoUrl'] ?? '';
          _isOpen = data['isOpen'] ?? false;
          _isLoading = false; // 데이터 로드 완료
          if (businessHours != null && businessHours.length == 2) {
            _startTime = _parseTime(businessHours[0]);
            _endTime = _parseTime(businessHours[1]);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일치하는 음식점 정보를 찾을 수 없습니다.')),
        );
        setState(() {
          _isLoading = false; // 데이터가 없는 경우에도 로드 완료로 설정
        });
      }
    } catch (e) {
      print('Error loading restaurant data: $e'); // 디버깅을 위한 로그 추가
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
      );
      setState(() {
        _isLoading = false; // 오류 발생 시 로드 완료로 설정
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final format = DateFormat.Hm();
    final dateTime = format.parse(time);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('영업시간을 설정해주세요.')),
        );
        return;
      }

      final startTime = DateTime(
        0,
        1,
        1,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endTime = DateTime(
        0,
        1,
        1,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (endTime.isBefore(startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('영업시간 설정이 올바르지 않습니다.')),
        );
        return;
      }

      // 영업시간을 파싱하여 영업 활성화 여부 결정
      _isOpen = _checkBusinessHours(_startTime!, _endTime!);

      // 데이터를 Firestore에 저장
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .update({
        'description': _description,
        'businessHours':
            '${_startTime!.format(context)} ~ ${_endTime!.format(context)}',
        'photoUrl': _photoUrl,
        'isOpen': _isOpen,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음식점 정보 수정 완료!')),
      );

      // 3초 후에 음식점 정보 수정 페이지로 이동
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushNamed(context, '/homeStaff');
      });
    }
  }

  Future<void> _markAsDeleted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
        );
        return;
      }

      // Firestore에서 해당 음식점 문서를 삭제 상태로 업데이트
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .update({'isDeleted': true});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음식점이 삭제되었습니다.')),
      );

      // homeStaff 페이지로 이동
      Navigator.pushReplacementNamed(context, '/homeStaff');
    } catch (e) {
      print('Error marking restaurant as deleted: $e'); // 디버깅을 위한 로그 추가
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음식점 삭제 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _checkBusinessHours(TimeOfDay startTime, TimeOfDay endTime) {
    final now = TimeOfDay.now();
    final currentTime = DateTime(
      0,
      1,
      1,
      now.hour,
      now.minute,
    );

    final start = DateTime(
      0,
      1,
      1,
      startTime.hour,
      startTime.minute,
    );

    final end = DateTime(
      0,
      1,
      1,
      endTime.hour,
      endTime.minute,
    );

    if (end.isBefore(start)) {
      return currentTime.isAfter(start) || currentTime.isBefore(end);
    } else {
      return currentTime.isAfter(start) && currentTime.isBefore(end);
    }
  }

  bool _isValidKorean(String value) {
    final koreanRegex = RegExp(r'^[가-힣\s]+$');
    return koreanRegex.hasMatch(value);
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('음식점 삭제'),
          content: Text('이 음식점을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsDeleted();
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '음식점 정보 수정',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 인디케이터 표시
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Text(
                        '음식점 정보',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          height: 0.07,
                          letterSpacing: -0.27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                          width: 500,
                          child: Divider(color: Colors.black, thickness: 2.0)),
                      SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 358,
                          height: 201,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: NetworkImage(_photoUrl),
                                fit: BoxFit.fill),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 15),
                      Container(
                        width: 200,
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              )),
                              side: BorderSide(color: Colors.black)),
                          onPressed: () async {
                            final location = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MapPage(previousPage: 'RestaurantEdit'),
                              ),
                            );
                            if (location != null) {
                              setState(() {
                                _location = location;
                              });
                            }
                          },
                          child: Text(
                            '위치 찾기',
                            style: TextStyle(
                              color: Color(0xFF1C1C21),
                              fontSize: 18,
                              fontFamily: 'Epilogue',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '음식점 이름',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        initialValue: _restaurantName,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                        ),
                        readOnly: true, // 음식점 이름은 수정 불가
                      ),
                      SizedBox(height: 20),
                      Text(
                        '위치',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        initialValue: _location,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                        ),
                        readOnly: true, // 위치는 수정 불가
                      ),
                      SizedBox(height: 20),
                      Text(
                        '등록번호',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        initialValue: _registrationNumber,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                        ),
                        readOnly: true, // 등록번호는 수정 불가
                      ),
                      SizedBox(height: 20),
                      Text(
                        '영업시간 (HH:MM ~ HH:MM)',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 167, 198, 255),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        )),
                  ),
                            onPressed: () => _selectTime(context, true),
                            child: Text(_startTime != null
                                ? _startTime!.format(context)
                                : '시작 시간 선택'),
                          ),
                          ElevatedButton(
                            style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 167, 198, 255),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        )),
                  ),
                            onPressed: () => _selectTime(context, false),
                            child: Text(_endTime != null
                                ? _endTime!.format(context)
                                : '종료 시간 선택'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        '설명',
                        style: TextStyle(
                          color: Color(0xFF1C1C21),
                          fontSize: 18,
                          fontFamily: 'Epilogue',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        initialValue: _description,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '음식점에 대한 설명을 입력해주세요';
                          }
                          if (value.length < 5) {
                            return '설명은 최소 5글자 이상 입력해야 합니다';
                          }
                          if (value.length > 100) {
                            return '최대 100글자까지 입력 가능합니다';
                          }
                          if (!_isValidKorean(value)) {
                            return '설명은 한국어로만 입력해주세요';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _description = value!;
                        },
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _showDeleteConfirmationDialog,
                          child: Text(
                            '음식점 삭제',
                            style: TextStyle(
                              color: Color(0xFF1C1C21),
                              fontSize: 18,
                              fontFamily: 'Epilogue',
                              fontWeight: FontWeight.w700,
                              height: 0.07,
                              letterSpacing: -0.27,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 167, 198, 255),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        )),
                  ),
                        onPressed: _submitForm,
                        child: Text('수정'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
