import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MemberPostDetail.dart';

class UserPostsPage extends StatefulWidget {
  @override
  _UserPostsPageState createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? nickname;

  Future<void> fetchNickname() async {
    String? userEmail = _auth.currentUser?.email;

    if (userEmail != null) {
      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          nickname = userSnapshot.docs.first['nickname'];
        });
      }
    }
  }

  Future<List<Map<String, String>>> fetchUserPosts() async {
    if (nickname != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('community')
          .where('author', isEqualTo: nickname)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data.map((key, value) {
          if (value is Timestamp) {
            return MapEntry(
                key, (value as Timestamp).toDate().toIso8601String());
          }
          return MapEntry(key, value.toString());
        });
      }).toList();
    } else {
      return [];
    }
  }

  void navigateToPostDetail(Map<String, String> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          post: post,
          onPostDeleted: () {
            setState(() {
              fetchUserPosts(); // 글 삭제 후 데이터 다시 가져오기
            });
          },
          onPostUpdated: (updatedPost) {
            setState(() {
              fetchUserPosts(); // 글 수정 후 데이터 다시 가져오기
            });
          },
        ),
      ),
    );
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    fetchNickname();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 30),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '내가 작성한 글',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.27,
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
                width: 500,
                child: Divider(color: Colors.black, thickness: 1.0)),
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: fetchUserPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No posts found'));
                  } else {
                    final posts = snapshot.data!;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          title: Text(post['title']!,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          subtitle: Text(formatTimestamp(post['timestamp']!),
                              style: TextStyle(color: Colors.grey)),
                          trailing: Text(post['author']!,
                              style: TextStyle(color: Colors.grey)),
                          onTap: () => navigateToPostDetail(post),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
