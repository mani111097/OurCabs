import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ourcabs/Assistance/allusers.dart';
import 'package:ourcabs/Assistance/nearbydrivers.dart';

String key = "AIzaSyCjRZ62ZGSLO9cx23F6ieCWsk8QJPGJLCs";

User userCurrentInfo;
BitmapDescriptor icon;
int num;

int driverRequestTimeOut = 20;
String requestId;
String statusRide = "";
String rideStatus = "Driver is Coming";
String carDetailsDriver = "";
String driverName = "";
String driverphone = "";
String carno = "";
String dpic = "";
String otp = "";
List listTokens = [];
String date = " ";
double starCounter = 0.0;
String title = " ";
String driverid = " ";
String carRideType = "Auto";
Set<NearbyAvailableDrivers> list = Set();

String serverkey =
    "AAAAfee6GkQ:APA91bGWAD7f2UKVMFrPoE4GzSMfp46R9umkCCRXRGMNejg_figxS5Q0vtZboUYrYaxjPaiJbKdptgS3W3kQ5RoXuz81x82GVWF8t8O-oDqhwATzFmYRm4G35h15-_-4kSBrchDTYk61";
