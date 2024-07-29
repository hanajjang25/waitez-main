import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'googleMap.dart';

class regRestaurant extends StatefulWidget {
  const regRestaurant({super.key});

  @override
  _RegRestaurantState createState() => _RegRestaurantState();
}

class _RegRestaurantState extends State<regRestaurant> {
  final _formKey = GlobalKey<FormState>();
  String _restaurantName = '';
  String _location = '';
  String _description = '';
  String _registrationNumber = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _photoUrl = '';
  String _nickname = '';
  bool _isOpen = false;
  File? _imageFile;
  String _averageWaitTime = '';
  String? _userRegistrationNumber;

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('restaurants');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          var data = userDoc.data() as Map<String, dynamic>;
          _nickname = data['nickname'] ?? '';
          _location = data.containsKey('location') ? data['location'] : '';
          _userRegistrationNumber = data['resNum'] ?? '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
          'restaurant_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(image);
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Image upload error: $e');
      return '';
    }
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

      if (_imageFile != null) {
        _photoUrl = await _uploadImage(_imageFile!);
        if (_photoUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사진 업로드 중 오류가 발생했습니다. 다시 시도해주세요.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진을 업로드해주세요.')),
        );
        return;
      }

      if (_userRegistrationNumber != _registrationNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록번호가 일치하지 않습니다.')),
        );
        return;
      }

      try {
        // 중복된 음식점 이름이 있는지 확인
        final QuerySnapshot nameSnapshot = await _collectionRef
            .where('restaurantName', isEqualTo: _restaurantName)
            .get();
        if (nameSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미 등록된 음식점 이름입니다.')),
          );
          return;
        }

        // 중복된 등록번호가 있는지 확인
        final QuerySnapshot numberSnapshot = await _collectionRef
            .where('registrationNumber', isEqualTo: _registrationNumber)
            .get();
        if (numberSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미 등록되어 있는 음식점입니다.')),
          );
          return;
        }

        // 영업시간을 파싱하여 영업 활성화 여부 결정
        _isOpen = _checkBusinessHours(_startTime!, _endTime!);

        // 데이터를 Cloud Firestore에 저장
        await _collectionRef.add({
          'restaurantName': _restaurantName,
          'location': _location,
          'description': _description,
          'registrationNumber': _registrationNumber,
          'businessHours':
              '${_startTime!.format(context)} ~ ${_endTime!.format(context)}',
          'photoUrl': _photoUrl,
          'isOpen': _isOpen,
          'nickname': _nickname,
          'isDeleted': false,
          'averageWaitTime':
              int.parse(_averageWaitTime), // 저장된 대기시간을 int로 변환하여 저장
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음식점 등록 완료!')),
        );

        // 3초 후에 직원 home 페이지로 이동
        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushNamed(context, '/homeStaff');
        });
      } catch (e) {
        print('Error adding restaurant: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음식점 등록 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
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

  bool _validateRestaurantName(String value) {
    final nameRegExp = RegExp(r'^[가-힣]+$');
    if (!nameRegExp.hasMatch(value)) {
      return false;
    }
    if (value.length > 15) {
      return false;
    }
    return true;
  }

  bool _validateDescription(String value) {
    final descriptionRegExp = RegExp(r'^[가-힣\s]+$');
    if (!descriptionRegExp.hasMatch(value)) {
      return false;
    }
    if (value.length > 100) {
      return false;
    }
    return true;
  }

  void _updateLocation(String location) {
    setState(() {
      _location = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '음식점 등록',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    fontSize: 20,
                    fontFamily: 'Epilogue',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: Colors.black, thickness: 2.0),
                SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 358,
                      height: 201.38,
                      decoration: BoxDecoration(
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.fill,
                              )
                            : DecorationImage(
                                image:
                                    AssetImage("assets/images/imageUpload.png"),
                                fit: BoxFit.fill,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageFile == null
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 50,
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  width: 200,
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        )),
                        side: BorderSide(color: Colors.black)),
                    onPressed: () async {
                      final location = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MapPage(previousPage: 'RestaurantReg'),
                        ),
                      );
                      if (location != null) {
                        _updateLocation(location);
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
                if (_location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '위치: $_location',
                      style: TextStyle(
                        color: Color(0xFF1C1C21),
                        fontSize: 16,
                        fontFamily: 'Epilogue',
                      ),
                    ),
                  ),
                
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '상호명',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '음식점 이름을 입력해주세요';
                    }
                    if (!_validateRestaurantName(value)) {
                      if (!RegExp(r'^[가-힣]+$').hasMatch(value)) {
                        return '상호명은 한글로만 가능합니다';
                      }
                      if (value.length > 15) {
                        return '15글자 이하로 입력해주세요.';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _restaurantName = value!;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '1팀당 평균 대기시간 (분)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '평균 대기시간을 입력해주세요';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return '숫자로만 입력해주세요';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _averageWaitTime = value!;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '설명',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5))
                      )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '음식점에 대한 설명을 입력해주세요';
                    }
                    if (!_validateDescription(value)) {
                      if (!RegExp(r'^[가-힣\s]+$').hasMatch(value)) {
                        return '설명은 한글로만 가능합니다';
                      }
                      if (value.length > 100) {
                        return '최대 100글자까지 입력 가능합니다';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value!;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '등록번호',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '등록번호를 입력해주세요';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return '등록번호는 숫자만 입력 가능합니다';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _registrationNumber = value!;
                  },
                ),
                SizedBox(height: 20),
                Text(
                  '영업시간 (HH:MM ~ HH:MM)',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                  ),
                ),
                SizedBox(height: 10),
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
                
                SizedBox(height: 40),
                ElevatedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 167, 198, 255),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    )),
                  ),
                  onPressed: _submitForm,
                  child: Text('등록하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
