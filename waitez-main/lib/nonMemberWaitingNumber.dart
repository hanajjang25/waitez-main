import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'UserWaitingDetail.dart';
import 'UserBottom.dart';
import 'NonMemberBottom.dart';

class nonMemberWaitingNumber extends StatefulWidget {
  @override
  _WaitingNumberState createState() => _WaitingNumberState();
}

class _WaitingNumberState extends State<nonMemberWaitingNumber> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _nickname = '';
  List<Map<String, dynamic>> _storeReservations = [];
  List<Map<String, dynamic>> _takeoutReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserNickname();
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
        print('Nickname: $_nickname'); // 디버깅 메시지 추가
        _fetchConfirmedReservations();
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

  Future<void> _fetchConfirmedReservations() async {
    try {
      QuerySnapshot reservationSnapshot = await _firestore
          .collection('reservations')
          .where('nickname', isEqualTo: _nickname)
          .where('status', isEqualTo: 'confirmed')
          .get();

      List<Map<String, dynamic>> storeReservations = [];
      List<Map<String, dynamic>> takeoutReservations = [];

      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (var doc in reservationSnapshot.docs) {
        var timestamp = (doc['timestamp'] as Timestamp).toDate();
        if (timestamp.isAfter(todayStart) && timestamp.isBefore(todayEnd)) {
          print('Document Data: ${doc.data()}'); // 디버깅 메시지 추가
          var restaurantId = doc['restaurantId'] ?? '';
          DocumentSnapshot restaurantSnapshot = await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();

          var reservation = {
            'reservationId': doc.id, // Add the reservation ID here
            'nickname': doc['nickname'] ?? '',
            'restaurantName': restaurantSnapshot.exists
                ? restaurantSnapshot['restaurantName'] ?? ''
                : 'Unknown',
            'numberOfPeople': doc['numberOfPeople'] ?? null,
            'type': doc['type'] == 1 ? '매장' : '포장',
            'timestamp': timestamp,
          };
          if (reservation['type'] == '매장') {
            storeReservations.add(reservation);
          } else if (reservation['type'] == '포장') {
            takeoutReservations.add(reservation);
          }
        }
      }

      setState(() {
        _storeReservations = storeReservations;
        _takeoutReservations = takeoutReservations;
        _isLoading = false;
      });

      print('Store Reservations: $_storeReservations'); // 디버깅 메시지 추가
      print('Takeout Reservations: $_takeoutReservations'); // 디버깅 메시지 추가
    } catch (e) {
      print('Error fetching reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('매장'),
                    ..._buildQueueCards(context, _storeReservations),
                    SizedBox(height: 20),
                    _buildSectionTitle('포장'),
                    ..._buildQueueCards(context, _takeoutReservations),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: nonMemberBottom(),
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
      return _buildQueueCard(
        context,
        reservation['nickname'],
        reservation['restaurantName'],
        reservation['numberOfPeople'],
        reservation['type'],
        reservation['timestamp'],
        reservation['reservationId'], // Pass the reservationId to the card
      );
    }).toList();
  }

  Widget _buildQueueCard(
    BuildContext context,
    String nickname,
    String restaurantName,
    int? numberOfPeople,
    String type,
    DateTime timestamp,
    String reservationId, // Add reservationId parameter
  ) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => waitingDetail(
              restaurantName: restaurantName,
              queueNumber: 2,
              reservationId:
                  reservationId, // Pass reservationId to waitingDetail
            ),
          ),
        );
      },
      child: Card(
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '13',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 50),
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
                  if (numberOfPeople != null)
                    Text(
                      '인원수: $numberOfPeople',
                      style: TextStyle(
                        color: Color(0xFF1C1C21),
                        fontSize: 14,
                        fontFamily: 'Epilogue',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    '날짜: $formattedDate',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 14,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.bold,
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
