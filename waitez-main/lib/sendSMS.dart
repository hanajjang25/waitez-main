// import 'package:flutter/material.dart';
// import 'package:flutter_sms/flutter_sms.dart';

// class messagesend extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Send SMS Example'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: _sendSMS,
//           child: Text('Send SMS'),
//         ),
//       ),
//     );
//   }

//   void _sendSMS() async {
//     String message = "Hello, this is a test message!";
//     List<String> recipients = ["+821023209299"]; // 실제 전화번호로 대체

//     try {
//       String result = await sendSMS(
//         message: message,
//         recipients: recipients,
//         sendDirect: true,
//       );
//       print(result);
//     } catch (error) {
//       print(error);
//     }
//   }
// }
