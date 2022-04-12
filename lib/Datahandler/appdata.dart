import 'package:flutter/foundation.dart';
import 'package:ourcabs/Datahandler/address.dart';
import 'package:ourcabs/Datahandler/directiondetails.dart';

class AppData extends ChangeNotifier {
  Address pickUpLocation, dropOffLocation;
  DirectionDetails directionDetails;

  String earnings = "0";
  int countTrips = 0;
  List<String> tripHistoryKeys = [];
  // List tripHistoryDataList = [];

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }

  //history
  void updateEarnings(String updatedEarnings) {
    earnings = updatedEarnings;
    notifyListeners();
  }

  void updateTripsCounter(int tripCounter) {
    countTrips = tripCounter;
    notifyListeners();
  }

  void updateTripKeys(List<String> newKeys) {
    tripHistoryKeys = newKeys;
    notifyListeners();
  }

  // void updateTripHistoryData(History eachHistory)
  // {
  //   tripHistoryDataList.add(eachHistory);
  //   notifyListeners();
  // }
}
