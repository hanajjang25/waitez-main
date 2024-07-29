import 'package:flutter/material.dart';
import 'RestaurantEdit.dart';

class RestaurantEditBefore extends StatefulWidget {
  @override
  _EnterRegistrationNumberPageState createState() =>
      _EnterRegistrationNumberPageState();
}

class _EnterRegistrationNumberPageState extends State<RestaurantEditBefore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음식점 수정'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '음식점 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: '등록번호를 입력하세요.'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '등록번호를 입력하세요.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        )),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => editregRestaurant(),
                          ),
                        );
                      },
                      child: Text('확인'),
                    ),
                    SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        )),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('취소'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditRegRestaurantPage extends StatelessWidget {
  final String registrationNumber;

  EditRegRestaurantPage({required this.registrationNumber});

  @override
  Widget build(BuildContext context) {
    // You can pass the registration number to the actual edit page
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Restaurant'),
      ),
      body: Center(
        child: Text(
            'Editing restaurant with registration number: $registrationNumber'),
      ),
    );
  }
}
