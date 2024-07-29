import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'StaffBottom.dart';
import 'notification.dart';

class WaitlistEntry {
  final String id;
  final String name;
  final int people;
  final String phoneNum;
  final String? altPhoneNum;
  final DateTime timeStamp;
  final String type;

  WaitlistEntry({
    required this.id,
    required this.name,
    required this.people,
    required this.phoneNum,
    this.altPhoneNum,
    required this.timeStamp,
    required this.type,
  });
}

class homeStaff extends StatefulWidget {
  @override
  _homeStaffState createState() => _homeStaffState();
}

class _homeStaffState extends State<homeStaff> {
  List<WaitlistEntry> storeWaitlist = [];
  List<WaitlistEntry> takeoutWaitlist = [];
  String? restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantId();
  }

  Future<void> _fetchRestaurantId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final nickname = userDoc.data()?['nickname'];

          if (nickname != null) {
            final restaurantQuery = await FirebaseFirestore.instance
                .collection('restaurants')
                .where('nickname', isEqualTo: nickname)
                .get();

            if (restaurantQuery.docs.isNotEmpty) {
              setState(() {
                restaurantId = restaurantQuery.docs.first.id;
              });
              _fetchConfirmedReservations();
            } else {
              print('Restaurant not found for this user.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Restaurant not found for this user.')),
              );
            }
          }
        } else {
          print('User document does not exist.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User document does not exist.')),
          );
        }
      } else {
        print('User is not logged in.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not logged in.')),
        );
      }
    } catch (e) {
      print('Error fetching restaurant ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching restaurant ID: $e')),
      );
    }
  }

  Future<void> _fetchConfirmedReservations() async {
    if (restaurantId != null) {
      try {
        final reservationQuery = await FirebaseFirestore.instance
            .collection('reservations')
            .where('restaurantId', isEqualTo: restaurantId)
            .where('status', isEqualTo: 'confirmed')
            .get();

        final today = DateTime.now().toLocal();
        final formattedToday = DateFormat('yyyy-MM-dd').format(today);

        List<WaitlistEntry> storeList = [];
        List<WaitlistEntry> takeoutList = [];
        List<Map<String, dynamic>> reservations = [];

        reservationQuery.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp =
              (data['timestamp'] as Timestamp?)?.toDate().toLocal();
          if (timestamp != null) {
            final formattedTimestamp =
                DateFormat('yyyy-MM-dd').format(timestamp);

            if (formattedTimestamp == formattedToday) {
              final type = data['type'] == 1 ? '매장' : '포장';
              final entry = WaitlistEntry(
                id: doc.id,
                name: data['nickname']?.toString() ?? 'Unknown',
                people: data['numberOfPeople'] ?? 0,
                phoneNum: data['phone']?.toString() ?? 'Unknown',
                altPhoneNum: data['altPhoneNum']?.toString(),
                timeStamp: timestamp,
                type: type,
              );
              data['docId'] = doc.id;
              reservations.add(data);
              if (type == '매장') {
                storeList.add(entry);
              } else {
                takeoutList.add(entry);
              }
            }
          }
        });

        // Sort by timestamp, newest first
        storeList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        takeoutList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

        setState(() {
          storeWaitlist = storeList;
          takeoutWaitlist = takeoutList;
        });

        // Assign waiting numbers
        reservations.sort((a, b) => (b['timestamp'] as Timestamp)
            .compareTo(a['timestamp'] as Timestamp));

        int queueNumber = 1;
        for (var data in reservations) {
          data['waitingNumber'] = queueNumber++;
          FirebaseFirestore.instance
              .collection('reservations')
              .doc(data['docId'])
              .update({'waitingNumber': data['waitingNumber']});
        }
      } catch (e) {
        print('Error fetching confirmed reservations: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching confirmed reservations: $e')),
        );
      }
    }
  }

  Future<void> _cancelReservation(String id, List<String> phoneNumbers) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .update({'status': 'cancelled'});
      _fetchConfirmedReservations();
      NotificationService.sendSmsNotification(
          '매장 사정으로 인해 예약취소되었습니다.', phoneNumbers);
    } catch (e) {
      print('Error cancelling reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling reservation: $e')),
      );
    }
  }

  Future<void> _confirmArrival(String id, List<String> phoneNumbers) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .update({'status': 'arrived'});

      final waitlistSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      List<Map<String, dynamic>> waitlist = [];
      for (var doc in waitlistSnapshot.docs) {
        final data = doc.data();
        data['docId'] = doc.id;
        waitlist.add(data);
      }

      waitlist.sort((a, b) =>
          (a['waitingNumber'] ?? 0).compareTo(b['waitingNumber'] ?? 0));

      for (var i = 0; i < waitlist.length; i++) {
        if (waitlist[i]['waitingNumber'] != null &&
            waitlist[i]['waitingNumber'] > 1) {
          await FirebaseFirestore.instance
              .collection('reservations')
              .doc(waitlist[i]['docId'])
              .update({'waitingNumber': waitlist[i]['waitingNumber'] - 1});
        } else if (waitlist[i]['waitingNumber'] == 1) {
          await FirebaseFirestore.instance
              .collection('reservations')
              .doc(waitlist[i]['docId'])
              .update({'waitingNumber': 0});

          List<String> customerPhoneNumbers = [];
          if (waitlist[i]['phone'] != null) {
            customerPhoneNumbers.add(waitlist[i]['phone']);
          }
          if (waitlist[i]['altPhoneNum'] != null) {
            customerPhoneNumbers.add(waitlist[i]['altPhoneNum']);
          }
          NotificationService.sendSmsNotification(
              '입장할 준비해주세요.', customerPhoneNumbers);
        }
      }

      _fetchConfirmedReservations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arrival confirmed successfully.')),
      );
      NotificationService.sendSmsNotification(
          '도착확인되었습니다. 조리를 시작합니다.', phoneNumbers);
    } catch (e) {
      print('Error confirming arrival: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming arrival: $e')),
      );
    }
  }

  Future<void> _markAsNoShow(String nickname, List<String> phoneNumbers) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        final noShowCount = userDoc.data()['noShowCount'] ?? 0;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .update({'noShowCount': noShowCount + 1});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No-show count updated successfully.')),
        );
      }

      NotificationService.sendSmsNotification('불참처리 되었습니다.', phoneNumbers);
    } catch (e) {
      print('Error updating no-show count: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating no-show count: $e')),
      );
    }
  }

  Future<void> _callCustomer(String id, List<String> phoneNumbers) async {
    try {
      NotificationService.sendSmsNotification(
          '매장이 비었습니다. 들어와주세요.', phoneNumbers);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매장 호출 문자가 발송되었습니다.')),
      );
    } catch (e) {
      print('Error calling customer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calling customer: $e')),
      );
    }
  }

  Widget buildWaitlist(List<WaitlistEntry> waitlist) {
    if (waitlist.isEmpty) {
      return Center(
        child: Text('현재 예약되어 있는 것이 존재하지 않습니다.'),
      );
    }
    return Column(
      children: waitlist.map((waitP) {
        List<String> phoneNumbers = [];
        if (waitP.phoneNum.isNotEmpty) {
          phoneNumbers.add(waitP.phoneNum);
        }
        if (waitP.altPhoneNum != null && waitP.altPhoneNum!.isNotEmpty) {
          phoneNumbers.add(waitP.altPhoneNum!);
        }
        final formattedTimeStamp =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(waitP.timeStamp);
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        waitP.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('날짜: $formattedTimeStamp'),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('타입: ${waitP.type}'),
                      SizedBox(width: 50),
                      Text('인원수: ${waitP.people}'),
                    ],
                  ),
                  Text('전화번호: ${waitP.phoneNum}'),
                  if (waitP.altPhoneNum != null &&
                      waitP.altPhoneNum!.isNotEmpty)
                    Text('보조 전화번호: ${waitP.altPhoneNum}'),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          )),
                        ),
                        onPressed: () =>
                            _cancelReservation(waitP.id, phoneNumbers),
                        child: Text(
                          '예약취소',
                          style: TextStyle(
                            color: Color(0xFF1C1C21),
                            fontSize: 15,
                            fontFamily: 'Epilogue',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          )),
                        ),
                        onPressed: () {
                          _confirmArrival(waitP.id, phoneNumbers);
                        },
                        child: Text(
                          '도착확인',
                          style: TextStyle(
                            color: Color(0xFF1C1C21),
                            fontSize: 15,
                            fontFamily: 'Epilogue',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          )),
                        ),
                        onPressed: () async {
                          await _markAsNoShow(waitP.name, phoneNumbers);
                        },
                        child: Text(
                          '불참',
                          style: TextStyle(
                            color: Color(0xFF1C1C21),
                            fontSize: 15,
                            fontFamily: 'Epilogue',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          )),
                        ),
                        onPressed: () {
                          _callCustomer(waitP.id, phoneNumbers);
                        },
                        child: Text(
                          '매장 호출',
                          style: TextStyle(
                            color: Color(0xFF1C1C21),
                            fontSize: 15,
                            fontFamily: 'Epilogue',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'waitez',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
            height: 0.07,
            letterSpacing: -0.27,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchConfirmedReservations,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '매장',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Divider(color: Colors.black, thickness: 2.0),
              Container(
                width: screenWidth,
                child: storeWaitlist.isEmpty
                    ? Center(child: Text('현재 예약되어 있는 것이 존재하지 않습니다.'))
                    : buildWaitlist(storeWaitlist),
              ),
              Text(
                '포장',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Divider(color: Colors.black, thickness: 2.0),
              Container(
                width: screenWidth,
                child: takeoutWaitlist.isEmpty
                    ? Center(child: Text('현재 예약되어 있는 것이 존재하지 않습니다.'))
                    : buildWaitlist(takeoutWaitlist),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: staffBottom(),
    );
  }
}
