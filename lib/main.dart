import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:giftle/model/home_screen.dart';
import 'package:giftle/pages/Login_Screen.dart';
import 'package:giftle/pages/creataccont.dart';
import 'package:giftle/pages/resPass.dart';
import 'package:giftle/wegedt/navbar.dart';
import 'auth.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تسجيل معالج الإشعارات الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'giftle',
      theme: ThemeData(
        primaryColor: Colors.green[300],
      ),
      home: const Auoth(),
      routes: {
        'homescreen': (context) => HomeScreen(),
        'singupscreen': (context) => const CreateUsers(),
        'loginscreen': (context) => const LoginScreen(),
        'signupscreen': (context) => const CreateUsers(),
        'respassscreen': (context) => ResetPasswordPage(),
        'navbar': (context) => NavBar(),
      },
    );
  }
}
