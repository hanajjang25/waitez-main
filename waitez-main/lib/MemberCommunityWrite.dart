import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritePostPage extends StatefulWidget {
  @override
  _WritePostPageState createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isTitleEmpty = false;
  bool _isContentEmpty = false;
  String? _titleError;
  String? _contentError;

  bool _isValidKorean(String value) {
    final koreanRegex = RegExp(r'^[가-힣\s]+$');
    return koreanRegex.hasMatch(value);
  }

  Future<void> submitPost() async {
    final title = _titleController.text;
    final content = _contentController.text;

    setState(() {
      _isTitleEmpty = title.isEmpty;
      _isContentEmpty = content.isEmpty || content.length < 5;
      _titleError = null;
      _contentError = null;

      if (title.isEmpty) {
        _titleError = '제목을 입력하세요';
      } else if (!_isValidKorean(title)) {
        _titleError = '한글로 작성해주세요';
      } else if (title.length > 10) {
        _titleError = '10자 이하로 입력해주세요';
      }

      if (content.isEmpty) {
        _contentError = '내용을 입력하세요';
      } else if (content.length < 5) {
        _contentError = '내용은 최소 5자 이상이어야 합니다';
      } else if (content.length > 500) {
        _contentError = '내용은 500자까지 작성 가능합니다';
      } else if (!_isValidKorean(content)) {
        _contentError = '한글로 작성해주세요';
      }
    });

    if (_titleError == null && _contentError == null) {
      if (currentUser != null) {
        try {
          // Firestore에서 현재 사용자 닉네임 가져오기
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final nickname = userDoc.get('nickname');

            // Firestore에 게시물 저장
            await FirebaseFirestore.instance.collection('community').add({
              'title': title,
              'content': content,
              'author': nickname,
              'email': currentUser!.email,
              'date': DateTime.now().toIso8601String().substring(0, 10),
              'timestamp': DateTime.now(),
            });

            Navigator.pop(context);
          } else {
            _showErrorDialog('글쓰기 실패하였습니다');
          }
        } catch (e) {
          _showErrorDialog('글쓰기 실패하였습니다');
        }
      } else {
        _showErrorDialog('글쓰기 실패하였습니다');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true; // Allow back navigation without any additional actions
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('글 작성'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 30),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '글 작성',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 20,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.w700,
                      height: 0.07,
                      letterSpacing: -0.27,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Container(
                    width: 500,
                    child: Divider(color: Colors.black, thickness: 2.0)),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('제목', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16),),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    errorText: _titleError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))
                    )
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('내용', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16),),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: '내용',
                    errorText: _contentError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: submitPost,
                  child: Text('등록'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: !_isTitleEmpty && !_isContentEmpty
                        ? Color(0xFF6495ED)
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
