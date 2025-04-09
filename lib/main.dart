import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'firebase_options.dart';

Future<void> _backgroundHandler(RemoteMessage message) async {
  print("🔥 [Background] Message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_notification'); // JPEG will not work well here

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        navigatorKey.currentState?.pushNamed(response.payload!);
      }
    },
  );

  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FCM Class Activity',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/important': (_) => ImportantPage(),
        '/regular': (_) => RegularPage(),
      },
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _notifications = [];
  String? _token;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    messaging.requestPermission();
    messaging.getToken().then((token) {
      print("🧪 FCM Token: $token");
      setState(() {
        _token = token;
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📥 [Foreground] Message received");

      String type = message.data['notificationType'] ?? 'regular';
      String route = type == 'important' ? '/important' : '/regular';
      String body = message.notification?.body ?? 'No body';

      setState(() {
        _notifications.add(body);
      });

      if (type == 'important') {
        await _audioPlayer.play(AssetSource('alert.mp3'));

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.red[100],
            title: const Text('🚨 Important Notification'),
            content: Text(body),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.blue[50],
            title: const Text('🔔 Regular Notification'),
            content: Text(body),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }

      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'ClassActivityChannel',
            icon: '@drawable/ic_stat_notification', // Will be ignored if JPEG!
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: route,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      String type = message.data['notificationType'] ?? 'regular';
      navigatorKey.currentState?.pushNamed(
        type == 'important' ? '/important' : '/regular',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Messaging'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_token != null)
              Text("🔑 Token:\n$_token", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            const Text("📜 Notification History:", style: TextStyle(fontSize: 16)),
            Expanded(
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (_, index) => ListTile(
                  title: Text(_notifications[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportantPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🚨 Important Page")),
      body: const Center(
        child: Text("This is the Important Notification Page."),
      ),
    );
  }
}

class RegularPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔔 Regular Page")),
      body: const Center(
        child: Text("This is the Regular Notification Page."),
      ),
    );
  }
}
