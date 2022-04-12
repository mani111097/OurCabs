import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/config.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class CollectFareDialog extends StatefulWidget {
  final String fare, driverid;

  CollectFareDialog({this.fare, this.driverid});

  @override
  _CollectFareDialogState createState() => _CollectFareDialogState();
}

class _CollectFareDialogState extends State<CollectFareDialog> {
  @override
  Widget build(BuildContext context) {
    var pickup = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropoff = Provider.of<AppData>(context, listen: false).dropOffLocation;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22.0,
            ),
            Text(
              "Trip Fare",
              style: TextStyle(fontSize: 16.0, fontFamily: "Brand Bold"),
            ),
            SizedBox(
              height: 22.0,
            ),
            Divider(
              height: 2.0,
              thickness: 2.0,
            ),
            SizedBox(
              height: 16.0,
            ),
            Text(
              "₹ ${widget.fare}",
              style: TextStyle(fontSize: 55.0, fontFamily: "Brand Bold"),
            ),
            SizedBox(
              height: 16.0,
            ),
            SizedBox(
              height: 16.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "This is the total trip amount, it has been charged to the rider.",
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Divider(),
            SizedBox(
              height: 10.0,
            ),
            SmoothStarRating(
              rating: starCounter,
              borderColor: Colors.black,
              color: Colors.redAccent,
              allowHalfRating: false,
              starCount: 5,
              size: 45,
              onRated: (value) {
                starCounter = value;

                if (starCounter == 1) {
                  setState(() {
                    title = "Very Bad";
                  });
                }
                if (starCounter == 2) {
                  setState(() {
                    title = "Bad";
                  });
                }
                if (starCounter == 3) {
                  setState(() {
                    title = "Good";
                  });
                }
                if (starCounter == 4) {
                  setState(() {
                    title = "Very Good";
                  });
                }
                if (starCounter == 5) {
                  setState(() {
                    title = "Excellent";
                  });
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              title,
              style: TextStyle(
                  fontSize: 25.0,
                  //fontFamily: "Signatra",
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: RaisedButton(
                shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(24.0),
                ),
                onPressed: () async {
                  FirebaseFirestore.instance
                      .collection('Driver')
                      .doc(driverid)
                      .collection('User Details')
                      .doc('User Details')
                      .get()
                      .then((datasnapshot) {
                    if (datasnapshot.data()['Rating'] != null) {
                      double oldRatings = double.parse(
                          datasnapshot.data()['Rating'].toString());
                      double addRatings = oldRatings + starCounter;
                      double averageRatings = addRatings / 2;
                      FirebaseFirestore.instance
                          .collection('Driver')
                          .doc(driverid)
                          .collection('User Details')
                          .doc('User Details')
                          .update({'Rating': averageRatings.toString()});
                    }
                  });

                  Navigator.pop(context);
                },
                color: Colors.black,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Submit",
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
