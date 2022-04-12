import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:ourcabs/Assistance/requestassistance.dart';
import 'package:ourcabs/Datahandler/address.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/Datahandler/directiondetails.dart';
import 'package:ourcabs/config.dart';
import 'package:provider/provider.dart';

class Assistancemethod {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$key";

    var response = await RequestAssistance.getRequest(url);

    if (response != "FAILED") {
      placeAddress = response["results"][0]["formatted_address"];

      Address userPickupAddress = new Address();
      userPickupAddress.latitude = position.latitude;
      userPickupAddress.longitude = position.longitude;
      userPickupAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickupAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(
      LatLng initialPosition, LatLng finalPosition, context) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$key";

    var res = await RequestAssistance.getRequest(directionUrl);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints =
        res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText =
        res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue =
        res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText =
        res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue =
        res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails, String type) {
    double fair;
    double accessfee = 20.0;
    double minifair = 30.0;

    if (directionDetails != null) {
      double timeTraveledFare = (directionDetails.durationValue / 60) * 0.20;
      double traveldis = directionDetails.distanceValue / 1000;
      if (type == "Auto") {
        if (traveldis <= 2.0) {
          fair = minifair + accessfee + timeTraveledFare;
          return fair.truncate();
        } else {
          double extrakm = (traveldis - 2.0) * 15;
          fair = minifair + accessfee + extrakm + timeTraveledFare;

          return fair.truncate();
        }
      }
      if (type == "Mini") {
        fair = (traveldis * 19) + accessfee + minifair + timeTraveledFare;

        return fair.truncate();
      }
      if (type == "Sedan") {
        fair = (traveldis * 24) + accessfee + minifair + timeTraveledFare;

        return fair.truncate();
      }
      if (type == "SUV") {
        fair = (traveldis * 35) + accessfee + minifair + timeTraveledFare;

        return fair.truncate();
      }
    } else {
      return null;
    }
    //in terms USD
  }

  // static void getCurrentOnlineUserInfo() async {
  //   User firebaseUser = FirebaseAuth.instance.currentUser;
  //   String userId = firebaseUser.uid;
  //   DatabaseReference reference =
  //       FirebaseDatabase.instance.reference().child("users").child(userId);

  //   reference.once().then((DataSnapshot dataSnapShot) {
  //     if (dataSnapShot.value != null) {
  //       //userCurrentInfo = user.fromSnapshot(dataSnapShot);
  //     }
  //   });
  // }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(
      String token, context, String rideRequestId) async {
    try {
      var destionation =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      Map<String, String> headerMap = {
        'Content-Type': 'application/json',
        'Authorization': "key=$serverkey",
      };

      Map notificationMap = {
        'body': 'DropOff Address, ${destionation.placeName}',
        'title': 'New Ride Request',
        'sound': 'alert'
      };

      Map dataMap = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
        'ride_request_id': rideRequestId,
      };

      Map<String, dynamic> sendNotificationMap = {
        'notification': notificationMap,
        'data': dataMap,
        'priority': "high",
        'to': token,
      };

      print("Message: " + sendNotificationMap.toString());
      var client = new Client();
      var url = 'https://fcm.googleapis.com/fcm/send';
      Uri uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      var res = await client.post(
        uri,
        headers: headerMap,
        body: json.encode(sendNotificationMap),
      );
      listTokens.remove(token);
      return true;
    } catch (e) {
      print(e);
      return;
    }
  }
}
