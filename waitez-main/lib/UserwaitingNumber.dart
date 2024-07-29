import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'UserWaitingDetail.dart';
import 'UserBottom.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification.dart'; // Import the notification helper

class waitingNumber extends StatefulWidget {
  @override
  _WaitingNumberState createState() => _WaitingNumberState();
}

class _WaitingNumberState extends State<waitingNumber> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String _nickname = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserNickname();
    _configureFCM();
  }

  Future<void> _configureFCM() async {
    await _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(notification.title ?? 'Notification'),
            content: Text(notification.body ?? 'No message body'),
          ),
        );
      }
    });
  }

  Future<void> _fetchUserNickname() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        if (user.isAnonymous) {
          QuerySnapshot nonMemberSnapshot = await _firestore
              .collection('non_members')
              .where('uid', isEqualTo: user.uid)
              .get();
          if (nonMemberSnapshot.docs.isNotEmpty) {
            setState(() {
              _nickname = nonMemberSnapshot.docs.first['nickname'] ?? '';
            });
          } else {
            print('No matching document for anonymous user UID: ${user.uid}');
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          DocumentSnapshot userSnapshot =
              await _firestore.collection('users').doc(user.uid).get();
          if (userSnapshot.exists) {
            setState(() {
              _nickname = userSnapshot['nickname'] ?? '';
            });
          } else {
            print('User document does not exist');
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('No user is signed in');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _fetchRestaurantDetails(
      String restaurantId) async {
    try {
      DocumentSnapshot restaurantSnapshot =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      if (restaurantSnapshot.exists) {
        return {
          'name': restaurantSnapshot['restaurantName'] ?? 'Unknown',
          'location': restaurantSnapshot['location'] ?? 'Unknown',
          'photoUrl': restaurantSnapshot['photoUrl'] ?? '',
        };
      } else {
        return {'name': 'Unknown', 'location': 'Unknown', 'photoUrl': ''};
      }
    } catch (e) {
      print('Error fetching restaurant details: $e');
      return {'name': 'Unknown', 'location': 'Unknown', 'photoUrl': ''};
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchReservationsStream() {
    return _firestore
        .collection('reservations')
        .where('nickname', isEqualTo: _nickname)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> reservations = [];
      int maxWaitingNumber = 0;

      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var timestamp = (data['timestamp'] as Timestamp).toDate();
        if (timestamp.isAfter(todayStart) && timestamp.isBefore(todayEnd)) {
          var restaurantId = data['restaurantId'] ?? '';
          var reservation = {
            'reservationId': doc.id,
            'nickname': data['nickname'] ?? '',
            'restaurantId': restaurantId,
            'numberOfPeople': data['numberOfPeople'] ?? 0,
            'type': data['type'] == 1 ? '매장' : '포장',
            'timestamp': timestamp,
            'waitingNumber': (data['waitingNumber'] ?? 0) as int,
          };
          reservations.add(reservation);
          if (reservation['waitingNumber'] > maxWaitingNumber) {
            maxWaitingNumber = reservation['waitingNumber'];
          }
        }
      }

      // Sort reservations by timestamp
      reservations.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

      // Assign waiting numbers based on sorted order
      for (var reservation in reservations) {
        if (reservation['waitingNumber'] == 0) {
          maxWaitingNumber++;
          reservation['waitingNumber'] = maxWaitingNumber;
          _firestore
              .collection('reservations')
              .doc(reservation['reservationId'])
              .update({'waitingNumber': maxWaitingNumber});
        }
      }

      // Check if any waitingNumber is 1 and show notification
      for (var reservation in reservations) {
        if (reservation['waitingNumber'] == 1) {
          FlutterLocalNotification.showNotification(
            '대기순번 1번 안내',
            '음식점에 방문할 준비를 해주세요.',
          );
        }
      }

      return reservations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 170),
              child: Text(
                '대기순번',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchReservationsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> storeReservations =
                      snapshot.data!.where((r) => r['type'] == '매장').toList();
                  List<Map<String, dynamic>> takeoutReservations =
                      snapshot.data!.where((r) => r['type'] == '포장').toList();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('매장'),
                        ..._buildQueueCards(context, storeReservations),
                        SizedBox(height: 20),
                        _buildSectionTitle('포장'),
                        ..._buildQueueCards(context, takeoutReservations),
                      ],
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: menuButtom(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
          ),
        ),
        Divider(color: Colors.black, thickness: 2.0),
      ],
    );
  }

  List<Widget> _buildQueueCards(
      BuildContext context, List<Map<String, dynamic>> reservations) {
    if (reservations.isEmpty) {
      return [Text('No reservations found.')];
    }
    return reservations.map((reservation) {
      return FutureBuilder<Map<String, String>>(
        future: _fetchRestaurantDetails(reservation['restaurantId']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var restaurantDetails = snapshot.data!;
          return _buildQueueCard(
            context,
            reservation['nickname'],
            restaurantDetails['name']!,
            restaurantDetails['location']!,
            restaurantDetails['photoUrl']!,
            reservation['numberOfPeople'],
            reservation['type'],
            reservation['timestamp'],
            reservation['reservationId'], // Pass the reservationId to the card
            reservation['waitingNumber'], // Pass the waitingNumber to the card
          );
        },
      );
    }).toList();
  }

  Widget _buildQueueCard(
    BuildContext context,
    String nickname,
    String restaurantName,
    String restaurantLocation,
    String restaurantPhotoUrl, // Add photo URL parameter
    int numberOfPeople,
    String type,
    DateTime timestamp,
    String reservationId, // Add reservationId parameter
    int waitingNumber, // Add waitingNumber parameter
  ) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => waitingDetail(
              restaurantName: restaurantName,
              queueNumber: waitingNumber,
              reservationId:
                  reservationId, // Pass reservationId to WaitingDetail
            ),
          ),
        );
      },
      child: Card(
        color: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                child: Center(
                  child: Text(
                    '$waitingNumber',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 20,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.0),
                  Text(
                    '$restaurantName',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 14,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 250, // Set the desired width
                    child: Wrap(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "주소: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: restaurantLocation,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (numberOfPeople != null)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "인원수:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' $numberOfPeople'),
                        ],
                      ),
                    ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "날짜:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' $formattedDate'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
