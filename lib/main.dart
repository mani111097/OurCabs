import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/config.dart';
import 'package:ourcabs/login/data.dart';
import 'package:ourcabs/login/login.dart';
import 'package:ourcabs/mainscreen/homescreen.dart';
import 'package:provider/provider.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('logo');

AndroidNotificationChannel channel = AndroidNotificationChannel(
    "id", "name", "description",
     importance: Importance.high);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: initializationSettingsAndroid));

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      .createNotificationChannel(channel);

  runApp(MyApp());
}

CollectionReference rideRef =
    FirebaseFirestore.instance.collection("Ride Request");

DatabaseReference driversRef =
    FirebaseDatabase.instance.reference().child("Drivers");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(1, 1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/marker.png")
          .then((value) {
        icon = value;
      });
    }
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Our Cabs',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute:
            FirebaseAuth.instance.currentUser == null ? 'login' : 'home',
        routes: {
          'login': (context) => Login(),
          'home': (context) => Homescreen()
        },
      ),
    );
  }
}
