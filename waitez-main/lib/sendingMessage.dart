import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class sendingMessage extends StatelessWidget {
  void _sendSMS(String message, List<String> recipients) async {
    String _message = Uri.encodeComponent(message);
    String _recipients = recipients.join(',');
    String _url = 'sms:$_recipients?body=$_message';

    if (await canLaunch(_url)) {
      await launch(_url);
    } else {
      throw 'Could not launch $_url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send SMS Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _sendSMS('Hello, this is a test message!', ['01023209299']);
          },
          child: Text('Send SMS'),
        ),
      ),
    );
  }
}
