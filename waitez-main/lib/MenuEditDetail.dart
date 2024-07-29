import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MenuItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final String origin;
  final String photoUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.origin,
    required this.photoUrl,
  });

  factory MenuItem.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    return MenuItem(
      id: document.id,
      name: data['menuName'] ?? '',
      price: data['price'] ?? 0,
      description: data['description'] ?? '',
      origin: data['origin'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }
}

class MenuEditDetail extends StatefulWidget {
  final String menuItemId;

  MenuEditDetail({required this.menuItemId});

  @override
  _MenuEditDetailState createState() => _MenuEditDetailState();
}

class _MenuEditDetailState extends State<MenuEditDetail> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  File? _imageFile;
  String _photoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItem();
  }

  Future<void> _loadMenuItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDocSnapshot = await userDocRef.get();
      final resNum = userDocSnapshot.data()?['resNum'] as String?;

      if (resNum != null) {
        final restaurantQuery = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('registrationNumber', isEqualTo: resNum)
            .where('isDeleted', isEqualTo: false)
            .get();

        if (restaurantQuery.docs.isNotEmpty) {
          final restaurantId = restaurantQuery.docs.first.id;
          final menuDoc = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .collection('menus')
              .doc(widget.menuItemId)
              .get();

          if (menuDoc.exists) {
            final menuItem = MenuItem.fromDocument(menuDoc);
            setState(() {
              _nameController.text = menuItem.name;
              _priceController.text = menuItem.price.toString();
              _descriptionController.text = menuItem.description;
              _originController.text = menuItem.origin;
              _photoUrl = menuItem.photoUrl;
              _isLoading = false;
            });
          }
        }
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
    final originRegex = RegExp(r'^[가-힣\s:,]+$');
    return originRegex.hasMatch(value);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final resNum = userDoc.data()?['resNum'] as String?;

          if (resNum != null) {
            final restaurantQuery = await FirebaseFirestore.instance
                .collection('restaurants')
                .where('registrationNumber', isEqualTo: resNum)
                .where('isDeleted', isEqualTo: false)
                .get();

            if (restaurantQuery.docs.isNotEmpty) {
              final restaurantDoc = restaurantQuery.docs.first.reference;

              if (_imageFile != null) {
                _photoUrl = await _uploadImage(_imageFile!);
                if (_photoUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('사진 업로드 중 오류가 발생했습니다. 다시 시도해주세요.')),
                  );
                  return;
                }
              }

              await restaurantDoc
                  .collection('menus')
                  .doc(widget.menuItemId)
                  .update({
                'price': int.parse(_priceController.text),
                'description': _descriptionController.text,
                'origin': _originController.text,
                'photoUrl': _photoUrl,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('메뉴가 수정되었습니다.')),
              );

              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('음식점을 먼저 등록해주세요.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('사용자의 resNum을 찾을 수 없습니다.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('메뉴 수정 중 오류가 발생했습니다. 다시 시도해주세요.')),
          );
          print('Error: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final resNum = userDoc.data()?['resNum'] as String?;

        if (resNum != null) {
          final restaurantQuery = await FirebaseFirestore.instance
              .collection('restaurants')
              .where('registrationNumber', isEqualTo: resNum)
              .where('isDeleted', isEqualTo: false)
              .get();

          if (restaurantQuery.docs.isNotEmpty) {
            final restaurantDoc = restaurantQuery.docs.first.reference;

            await restaurantDoc
                .collection('menus')
                .doc(widget.menuItemId)
                .delete();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('메뉴가 삭제되었습니다.')),
            );

            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('음식점을 찾을 수 없습니다.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사용자의 resNum을 찾을 수 없습니다.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메뉴 삭제 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
        print('Error: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자가 로그인되어 있지 않습니다.')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('메뉴 삭제'),
          content: Text('이 메뉴를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _delete();
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('메뉴 수정'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '메뉴 수정',
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
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 358,
                      height: 201,
                      decoration: BoxDecoration(
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.fill,
                              )
                            : DecorationImage(
                                image: NetworkImage(_photoUrl),
                                fit: BoxFit.fill,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageFile == null
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.transparent,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  enabled: false,
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
                    final intPrice = int.tryParse(value);
                    if (intPrice == null) {
                      return '유효한 숫자를 입력해주세요';
                    }
                    if (intPrice > 1000000) {
                      return '가격은 백만원 이하이어야 합니다';
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '설명을 입력해주세요';
                    }
                    if (!_isValidKorean(value)) {
                      return '설명은 한국어로만 입력해주세요';
                    }
                    if (value.length < 5) {
                      return '설명은 최소 5글자 이상 입력해야 합니다';
                    }
                    if (value.length > 100) {
                      return '최대 100글자까지 입력 가능합니다';
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '원산지를 입력해주세요';
                    }
                    if (!_isValidOrigin(value)) {
                      return '원산지는 한국어 및 특수문자(: ,)만 입력해주세요';
                    }
                    if (value.length > 100) {
                      return '100글자 이하로 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showDeleteConfirmationDialog,
                    child: Text(
                      '메뉴 삭제',
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
                  onPressed: _save,
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
