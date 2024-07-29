import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'linkPage.dart';
import 'MemberLogin.dart';
import 'UserSignUp.dart';
import 'MemberInfo.dart';
import 'MemberFindPwd.dart';
import 'MemberFindPwdEmail.dart';
import 'RestaurantReg.dart';
import 'RestaurantInfo.dart';
import 'UserwaitingNumber.dart';
import 'UserSearch.dart';
import 'UserHome.dart';
import 'StaffHome.dart';
import 'MemberFavorite.dart';
import 'RestaurantEdit.dart';
import 'MenuRegOne.dart';
import 'MenuRegList.dart';
import 'UserCart.dart';
import 'UserReservation.dart';
import 'UserReservationMenu.dart';
import 'MemberCommunity.dart';
import 'MemberProfile.dart';
import 'MenuEdit.dart';
import 'staffProfile.dart';
import 'UserSetting.dart';
import 'UserNoti.dart';
import 'MemberHistory.dart';
import 'NonMemberHome.dart';
import 'NonMemberInfo.dart';
import 'googleMap.dart';
import 'MemebrHistoryList.dart';
import 'MemberCommunityWrite.dart';
import 'communityMyPage.dart';
import 'notification.dart';
import 'sendingMessage.dart';
import 'RestaurantEditBefore.dart';
import 'nonMemberWaitingNumber.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  var initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final status = await Geolocator.checkPermission();
  if (status == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterLocalNotification.init();

    // Listen for messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      var androidNotiDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
      );
      var details = NotificationDetails(android: androidNotiDetails);
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          details,
        );
      }
    });

    // Handle app opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(message);
    });

    // Get FCM token
    _getToken();
  }

  void _getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("token : ${token ?? 'token NULL!'}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/restaurantInfo':
            if (settings.arguments is String) {
              final String restaurantId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) =>
                    RestaurantInfo(restaurantId: restaurantId),
              );
            }
            return _errorRoute();
          default:
            return null;
        }
      },
      routes: {
        '/': (context) => login(),
        //'/login': (context) => login(),
        '/signup': (context) => SignUp(),
        '/memberInfo': (context) => memberInfo(),
        '/findPassword': (context) => findPassword(),
        '/findPassword_email': (context) => findPasswordEmail(),
        '/regRestaurant': (context) => regRestaurant(),
        '/waitingNumber': (context) => waitingNumber(),
        '/nonMemberWaitingNumber': (context) => nonMemberWaitingNumber(),
        '/search': (context) => search(),
        '/home': (context) => home(),
        '/homeStaff': (context) => homeStaff(),
        '/favorite': (context) => Favorite(),
        '/editRestaurant': (context) => editregRestaurant(),
        '/MenuRegList': (context) => MenuRegList(),
        '/cart': (context) => cart(),
        '/reservation': (context) => Reservation(),
        '/community': (context) => CommunityMainPage(),
        '/communityMyPage': (context) => communityMyPage(),
        '/communityWrite': (context) => WritePostPage(),
        '/profile': (context) => Profile(),
        '/reservationMenu': (context) => UserReservationMenu(),
        '/menuEdit': (context) => MenuEdit(),
        '/staffProfile': (context) => staffProfile(),
        '/setting': (context) => setting(),
        '/noti': (context) => noti(),
        '/sendingMessage': (context) => sendingMessage(),
        '/nonMemberHome': (context) => nonMemberHome(),
        '/nonMemberInfo': (context) => nonMemberInfo(),
        '/historyList': (context) => historyList(),
        '/restaurantEditBefore': (context) => RestaurantEditBefore(),
        // '/sendSMS': (context) => messagesend(),
      },
    );
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Page not found or invalid arguments.'),
        ),
      ),
    );
  }
}
