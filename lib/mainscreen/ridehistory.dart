import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ourcabs/Datahandler/address.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/Datahandler/droppoff.dart';
import 'package:ourcabs/Datahandler/ridedetails.dart';
import 'package:ourcabs/mainscreen/homescreen.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          // appBar: AppBar(
          //   title: Text('Trip History'),
          //   backgroundColor: Colors.black87,
          //   leading: Icon(Icons.),

          // ),
          body: Column(
        children: [
          Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.07,
              padding: const EdgeInsets.all(8.0),
              color: Colors.black,
              child: Center(
                child: Text(
                  'Ride History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Ride Request")
                  .where("rider_phone",
                      isEqualTo: FirebaseAuth.instance.currentUser.phoneNumber)
                  .where("status", isNotEqualTo: "cancelled")
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return noData();
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      return cart(index, snapshot.data.docs[index]);
                    },
                  );
                }
              },
            ),
          ),
        ],
      )),
    );
  }

  noData() {
    return Column(
      children: [Icon(Icons.dangerous)],
    );
  }

  cart(int index, QueryDocumentSnapshot docs) {
    String type;
    String status = docs['status'];
    RideDetails rideDetails = RideDetails();
    print("Status" + status);
    print("Doc id" + docs.id);

    if (status == "ended") {
      if (docs["fares"] != null) {
        type = docs["fares"];
      }
    } else {
      type = "OG";
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          if (type == "OG") {
            print("statment called");
            String rideId = docs.id;
            print("RideId" + rideId);

            Address address = Address();
            address.placeName = docs["pickup_address"].toString();
            address.latitude =
                double.parse(docs["pickup"]["latitude"].toString());
            address.longitude =
                double.parse(docs["pickup"]["longitude"].toString());
            Provider.of<AppData>(context, listen: false)
                .updatePickUpLocationAddress(address);

            Address dropoff = Address();

            dropoff.placeName = docs["dropoff_address"].toString();
            dropoff.latitude =
                double.parse(docs["dropoff"]["latitude"].toString());
            dropoff.longitude =
                double.parse(docs["dropoff"]["longitude"].toString());
            Provider.of<AppData>(context, listen: false)
                .updateDropOffLocationAddress(dropoff);

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Homescreen(
                          rideid: rideId,
                          type: type,
                        )));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey[700],
              )
            ],
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docs['created_at'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // Text(
                      //   docs.id,
                      //   style: TextStyle(color: Colors.grey),
                      // ),
                    ],
                  ),
                  // SizedBox(
                  //   width: MediaQuery.of(context).size.width * 0.2,
                  // ),
                  Text((type == "OG") ? type : "₹" + type),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.brightness_1,
                        size: 5,
                      ),
                      Text("I"),
                      Icon(Icons.brightness_1, size: 5),
                    ],
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docs['pickup_address'].toString(),
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 5),
                        Text(docs['dropoff_address'].toString(),
                            overflow: TextOverflow.ellipsis)
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
