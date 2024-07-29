import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'UserBottom.dart';
import 'UserCart.dart'; // Import the Cart page
import 'notification.dart';

class waitingDetail extends StatefulWidget {
  final String restaurantName;
  final int queueNumber;
  final String reservationId; // Add reservationId as a parameter

  waitingDetail({
    required this.restaurantName,
    required this.queueNumber,
    required this.reservationId, // Initialize reservationId
  });

  @override
  _waitingDetailState createState() => _waitingDetailState();
}

class _waitingDetailState extends State<waitingDetail> {
  bool isRestaurantSelected = true;
  bool isFavorite = false;
  String? restaurantAddress;
  String?
      restaurantPhotoUrl; // Add a variable to store the restaurant photo URL
  List<Map<String, dynamic>> orderItems = [];
  int totalAmount = 0;
  LatLng? restaurantLocation; // Add a variable to store the restaurant location
  int isTakeout = 0; // Add a flag for takeout
  int averageWaitTime = 0; // Add a variable for average wait time

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
    _fetchOrderDetails();
    _fetchReservationType(); // Fetch reservation type
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      // Fetch restaurant address, photo URL, and average wait time from Firestore
      var restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('restaurantName', isEqualTo: widget.restaurantName)
          .limit(1)
          .get();

      if (restaurantSnapshot.docs.isNotEmpty) {
        var restaurantData = restaurantSnapshot.docs.first.data();
        setState(() {
          restaurantAddress = restaurantData['location'];
          restaurantPhotoUrl =
              restaurantData['photoUrl']; // Fetch the photo URL
          averageWaitTime = restaurantData['averageWaitTime'];
        });

        // Geocode the address to get the coordinates
        List<Location> locations =
            await locationFromAddress(restaurantAddress!);
        if (locations.isNotEmpty) {
          setState(() {
            restaurantLocation =
                LatLng(locations.first.latitude, locations.first.longitude);
          });
        }
      } else {
        setState(() {
          restaurantAddress = '주소를 찾을 수 없습니다.';
        });
      }
    } catch (e) {
      print('Error fetching restaurant details: $e');
      setState(() {
        restaurantAddress = '주소를 찾을 수 없습니다.';
      });
    }
  }

  Future<void> _fetchOrderDetails() async {
    try {
      // Fetch order details from Firestore
      var orderSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .collection('cart')
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> items = [];
        int total = 0;

        for (var doc in orderSnapshot.docs) {
          var item = doc.data();
          var menuItem = item['menuItem'];
          int price = 0;
          int quantity = 0;

          if (menuItem != null) {
            if (menuItem['price'] != null) {
              price = menuItem['price'] is int
                  ? menuItem['price']
                  : int.tryParse(menuItem['price'].toString()) ?? 0;
            }

            if (item['quantity'] != null) {
              quantity = item['quantity'] is int
                  ? item['quantity']
                  : int.tryParse(item['quantity'].toString()) ?? 0;
            }

            items.add({
              'name': menuItem['menuName'] ?? 'Unknown',
              'price': price,
              'quantity': quantity,
            });

            total += price * quantity;
          }
        }

        setState(() {
          orderItems = items;
          totalAmount = total;
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  Future<void> _fetchReservationType() async {
    try {
      // Fetch reservation type from Firestore
      var reservationSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .get();

      if (reservationSnapshot.exists) {
        setState(() {
          isTakeout = reservationSnapshot.data()!['type'];
        });
      }
    } catch (e) {
      print('Error fetching reservation type: $e');
    }
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('예약 취소'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('예약취소 사유를 입력해주세요.'),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(hintText: '사유 입력'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '사유를 입력해주세요.';
                    }
                    if (value.length < 3) {
                      return '사유는 최소 3글자 이상이어야 합니다.';
                    }
                    if (value.length > 100) {
                      return '사유는 최대 100글자 이하이어야 합니다.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String reason = reasonController.text;

                  try {
                    // Firestore에서 예약을 삭제
                    await FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(widget.reservationId)
                        .delete();

                    FlutterLocalNotification.showNotification(
                      '예약취소',
                      '예약이 취소되었습니다.',
                    );

                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/waitingNumber');
                  } catch (e) {
                    print('Error deleting reservation: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('예약 취소 중 오류가 발생했습니다.')),
                    );
                  }
                }
              },
              child: Text('확인'),
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
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            Center(
              child: Container(
                width: 200,
                height: 150,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.queueNumber.toString(),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                '(한 팀당 평균 대기 시간 : $averageWaitTime분)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.queue, color: Colors.blue, size: 15),
                  label: Text(
                    '예약정보 수정',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InfoInputScreen(
                            reservationId: widget
                                .reservationId), // Pass reservationId to InfoInputScreen
                      ),
                    );
                  },
                ),
                SizedBox(width: 5),
                ElevatedButton.icon(
                  icon: Icon(Icons.list_alt, color: Colors.blue, size: 15),
                  label: Text(
                    '장바구니 수정',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                  ),
                  onPressed: isTakeout == 2
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  cart(), // Pass reservationId if needed
                            ),
                          );
                        },
                ),
                SizedBox(width: 5),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.list_alt,
                    color: Colors.blue,
                    size: 15,
                  ),
                  label: Text('예약취소',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      )),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                  ),
                  onPressed: showCancelDialog,
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRestaurantSelected = true;
                    });
                  },
                  child: Text(
                    '음식점',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 18,
                      fontFamily: 'Epilogue',
                      fontWeight: isRestaurantSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRestaurantSelected = false;
                    });
                  },
                  child: Text(
                    '메뉴',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 18,
                      fontFamily: 'Epilogue',
                      fontWeight: isRestaurantSelected
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.black, thickness: 2.0),
            SizedBox(height: 20),
            if (isRestaurantSelected)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 20),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: restaurantPhotoUrl != null
                                    ? NetworkImage(restaurantPhotoUrl!)
                                    : AssetImage("assets/images/malatang.png")
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.restaurantName,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.star_border,
                                          color: Colors.black, // 테두리 색
                                        ),
                                        Icon(
                                          Icons.star,
                                          color: isFavorite
                                              ? Colors.yellow
                                              : Colors.transparent, // 채워진 색
                                        ),
                                      ],
                                    ),
                                    onPressed: toggleFavorite,
                                  ),
                                ],
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 200.0, // 원하는 최대 너비 설정
                                      ),
                                      child: Wrap(
                                        children: [
                                          Text(
                                            restaurantAddress ?? '',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Container(
                          height: 30,
                          width: 40,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(5)),
                          child: Center(
                            child: Text("위치",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: Container(
                          width: 400,
                          height: 300,
                          child: restaurantLocation != null
                              ? GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: restaurantLocation!,
                                    zoom: 14.0,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: MarkerId('restaurant'),
                                      position: restaurantLocation!,
                                    ),
                                  },
                                )
                              : Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            if (!isRestaurantSelected)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주문내역',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          var item = orderItems[index];
                          return ListTile(
                            title: Text(item['name']),
                            subtitle: Text('수량: ${item['quantity']}'),
                            trailing: Text('${item['price']}원'),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '총 금액: $totalAmount원',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: menuButtom(),
    );
  }
}

class InfoInputScreen extends StatefulWidget {
  final String reservationId;

  InfoInputScreen({required this.reservationId});

  @override
  _InfoInputScreenState createState() => _InfoInputScreenState();
}

class _InfoInputScreenState extends State<InfoInputScreen> {
  String nickname = '';
  int numberOfPeople = 1;
  bool isTakeout = false;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReservationDetails();
  }

  Future<void> _fetchReservationDetails() async {
    try {
      // Fetch reservation details from Firestore
      var reservationSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationId)
          .get();

      if (reservationSnapshot.exists) {
        var data = reservationSnapshot.data()!;
        setState(() {
          nickname = data['nickname'];
          numberOfPeople = data['numberOfPeople'];
          isTakeout = data['type'] == 2; // Assuming type 2 means takeout
          _nicknameController.text = nickname;
          _phoneController.text = data['phone'] ?? '';
          _altPhoneController.text = data['altPhone'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching reservation details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('정보입력'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTakeout ? '포장' : '매장',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 50),
            Text(
              '닉네임',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
              ),
            ),
            TextField(
              controller: _nicknameController,
              enabled: false, // Disable editing
              decoration: InputDecoration(),
            ),
            SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '인원수',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: isTakeout
                            ? null
                            : () {
                                setState(() {
                                  if (numberOfPeople > 0) {
                                    numberOfPeople--;
                                  }
                                });
                              }),
                    Text('$numberOfPeople'),
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: isTakeout || numberOfPeople >= 10
                            ? null
                            : () {
                                setState(() {
                                  if (numberOfPeople < 10) {
                                    numberOfPeople++;
                                  }
                                });
                              }),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              '전화번호',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
              ),
            ),
            TextField(
              controller: _phoneController,
              enabled: false, // Disable editing
              decoration: InputDecoration(),
            ),
            SizedBox(height: 30),
            Text(
              '보조전화번호',
              style: TextStyle(
                color: Color(0xFF1C1C21),
                fontSize: 18,
                fontFamily: 'Epilogue',
              ),
            ),
            TextField(
              controller: _altPhoneController,
              decoration: InputDecoration(),
            ),
            SizedBox(height: 100),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Update reservation details in Firestore
                  FirebaseFirestore.instance
                      .collection('reservations')
                      .doc(widget.reservationId)
                      .update({
                    'numberOfPeople': numberOfPeople,
                    'altPhone': _altPhoneController.text,
                  });

                  Navigator.pop(context); // 이전 페이지로 돌아가기
                },
                child: Text('수정'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.lightBlueAccent),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                  minimumSize: MaterialStateProperty.all(Size(200, 50)),
                  padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 10)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: menuButtom(),
    );
  }
}
