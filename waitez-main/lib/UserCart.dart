import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class cart extends StatefulWidget {
  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<cart> {
  List<Map<String, dynamic>> cartItems = [];
  String reservationId = '';

  @override
  void initState() {
    super.initState();
    _fetchUserAndReservationId();
  }

  Future<void> _fetchUserAndReservationId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? nickname = await _fetchNickname(user.email!);
        if (nickname != null) {
          await _fetchLatestReservationId(nickname);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user found with this email.')),
          );
        }
      }
    } catch (e) {
      print('Error fetching user or reservation ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user or reservation ID: $e')),
      );
    }
  }

  Future<String?> _fetchNickname(String email) async {
    // users 컬렉션에서 사용자 정보를 찾음
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      return userQuery.docs.first['nickname'];
    } else {
      // non_member 컬렉션에서 사용자 정보를 찾음
      final nonMemberQuery = await FirebaseFirestore.instance
          .collection('non_member')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (nonMemberQuery.docs.isNotEmpty) {
        return nonMemberQuery.docs.first['nickname'];
      }
    }
    return null;
  }

  Future<void> _fetchLatestReservationId(String nickname) async {
    final reservationQuery = await FirebaseFirestore.instance
        .collection('reservations')
        .where('nickname', isEqualTo: nickname)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (reservationQuery.docs.isNotEmpty) {
      final reservationDoc = reservationQuery.docs.first;
      setState(() {
        reservationId = reservationDoc.id;
      });
      _fetchCartItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No recent reservation found.')),
      );
    }
  }

  Future<void> _fetchCartItems() async {
    if (reservationId.isNotEmpty) {
      try {
        final cartQuery = await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .collection('cart')
            .get();

        setState(() {
          cartItems = cartQuery.docs
              .map((doc) =>
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
        });
      } catch (e) {
        print('Error fetching cart items: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching cart items: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No reservation found to fetch cart items.')),
      );
    }
  }

  Future<void> removeItem(int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .collection('cart')
          .doc(cartItems[index]['id'])
          .delete();

      setState(() {
        cartItems.removeAt(index);
      });
    } catch (e) {
      print('Error removing cart item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing cart item: $e')),
      );
    }
  }

  Future<void> updateQuantity(int index, int quantity) async {
    if (quantity > 0 && quantity <= 50) {
      try {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .collection('cart')
            .doc(cartItems[index]['id'])
            .update({'quantity': quantity});

        setState(() {
          cartItems[index]['quantity'] = quantity;
        });
      } catch (e) {
        print('Error updating cart item quantity: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cart item quantity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = cartItems.fold(
        0,
        (sum, item) =>
            sum +
            ((item['menuItem']?['price'] ?? 0) as int) *
                ((item['quantity'] ?? 1) as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '장바구니',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            Expanded(
              child: cartItems.isNotEmpty
                  ? ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = cartItems[index]['menuItem'];
                        return CartItem(
                          name: menuItem != null
                              ? menuItem['menuName'] as String? ?? ''
                              : '',
                          price: menuItem != null
                              ? menuItem['price'] as int? ?? 0
                              : 0,
                          quantity: cartItems[index]['quantity'] as int? ?? 1,
                          photoUrl: menuItem != null
                              ? menuItem['photoUrl'] as String? ?? ''
                              : '',
                          onRemove: () => removeItem(index),
                          onQuantityChanged: (newQuantity) =>
                              updateQuantity(index, newQuantity),
                        );
                      },
                    )
                  : Center(child: Text('장바구니에 아이템이 없습니다.')),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 금액',
                  style: TextStyle(
                    color: Color(0xFF1C1C21),
                    fontSize: 18,
                    fontFamily: 'Epilogue',
                    fontWeight: FontWeight.w700,
                    height: 0.07,
                    letterSpacing: -0.27,
                  ),
                ),
                Text('₩ $totalPrice', style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CartItem extends StatelessWidget {
  final String name;
  final int price;
  final int quantity;
  final String photoUrl;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.photoUrl,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey,
                image: photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₩ $price',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) {
                      onQuantityChanged(quantity - 1);
                    }
                  },
                ),
                Text('$quantity', style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: quantity < 50
                      ? () {
                          onQuantityChanged(quantity + 1);
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
