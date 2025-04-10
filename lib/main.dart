import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Tutorial',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FirebaseMessaging _messaging;
  List<Map<String, dynamic>> notificationHistory = [];
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Request permission (iOS requires this, Android handles automatically in newer versions)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get and display FCM token
    String? token = await _messaging.getToken();
    setState(() {
      fcmToken = token;
    });
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String type = message.data['notificationType'] ?? 'regular';
      String? body = message.notification?.body ?? 'No body';

      // Add to history
      setState(() {
        notificationHistory.insert(0, {
          'type': type,
          'body': body,
          'timestamp': DateTime.now(),
        });
      });

      // Show dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: type == 'important' ? Colors.red[100] : Colors.blue[100],
          title: Row(
            children: [
              Icon(
                type == 'important' ? Icons.warning : Icons.info,
                color: type == 'important' ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(type == 'important' ? 'Important' : 'Notification'),
            ],
          ),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked: ${message.notification?.body}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Tutorial'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FCM Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(fcmToken ?? 'Loading...', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Divider(),
          const Text('Notification History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: notificationHistory.length,
              itemBuilder: (context, index) {
                final notification = notificationHistory[index];
                return ListTile(
                  leading: Icon(
                    notification['type'] == 'important' ? Icons.warning : Icons.info,
                    color: notification['type'] == 'important' ? Colors.red : Colors.blue,
                  ),
                  title: Text(notification['body']),
                  subtitle: Text(notification['timestamp'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}