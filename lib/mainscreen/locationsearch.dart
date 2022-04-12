import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ourcabs/Assistance/requestassistance.dart';
import 'package:ourcabs/Datahandler/address.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/Datahandler/placePrediction.dart';
import 'package:ourcabs/config.dart';
import 'package:provider/provider.dart';

class LocationSearch extends StatefulWidget {
  @override
  _LocationSearchState createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Column(
        children: [
          Container(
              height: MediaQuery.of(context).size.height * 0.18,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey[500],
                      blurRadius: 4,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7))
                ],
              ),
              child: Column(children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Stack(children: [
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back_ios)),
                    Center(
                      child: Text(
                        "Set Pick Up",
                        style: TextStyle(fontSize: 15),
                      ),
                    )
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5)),
                      child: TextField(
                        onChanged: (val) {
                          findPlace(val);
                        },
                        controller: pickUpTextEditingController,
                        decoration: InputDecoration(
                          hintText: "Where you want us to pick you",
                          fillColor: Colors.grey[100],
                          filled: true,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                              left: 11.0, top: 15.0, bottom: 15.0),
                        ),
                      )),
                ),
              ])),
          SizedBox(
            height: 10.0,
          ),
          (placePredictionList.length > 0)
              ? Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0.0),
                      itemBuilder: (context, index) {
                        return PredictionTile(
                          placePredictions: placePredictionList[index],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(),
                      itemCount: placePredictionList.length,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                    ),
                  ),
                )
              : Container(
                  color: Colors.red,
                ),
        ],
      ),
    ));
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&location=12.9716,77.5946&radius=50000&strictbounds=true&key=$key&sessiontoken=1234567890&components=country:IN";

      var res = await RequestAssistance.getRequest(autoCompleteUrl);
      if (res == "FAILED") {
        return;
      }

      print(res);

      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;

  PredictionTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(
              width: 10.0,
            ),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(
                  width: 14.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                        placePredictions.main_text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(
                        height: 2.0,
                      ),
                      Text(
                        placePredictions.secondary_text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 10.0,
            ),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key";

    print("object" + placeDetailsUrl);

    var res = await RequestAssistance.getRequest(placeDetailsUrl);

    if (res == "failed") {
      return;
    }
    print(res);

    if (res["status"] == "OK") {
      print(res);
      Address address = Address();
      address.placeName = res["result"]["formatted_address"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(address);
      print("This is pick up Location :: ");
      print(address.placeName);

      Navigator.pop(context, "obtainLocation");
    }
  }
}
