import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'menu_item.dart'; // Import the MenuItem class

class MenuRegOne extends StatefulWidget {
  final Function(MenuItem) onSave;

  MenuRegOne({required this.onSave});

  @override
  _MenuRegOneState createState() => _MenuRegOneState();
}

class _MenuRegOneState extends State<MenuRegOne> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  File? _imageFile;
  String _photoUrl = '';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    super.dispose();
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
      final imageRef = storageRef
          .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(image);
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Image upload error: $e');
      return '';
    }
  }

  bool _isValidKorean(String value) {
    final koreanRegex = RegExp(r'^[가-힣\s]+$');
    return koreanRegex.hasMatch(value);
  }

  bool _isValidOrigin(String value) {
    final originRegex = RegExp(r'^[가-힣\s:,()]+$');
    return originRegex.hasMatch(value);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진을 업로드해주세요.')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final nickname = userDoc.data()?['nickname'] as String?;

          if (nickname != null) {
            final restaurantQuery = await FirebaseFirestore.instance
                .collection('restaurants')
                .where('nickname', isEqualTo: nickname)
                .where('isDeleted', isEqualTo: false)
                .get();

            if (restaurantQuery.docs.isNotEmpty) {
              final restaurantDoc = restaurantQuery.docs.first.reference;

              _photoUrl = await _uploadImage(_imageFile!);
              if (_photoUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('사진 업로드 중 오류가 발생했습니다. 다시 시도해주세요.')),
                );
                return;
              }

              final MenuItem item = MenuItem(
                id: '',
                name: _nameController.text,
                price: int.parse(_priceController.text),
                description: _descriptionController.text,
                origin: _originController.text,
                photoUrl: _photoUrl,
              );

              await restaurantDoc.collection('menus').add(item.toMap());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('메뉴가 등록되었습니다.')),
              );

              widget.onSave(item);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('닉네임과 일치하는 음식점을 찾을 수 없습니다.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('사용자의 닉네임을 찾을 수 없습니다.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('메뉴 등록 중 오류가 발생했습니다. 다시 시도해주세요.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '메뉴 등록',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  '메뉴 정보',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 20,
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
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 358,
                      height: 201,
                      decoration: BoxDecoration(
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!), fit: BoxFit.fill)
                            : DecorationImage(
                                image: AssetImage("assets/images/malatang.png"),
                                fit: BoxFit.fill),
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
                SizedBox(height: 50),
                Text(
                  '메뉴명',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                    height: 0.07,
                    letterSpacing: -0.27,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '메뉴명',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '메뉴명을 입력해주세요';
                    }
                    if (value.length >= 10) {
                      return '10글자 미만으로 입력하세요';
                    }
                    if (!_isValidKorean(value)) {
                      return '메뉴명은 한글로만 입력이 가능합니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                Text(
                  '가격',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                    height: 0.07,
                    letterSpacing: -0.27,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: '가격',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    ),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '가격을 입력해주세요';
                    }
                    final price = int.tryParse(value);
                    if (price == null) {
                      return '유효한 숫자를 입력해주세요';
                    }
                    if (price > 1000000) {
                      return '가격은 백만원 이하여야 합니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                Text(
                  '설명',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                    height: 0.07,
                    letterSpacing: -0.27,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '설명',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '설명을 입력해주세요';
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
                ),
                SizedBox(height: 30),
                Text(
                  '원산지',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                    height: 0.07,
                    letterSpacing: -0.27,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: '원산지',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '원산지를 입력해주세요';
                    }
                    if (value.length > 100) {
                      return '100글자 이하로 입력해주세요';
                    }
                    if (!_isValidOrigin(value)) {
                      return '원산지는 한국어랑 특수문자(: ,)으로만 입력해주세요';
                    }
                    return null;
                  },
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
                  onPressed: _save,
                  child: Text('등록'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
