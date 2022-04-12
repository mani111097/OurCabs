import 'package:ourcabs/Assistance/nearbydrivers.dart';

class GeoFireAssistant {
  static List<NearbyAvailableDrivers> nearByAvailableDriversList = [];

  static void removeDriverFromList(String key) {
    int index =
        nearByAvailableDriversList.indexWhere((element) => element.dkey == key);
    nearByAvailableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver) {
    int index = nearByAvailableDriversList
        .indexWhere((element) => element.dkey == driver.dkey);

    nearByAvailableDriversList[index].latitude = driver.latitude;
    nearByAvailableDriversList[index].longitude = driver.longitude;
  }
}
