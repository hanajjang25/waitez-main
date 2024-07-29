import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:waitez/reservationBottom.dart';
import 'UserReservation.dart'; // UserReservation 클래스를 임포트
import 'dart:async'; // Timer를 사용하기 위해 임포트
import 'reservationBottom.dart';
import 'package:intl/intl.dart';

class RestaurantInfo extends StatefulWidget {
  final String restaurantId;

  RestaurantInfo({required this.restaurantId, Key? key}) : super(key: key);

  @override
  _RestaurantInfoState createState() => _RestaurantInfoState();
}

class _RestaurantInfoState extends State<RestaurantInfo> {
  bool isFavorite = false;
  bool isOpen = false;
  bool isWithinBusinessHours = false; // Added
  Map<String, dynamic>? restaurantData;
  List<Map<String, dynamic>> menuItems = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
    _fetchMenuItems();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkBusinessHours();
    }); // Added Timer to call _checkBusinessHours periodically
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();
      if (doc.exists) {
        setState(() {
          restaurantData = doc.data() as Map<String, dynamic>?;
          _checkBusinessHours(); // Check business hours after fetching data
        });
      } else {
        print('Restaurant not found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restaurant not found')),
        );
      }
    } catch (e) {
      print('Error fetching restaurant details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> _fetchMenuItems() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menus')
          .get();

      setState(() {
        menuItems = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error fetching menu items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching menu items: $e')),
      );
    }
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void navigateToDetails(Map<String, dynamic> menuItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuDetailsPage(menuItem: menuItem),
      ),
    );
  }

  Future<void> _saveReservation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      String nickname = '';
      String phone = '';

      // 사용자 정보를 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final nonMemberQuery = await FirebaseFirestore.instance
          .collection('non_members')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (userDoc.exists) {
        nickname = (userDoc.data() as Map<String, dynamic>)['nickname'] ?? '';
        phone = (userDoc.data() as Map<String, dynamic>)['phoneNum'] ?? '';
      } else if (nonMemberQuery.docs.isNotEmpty) {
        final nonMemberData =
            nonMemberQuery.docs.first.data() as Map<String, dynamic>;
        nickname = nonMemberData['nickname'] ?? '';
        phone = nonMemberData['phoneNum'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'nickname': nickname,
        'phone': phone,
        'restaurantId': widget.restaurantId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation saved successfully')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Reservation()),
      ); // 예약하기 버튼 클릭 시 UserReservation 화면으로 이동
    } catch (e) {
      print('Error saving reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reservation: $e')),
      );
    }
  }

  // Added method to check business hours
  void _checkBusinessHours() {
    if (restaurantData == null) return;

    String businessHours = restaurantData!['businessHours'] ?? '';
    if (businessHours.isEmpty) return;

    List<String> hours = businessHours.split(' ~');
    if (hours.length != 2) return;

    try {
      DateTime now = DateTime.now();
      DateFormat format = DateFormat('hh:mm a');
      DateTime openTime = format.parse(hours[0].trim());
      DateTime closeTime = format.parse(hours[1].trim());

      openTime = DateTime(
          now.year, now.month, now.day, openTime.hour, openTime.minute);
      closeTime = DateTime(
          now.year, now.month, now.day, closeTime.hour, closeTime.minute);

      if (now.isAfter(openTime) && now.isBefore(closeTime)) {
        setState(() {
          isWithinBusinessHours = true;
        });
      } else {
        setState(() {
          isWithinBusinessHours = false;
        });
      }
    } catch (e) {
      print('Error parsing business hours: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing business hours: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (restaurantData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          restaurantData!['restaurantName'] ?? 'Unknown',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Center(
              child: Container(
                width: 358,
                height: 201,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(restaurantData!['photoUrl'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              restaurantData!['restaurantName'] ?? 'Unknown',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 20,
                fontFamily: 'Epilogue',
                fontWeight: FontWeight.w700,
                height: 0.07,
                letterSpacing: -0.27,
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              child: Row(
                children: [
                  Text(
                    '주소',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 18,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.w700,
                      height: 0.07,
                      letterSpacing: -0.27,
                    ),
                  ),
                  SizedBox(width: 50),
                  Expanded(
                    child: Text(
                      restaurantData!['location'] ?? 'Unknown',
                      style: TextStyle(fontSize: 15),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              child: Row(
                children: [
                  Text(
                    '영업시간',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 18,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.w700,
                      height: 0.07,
                      letterSpacing: -0.27,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    restaurantData!['businessHours'] ?? 'Unknown',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              child: Row(
                children: [
                  Text(
                    '설명',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 18,
                      fontFamily: 'Epilogue',
                      fontWeight: FontWeight.w700,
                      height: 0.07,
                      letterSpacing: -0.27,
                    ),
                  ),
                  SizedBox(width: 50),
                  Expanded(
                    child: Text(
                      restaurantData!['description'] ?? 'Unknown',
                      style: TextStyle(fontSize: 15),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'MENU',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final menuItem = menuItems[index];
                  return ListTile(
                    title: Text(menuItem['menuName'] ?? 'Unknown'),
                    subtitle: Text('${menuItem['price'] ?? '0'}원'),
                    onTap: () {},
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isWithinBusinessHours
                      ? _saveReservation
                      : null, // 예약하기 버튼 클릭 시 예약 정보 저장 및 화면 전환
                  child: Text('예약하기'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        isWithinBusinessHours ? Colors.blue[500] : Colors.grey),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    minimumSize: MaterialStateProperty.all(Size(200, 50)),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 10)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: reservationBottom(),
    );
  }
}

class MenuDetailsPage extends StatelessWidget {
  final Map<String, dynamic> menuItem;

  MenuDetailsPage({required this.menuItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          menuItem['menuName'] ?? 'Unknown',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            height: 0.07,
            letterSpacing: -0.27,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'MENU',
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
                    image: NetworkImage(menuItem['photoUrl'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              menuItem['menuName'] ?? 'Unknown',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 24,
                fontFamily: 'Epilogue',
                height: 0.07,
                letterSpacing: -0.27,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 50),
            Text(
              '가격: ${menuItem['price'] ?? '0'}원',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 20,
                fontFamily: 'Epilogue',
                height: 0.07,
                letterSpacing: -0.27,
              ),
            ),
            SizedBox(height: 50),
            Text(
              menuItem['description'] ?? '상세 설명이 없습니다.',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
                height: 0.07,
                letterSpacing: -0.27,
              ),
            ),
            SizedBox(height: 100),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('장바구니에 추가되었습니다.')),
                  );
                },
                child: Text('장바구니에 추가'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: reservationBottom(),
    );
  }
}
