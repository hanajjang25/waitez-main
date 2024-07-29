import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class History extends StatelessWidget {
  final String restaurantName;
  final String date;
  final String imageAsset;
  final List<Map<String, dynamic>> menuItems;
  final String type;
  final String address;
  final String operatingHours;

  History({
    required this.restaurantName,
    required this.date,
    required this.imageAsset,
    required this.menuItems,
    required this.type,
    required this.address,
    required this.operatingHours,
  });

  @override
  Widget build(BuildContext context) {
    int totalPrice = menuItems.fold(0, (sum, item) {
      int price = item['price'] is int
          ? item['price']
          : int.parse(item['price'].toString());
      int quantity = item['quantity'] is int
          ? item['quantity']
          : int.parse(item['quantity'].toString());
      return sum + (price * quantity);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                restaurantName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '매장/포장 : $type',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  height: 1.2,
                  letterSpacing: -0.27,
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '주소 : $address',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  height: 1.2,
                  letterSpacing: -0.27,
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '영업시간 : $operatingHours',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 18,
                  fontFamily: 'Epilogue',
                  height: 1.2,
                  letterSpacing: -0.27,
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                date,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '주문내역:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(menuItems[index]['name']),
                    subtitle: Text('₩${menuItems[index]['price']}'),
                    trailing: Text('수량: ${menuItems[index]['quantity']}'),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 금액', style: TextStyle(fontSize: 18)),
                Text('₩ $totalPrice', style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
