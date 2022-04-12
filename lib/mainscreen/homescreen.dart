import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ourcabs/Assistance/assistantmethod.dart';
import 'package:ourcabs/Assistance/geoFireAssistance.dart';
import 'package:ourcabs/Assistance/nearbydrivers.dart';
import 'package:ourcabs/Assistance/progressbar.dart';
import 'package:ourcabs/Datahandler/address.dart';
import 'package:ourcabs/Datahandler/appdata.dart';
import 'package:ourcabs/Datahandler/directiondetails.dart';
import 'package:ourcabs/Datahandler/ridedetails.dart';
import 'package:ourcabs/config.dart';
import 'package:ourcabs/login/login.dart';
import 'package:ourcabs/main.dart';
import 'package:ourcabs/mainscreen/locationsearch.dart';
import 'package:ourcabs/mainscreen/ridehistory.dart';
import 'package:ourcabs/mainscreen/searchsreen.dart';
import 'package:ourcabs/modules/collectfair.dart';
import 'package:ourcabs/modules/noDriverAvailable.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Homescreen extends StatefulWidget {
  String rideid, type;
  Homescreen({this.rideid, this.type});

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapcontroller;
  Position currpost;
  String address;
  var geolocator = Geolocator();
  bool cancel = false;
  bool cancel1 = false;
  DateTime now = DateTime.now();

  BitmapDescriptor nearByIcon;
  //BitmapDescriptor icon;

  bool nearbyAvailableDriverKeysLoaded = false;
  bool cross = false;
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  DatabaseReference rideRequestRef;
  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight;
  double driverDetailsContainerHeight = 0;
  String distance = "";
  int amount;
  LatLng latLng;
  DirectionDetails details;
  //String selected = "Auto";
  bool autoborder = true;
  bool sedanborder = false;
  bool miniborder = false;
  bool suvborder = false;
  bool driverCancel = false;

  DirectionDetails directionDetails;
  StreamSubscription<Event> ridestreamSubscription;
  bool isRequestingPositionDetails = false;
  double bottomPaddingOfMap = 0;

  String state = "normal";

  NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails("id", "name", "description",
          importance: Importance.high, priority: Priority.high));

  Set<String> availableDrivers = {};

  void initState() {
    if (widget.type == "OG") {
      cross = true;
      cancel = false;
      cancel1 = false;
      driverCancel = true;

      ongoingRide();
    }
    super.initState();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(12.972442, 77.580643),
    zoom: 14.4746,
  );

  void locatePostion() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currpost = position;
    });

    latLng = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLng, zoom: 14);

    newGoogleMapcontroller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    address = await Assistancemethod.searchCoordinateAddress(position, context);
    initGeofire();

    setState(() async {
      markersSet.add(Marker(
          markerId: MarkerId("Current Location"),
          position: latLng,
          icon: await icon));
    });

    //createMarkers();
  }

  GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();

  drawer() {
    return Drawer(
        child: Container(
            color: Colors.white,
            child: ListView(children: [
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Container(
                    height: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(FirebaseAuth.instance.currentUser.displayName)
                      ],
                    ),
                  )),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text("Your Rides"),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text("About"),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Login()));
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Logout"),
                ),
              )
            ])));
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    Position position;
    print("Function called");

    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(position.latitude, position.longitude);
      var details = await Assistancemethod.obtainPlaceDirectionDetails(
          driverCurrentLocation, positionUserLatLng, context);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void saveRideRequest() {
    print("Function called");
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Request").push();

    var pickup = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropoff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map<String, dynamic> pickUpLocMap = {
      "latitude": pickup.latitude.toString(),
      "longitude": pickup.longitude.toString(),
    };

    Map<String, dynamic> dropOffLocMap = {
      "latitude": dropoff.latitude.toString(),
      "longitude": dropoff.longitude.toString(),
    };
    Map<String, dynamic> rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "Name": FirebaseAuth.instance.currentUser.displayName,
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_phone": FirebaseAuth.instance.currentUser.phoneNumber,
      "pickup_address": pickup.placeName,
      "ride_type": carRideType,
      "dropoff_address": dropoff.placeName,
      "requestId": FirebaseAuth.instance.currentUser.uid,
    };

    rideRequestRef.set(rideInfoMap);
    num = 1;

    ridestreamSubscription = rideRequestRef.onValue.listen((event) {
      print("Status function called");
      print("Events" + event.snapshot.value.toString());

      if (event.snapshot.value == null) {
        return;
      }

      if (event.snapshot.value['status'] != null) {
        requestId = event.snapshot.key;

        statusRide = event.snapshot.value['status'].toString();
        print("RideStatus" + statusRide);

        if (event.snapshot.value["car_details"] != null) {
          setState(() {
            carDetailsDriver = event.snapshot.value["car_details"].toString();
          });
        }
        if (event.snapshot.value["otp"] != null) {
          setState(() {
            otp = event.snapshot.value["otp"].toString();
          });
        }
        if (event.snapshot.value["created_at"] != null &&
            event.snapshot.value["driver_id"] != null) {
          setState(() {
            date = event.snapshot.value["created_at"].toString();
            driverid = event.snapshot.value["driver_id"].toString();
          });
        }

        if (event.snapshot.value["driver_name"] != null) {
          setState(() {
            driverName = event.snapshot.value["driver_name"].toString();
          });
        }
        if (event.snapshot.value["driver_phone"] != null) {
          setState(() {
            driverphone = event.snapshot.value["driver_phone"].toString();
          });
        }
        if (event.snapshot.value["Regno"] != null) {
          setState(() {
            carno = event.snapshot.value["Regno"].toString();
          });
        }
        if (event.snapshot.value["ppic"] != null) {
          setState(() {
            dpic = event.snapshot.value["ppic"].toString();
          });
        }

        if (event.snapshot.value["driver_location"] != null) {
          double driverLat = double.parse(
              event.snapshot.value["driver_location"]["latitude"].toString());
          double driverLng = double.parse(
              event.snapshot.value["driver_location"]["longitude"].toString());
          LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

          if (statusRide == "accepted") {
            Map<String, dynamic> rideInfoMap = {
              "payment_method": "cash",
              "Name": FirebaseAuth.instance.currentUser.displayName,
              "pickup": pickUpLocMap,
              "dropoff": dropOffLocMap,
              "created_at": DateTime.now().toString(),
              "rider_phone": FirebaseAuth.instance.currentUser.phoneNumber,
              "pickup_address": pickup.placeName,
              "ride_type": carRideType,
              "dropoff_address": dropoff.placeName,
              "requestId": FirebaseAuth.instance.currentUser.uid,
            };
            rideRef.doc(event.snapshot.key).update(rideInfoMap);

            if (num == 1) {
              flutterLocalNotificationsPlugin.show(
                0,
                "Ride Status",
                "$driverName has accepted your request",
                platformChannelSpecifics,
              );
              num = 2;
            }

            updateRideTimeToPickUpLoc(driverCurrentLocation);
            displayDriverDetailsContainer();
            Geofire.stopListener();
            deleteGeofileMarkers();
          } else if (statusRide == "onride") {
            if (num == 3) {
              flutterLocalNotificationsPlugin.show(
                0,
                "Ride Status",
                "Your trip has started",
                platformChannelSpecifics,
              );
            }

            updateRideTimeToDropOffLoc(driverCurrentLocation);
          } else if (statusRide == "arrived") {
            if (num == 2) {
              flutterLocalNotificationsPlugin.show(
                0,
                "Ride Status",
                "$driverName has arived to your location",
                platformChannelSpecifics,
              );
              num = 3;
            }

            setState(() {
              rideStatus = "Driver has Arrived.";
            });
          } else if (statusRide == "cancelled") {
            if (num != 5) {
              num = 5;
              showDialog(
                context: context,
                builder: (context) => new AlertDialog(
                  title: new Text('Your ride has been cancelled'),
                  content: new Text(
                      'User has cancelled you ride please click okay to go back'),
                  actions: <Widget>[
                    new GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);

                        resetApp();
                        cancelRideRequest();
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
              resetApp();
              cancelRideRequest();
            }
          } else if (statusRide == "ended") {
            if (event.snapshot.value["fares"] != null) {
              String fareAmount = event.snapshot.value["fares"].toString();
              print("FareAmount " + fareAmount);
            }
            String fareAmount = event.snapshot.value["fares"].toString();

            rideRef.doc(requestId).update({"fares": fareAmount});

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => CollectFareDialog(
                fare: fareAmount,
                driverid: driverphone,
              ),
            );
            resetApp();
          }
        }
      }
    });

    //RideDetails rideDetails = RideDetails();
  }

  ongoingRide() {
    var initialPos =
        Provider.of<AppData>(context, listen: false).dropOffLocation;

    print("Initial Position" + initialPos.placeName.toString());

    FirebaseDatabase.instance
        .reference()
        .child("Ride Request")
        .child(widget.rideid)
        .onValue
        .listen((event) {
      // if (event.snapshot.value == null) {
      //   return;
      // }
      if (event.snapshot.value == null) {
        showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            //title: new Text('Your ride has been cancelled'),
            content: new Text(
                'Ride is not available or ride has been cancelled. Please book a new cab'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () {
                  Navigator.pop(context);

                  FirebaseFirestore.instance
                      .collection("Ride Request")
                      .doc(widget.rideid)
                      .update({"status": "cancelled"});

                  resetApp();
                  cancelRideRequest();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }

      if (event.snapshot.value != null) {
        if (event.snapshot.value['status'] != null) {
          requestId = event.snapshot.key;
          getPlaceDirection();
          statusRide = event.snapshot.value['status'].toString();
          print("RideStatus" + statusRide);

          if (event.snapshot.value["car_details"] != null) {
            setState(() {
              carDetailsDriver = event.snapshot.value["car_details"].toString();
            });
          }
          if (event.snapshot.value["otp"] != null) {
            setState(() {
              otp = event.snapshot.value["otp"].toString();
            });
          }
          if (event.snapshot.value["created_at"] != null &&
              event.snapshot.value["driver_id"] != null) {
            setState(() {
              date = event.snapshot.value["created_at"].toString();
              driverid = event.snapshot.value["driver_id"].toString();
            });
          }

          if (event.snapshot.value["driver_name"] != null) {
            setState(() {
              driverName = event.snapshot.value["driver_name"].toString();
            });
          }
          if (event.snapshot.value["driver_phone"] != null) {
            setState(() {
              driverphone = event.snapshot.value["driver_phone"].toString();
            });
          }
          if (event.snapshot.value["Regno"] != null) {
            setState(() {
              carno = event.snapshot.value["Regno"].toString();
            });
          }
          if (event.snapshot.value["ppic"] != null) {
            setState(() {
              dpic = event.snapshot.value["ppic"].toString();
            });
          }

          if (event.snapshot.value["driver_location"] != null) {
            double driverLat = double.parse(
                event.snapshot.value["driver_location"]["latitude"].toString());
            double driverLng = double.parse(event
                .snapshot.value["driver_location"]["longitude"]
                .toString());
            print("Driver location" + driverLat.toString());
            LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

            displayDriverDetailsContainer();
            Geofire.stopListener();
            deleteGeofileMarkers();

            if (statusRide == "accepted") {
              if (num == 1) {
                flutterLocalNotificationsPlugin.show(
                  0,
                  "Ride Status",
                  "$driverName has accepted your request",
                  platformChannelSpecifics,
                );
                num = 2;
              }

              updateRideTimeToPickUpLoc(driverCurrentLocation);
              displayDriverDetailsContainer();
              Geofire.stopListener();
              deleteGeofileMarkers();
            } else if (statusRide == "onride") {
              if (num == 3) {
                flutterLocalNotificationsPlugin.show(
                  0,
                  "Ride Status",
                  "Your trip has started",
                  platformChannelSpecifics,
                );
              }

              updateRideTimeToDropOffLoc(driverCurrentLocation);
            } else if (statusRide == "arrived") {
              if (num == 2) {
                flutterLocalNotificationsPlugin.show(
                  0,
                  "Ride Status",
                  "$driverName has arived to your location",
                  platformChannelSpecifics,
                );
                num = 3;
              }

              setState(() {
                rideStatus = "Driver has Arrived.";
              });
            } else if (statusRide == "cancelled") {
              if (num != 5) {
                num = 5;
                showDialog(
                  context: context,
                  builder: (context) => new AlertDialog(
                    title: new Text('Your ride has been cancelled'),
                    content: new Text(
                        'User has cancelled you ride please click okay to go back'),
                    actions: <Widget>[
                      new GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);

                          resetApp();
                          cancelRideRequest();
                        },
                        child: Text("OK"),
                      ),
                    ],
                  ),
                );
              } else {
                resetApp();
                cancelRideRequest();
              }
            } else if (statusRide == "ended") {
              if (event.snapshot.value["fares"] != null) {
                String fareAmount = event.snapshot.value["fares"].toString();
                print("FareAmount " + fareAmount);
              }
              String fareAmount = event.snapshot.value["fares"].toString();

              rideRef.doc(requestId).update({"fares": fareAmount});

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) => CollectFareDialog(
                  fare: fareAmount,
                  driverid: driverphone,
                ),
              );
              resetApp();
            }
          }
        }
      }
    });
  }

  void deleteGeofileMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var dropOff =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff.latitude, dropOff.longitude);

      var details = await Assistancemethod.obtainPlaceDirectionDetails(
          driverCurrentLocation, dropOffUserLatLng, context);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Going to Destination - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    FirebaseDatabase.instance
        .reference()
        .child("Ride Request")
        .child(rideRequestRef.key)
        .remove();
    if (mounted) {
      setState(() {
        state = "normal";
      });
    }
  }

  void displayRequestRideContainer() {
    if (mounted) {
      setState(() {
        requestRideContainerHeight = 0;
        rideDetailsContainerHeight = MediaQuery.of(context).size.height * 0.3;
        bottomPaddingOfMap = 0;
        cancel1 = true;
        cancel = false;
      });
    }

    saveRideRequest();
  }

  void displayDriverDetailsContainer() {
    if (mounted) {
      setState(() {
        requestRideContainerHeight = 0.0;
        rideDetailsContainerHeight = 0.0;
        cancel = false;
        cancel1 = false;
        //bottomPaddingOfMap = 295.0;
        driverDetailsContainerHeight =
            MediaQuery.of(context).size.height * 0.31;
        driverCancel = true;
      });
    }
  }

  resetApp() {
    if (mounted) {
      setState(() {
        cancel = false;
        cross = false;
        searchContainerHeight = MediaQuery.of(context).size.height * 0.2;
        rideDetailsContainerHeight = 0;
        requestRideContainerHeight = 0;
        bottomPaddingOfMap = 0;

        polylineSet.clear();
        markersSet.clear();
        circlesSet.clear();
        pLineCoordinates.clear();

        statusRide = "";
        driverName = "";
        driverphone = "";
        carDetailsDriver = "";
        rideStatus = "Driver is Coming";
        driverDetailsContainerHeight = 0.0;
        cancel = false;
        cross = false;
        cancel1 = false;
        driverCancel = false;
      });
    }

    locatePostion();
  }

  void mylocation(BuildContext context) async {
    if (icon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(1, 1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/marker.png")
          .then((value) {
        setState(() {
          icon = value;
        });
      });
    }
    print("Marker Created" + icon.toString());
  }

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    mylocation(context);

    searchContainerHeight = MediaQuery.of(context).size.height * 0.2;

    return WillPopScope(
      // ignore: missing_return
      onWillPop: () {
        if (cancel == true) {
          resetApp();
        } else if (cancel1 == true) {
          showDialog(
              context: context,
              builder: (BuildContext context) => Progressbar(
                    message: "Cancelling your ride request",
                  ));
          resetApp();
          cancelRideRequest();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else if (driverCancel == true) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => CancelDailog(
                    requestId: requestId,
                  ));
          resetApp();
          cancelRideRequest();
        } else {
          SystemNavigator.pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          key: scaffoldkey,
          drawer: drawer(),
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
                child: GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  polylines: polylineSet,
                  markers: markersSet,
                  circles: circlesSet,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    locatePostion();

                    _controllerGoogleMap.complete(controller);
                    newGoogleMapcontroller = controller;
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.02,
                left: MediaQuery.of(context).size.height * 0.01,
                child: GestureDetector(
                  onTap: () {
                    print("Cancel " + cross.toString());
                    if (cross == false) {
                      scaffoldkey.currentState.openDrawer();
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Homescreen()));
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: Colors.grey[700],
                          blurRadius: 10,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ], color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      (cross == false) ? Icons.menu : Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.01,
                right: MediaQuery.of(context).size.height * 0.01,
                left: MediaQuery.of(context).size.height * 0.01,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        locatePostion();

                        print(currpost);
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: Colors.grey[700],
                              blurRadius: 10,
                              spreadRadius: 0.5,
                              offset: Offset(0.7, 0.7))
                        ], color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.my_location),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: searchContainerHeight,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey[700],
                              blurRadius: 10,
                              spreadRadius: 0.5,
                              offset: Offset(0.7, 0.7))
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            Row(
                              children: [
                                // Icon(Icons.location_history_rounded),
                                // SizedBox(
                                //     width: MediaQuery.of(context).size.width *
                                //         0.02),
                                Expanded(
                                  child: Text(
                                    Provider.of<AppData>(context)
                                                .pickUpLocation !=
                                            null
                                        ? Provider.of<AppData>(context)
                                            .pickUpLocation
                                            .placeName
                                        : "Please on your Location",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.01),
                                GestureDetector(
                                    onTap: () async {
                                      var res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  LocationSearch()));

                                      if (res == 'obtainLocation') {
                                        await getLocation();
                                      }
                                    },
                                    child: Icon(Icons.edit)),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.015),
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Row(
                              children: [
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.015,
                                  width: MediaQuery.of(context).size.height *
                                      0.015,
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Where to go",
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.01,
                            ),
                            GestureDetector(
                              onTap: () async {
                                var res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Searchscreen()));

                                if (res == 'obtainDirection') {
                                  await getPlaceDirection();
                                  if (mounted) {
                                    setState(() {
                                      requestRideContainerHeight =
                                          MediaQuery.of(context).size.height *
                                              0.65;
                                      bottomPaddingOfMap =
                                          MediaQuery.of(context).size.height *
                                              0.65;
                                      print("bottom padding" +
                                          bottomPaddingOfMap.toString());
                                    });
                                  }
                                  cancel = true;
                                  cross = true;
                                }
                              },
                              child: Container(
                                height: 50,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey[700],
                                        blurRadius: 10,
                                        spreadRadius: 0.5,
                                        offset: Offset(0.7, 0.7))
                                  ],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Icon(Icons.search),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Search Destination",
                                      style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: requestRideContainerHeight,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[700],
                                )
                              ],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      Icons.brightness_1,
                                      size: 10,
                                    ),
                                    Text("I"),
                                    Icon(Icons.run_circle, size: 10)
                                  ],
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          child: Text(
                                            Provider.of<AppData>(context)
                                                        .pickUpLocation !=
                                                    null
                                                ? Provider.of<AppData>(context)
                                                    .pickUpLocation
                                                    .placeName
                                                : "Please on your Location",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.black,
                                        ),
                                        Container(
                                          child: Text(
                                            Provider.of<AppData>(context)
                                                        .dropOffLocation !=
                                                    null
                                                ? Provider.of<AppData>(context)
                                                    .dropOffLocation
                                                    .placeName
                                                : "Please on your Location",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Ride Categary",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: autoborder ? Colors.grey : Colors.white),
                            child: RaisedButton(
                              elevation: 0,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  state = "requesting";
                                  carRideType = "Auto";
                                  miniborder = false;
                                  autoborder = true;
                                  sedanborder = false;
                                  suvborder = false;
                                });
                              },
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'images/auto.png',
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                      width: MediaQuery.of(context).size.width *
                                          0.16,
                                    ),
                                    Column(
                                      // crossAxisAlignment:
                                      //     CrossAxisAlignment.start,
                                      children: [
                                        Text("Auto",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          distance,
                                          style:
                                              TextStyle(color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                        "₹" +
                                            ((Assistancemethod.calculateFares(
                                                        details, "Auto") !=
                                                    null)
                                                ? Assistancemethod
                                                        .calculateFares(
                                                            details, "Auto")
                                                    .toString()
                                                : " "),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: miniborder ? Colors.grey : Colors.white),
                            child: RaisedButton(
                              elevation: 0,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  state = "requesting";
                                  carRideType = "Mini";
                                  autoborder = false;
                                  miniborder = true;
                                  sedanborder = false;
                                  suvborder = false;
                                });
                              },
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'images/sedan1.png',
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                      width: MediaQuery.of(context).size.width *
                                          0.16,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Mini",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          distance,
                                          style:
                                              TextStyle(color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                        "₹" +
                                            ((Assistancemethod.calculateFares(
                                                        details, "Mini") !=
                                                    null)
                                                ? Assistancemethod
                                                        .calculateFares(
                                                            details, "Mini")
                                                    .toString()
                                                : " "),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color:
                                    sedanborder ? Colors.grey : Colors.white),
                            child: RaisedButton(
                              elevation: 0,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  state = "requesting";
                                  carRideType = "Sedan";
                                  autoborder = false;
                                  miniborder = false;
                                  sedanborder = true;
                                  suvborder = false;
                                });
                              },
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'images/sedan1.png',
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                      width: MediaQuery.of(context).size.width *
                                          0.16,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Sedan",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          distance,
                                          style:
                                              TextStyle(color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                        "₹" +
                                            ((Assistancemethod.calculateFares(
                                                        details, "Sedan") !=
                                                    null)
                                                ? Assistancemethod
                                                        .calculateFares(
                                                            details, "Sedan")
                                                    .toString()
                                                : " "),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: suvborder ? Colors.grey : Colors.white),
                            child: RaisedButton(
                              elevation: 0,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  state = "requesting";
                                  carRideType = "SUV";
                                  autoborder = false;
                                  sedanborder = false;
                                  miniborder = false;
                                  suvborder = true;
                                });
                              },
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      'images/suv1.png',
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                      width: MediaQuery.of(context).size.width *
                                          0.16,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("SUV",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          distance,
                                          style:
                                              TextStyle(color: Colors.black54),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                        "₹" +
                                            ((Assistancemethod.calculateFares(
                                                        details, "SUV") !=
                                                    null)
                                                ? Assistancemethod
                                                        .calculateFares(
                                                            details, 'SUV')
                                                    .toString()
                                                : " "),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                            ),
                          ),
                        ),
                        Divider(),
                        Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.07,
                              width: MediaQuery.of(context).size.height * 0.49,
                              child: RaisedButton(
                                  onPressed: () {
                                    cancel = true;
                                    print("Cancel " + cancel.toString());
                                    displayRequestRideContainer();
                                    int lng = GeoFireAssistant
                                        .nearByAvailableDriversList.length;
                                    print(lng);
                                    for (var i = 0; i < lng; i++) {
                                      availableDrivers.add(GeoFireAssistant
                                          .nearByAvailableDriversList[i].dkey);
                                    }
                                    print("Available Drivers" +
                                        availableDrivers.toString());
                                    searchNearestDriver();
                                  },
                                  color: Colors.grey[900],
                                  textColor: Colors.white,
                                  // shape: RoundedRectangleBorder(
                                  //     borderRadius: BorderRadius.circular(18.0)),
                                  child: Center(
                                      child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      //Icon(Icons.camera_alt_outlined),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01),
                                      Text(
                                        "Request $carRideType",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ))),
                            ))
                      ],
                    ),
                  )),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      height: rideDetailsContainerHeight,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[700],
                          )
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Center(
                            child: SizedBox(
                              width: 250.0,
                              child: DefaultTextStyle(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 25.0,
                                ),
                                child: AnimatedTextKit(
                                  repeatForever: true,
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                        'Requesting Cab.....'),
                                    TypewriterAnimatedText('Please wait.....'),
                                    // TypewriterAnimatedText(
                                    //     'Do not patch bugs out, rewrite them'),
                                    // TypewriterAnimatedText(
                                    //     'Do not test bugs out, design them out'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () {
                              // showDialog(
                              //     context: context,
                              //     builder: (BuildContext context) =>
                              //         Progressbar(
                              //           message: "Cancelling!!!",
                              //         ));

                              resetApp();
                              cancelRideRequest();

                              //Navigator.pop(context);
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 30,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          Text("Cancel"),
                          SizedBox(
                            height: 10,
                          )
                        ],
                      ))), //Display Assisned Driver Info
              Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 0.5,
                            blurRadius: 16.0,
                            color: Colors.black54,
                            offset: Offset(0.7, 0.7),
                          ),
                        ],
                      ),
                      height: driverDetailsContainerHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.005,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  rideStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Divider(
                              height: 2.0,
                              thickness: 2.0,
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  width:
                                      MediaQuery.of(context).size.height * 0.07,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        fit: BoxFit.fitWidth,
                                        image: NetworkImage(dpic)),
                                    shape: BoxShape.circle,
                                  ),
                                  // child: (ppurl != null)
                                  //     ? Image.network(ppurl)
                                  //     : Icon(Icons.person_add_alt),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      carDetailsDriver,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      driverName,
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                    Text(
                                      carno,
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.01,
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  color: Colors.redAccent,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.015,
                                      ),
                                      Text(
                                        "OTP",
                                        style: TextStyle(fontSize: 15.0),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.002,
                                      ),
                                      Text(
                                        otp,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Divider(
                              height: 2.0,
                              thickness: 2.0,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                //call button
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.36,
                                        child: RaisedButton(
                                          shape: new RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(24.0),
                                          ),
                                          onPressed: () async {
                                            launch(('tel://${driverphone}'));
                                          },
                                          color: Colors.black87,
                                          child: Padding(
                                            padding: EdgeInsets.all(17.0),
                                            child: Text(
                                              "Call",
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02,
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.36,
                                        child: RaisedButton(
                                          shape: new RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(24.0),
                                          ),
                                          onPressed: () async {
                                            print("Request Id " + requestId);
                                            showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (BuildContext context) =>
                                                        CancelDailog(
                                                          requestId: requestId,
                                                        ));
                                          },
                                          color: Colors.black87,
                                          child: Padding(
                                            padding: EdgeInsets.all(17.0),
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getLocation() async {
    var pickupPos = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var pickUpLatLng = LatLng(pickupPos.latitude, pickupPos.longitude);
    print("pickup" + pickupPos.toString());

    Marker pickUpLocMarker = Marker(
      icon: icon,
      infoWindow:
          InfoWindow(title: pickupPos.placeName, snippet: "my Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    CameraPosition cameraPosition =
        new CameraPosition(target: pickUpLatLng, zoom: 14);

    newGoogleMapcontroller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    if (mounted) {
      setState(() {
        markersSet.add(pickUpLocMarker);
      });
    }
  }

  Future<void> getPlaceDirection() async {
    print("called direction function");
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => Progressbar(
              message: "Please wait...",
            ));

    details = await Assistancemethod.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng, context);

    Navigator.pop(context);

    print("This is Encoded Points ::");
    print(details.encodedPoints);

    distance = details.distanceText;
    //amount = Assistancemethod.calculateFares(details);

    //Polyline

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    if (mounted) {
      setState(() {
        Polyline polyline = Polyline(
          color: Colors.grey[900],
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );

        polylineSet.add(polyline);
      });
    }

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapcontroller
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 80));

    Marker pickUpLocMarker = Marker(
      icon: icon,
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "my Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: icon,
      infoWindow:
          InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    if (mounted) {
      setState(() {
        markersSet.add(pickUpLocMarker);
        markersSet.add(dropOffLocMarker);
      });
    }

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropOffId"),
    );

    if (mounted) {
      setState(() {
        circlesSet.add(pickUpLocCircle);
        circlesSet.add(dropOffLocCircle);
      });
    }
  }

  void initGeofire() {
    Geofire.initialize("availableDrivers");
    //comment
    Geofire.queryAtLocation(currpost.latitude, currpost.longitude, 15)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.dkey = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearByAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.dkey = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      //setState(() {});
    });
    //comment
  }

  void updateAvailableDriversOnMap() {
    if (mounted) {
      setState(() {
        markersSet.clear();
      });
    }

    Set<Marker> tMakers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearByAvailableDriversList) {
      LatLng driverAvaiablePosition = LatLng(driver.latitude, driver.longitude);
      //print("Driver Postions: " + driverAvaiablePosition.toString());

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.dkey}'),
        position: driverAvaiablePosition,
        icon: nearByIcon,
        rotation: Assistancemethod.createRandomNumber(360),
      );

      tMakers.add(marker);
    }
    if (mounted) {
      setState(() {
        markersSet = tMakers;
      });
    }
  }

  void createIconMarker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/cabicon.png")
          .then((value) {
        nearByIcon = value;
      });
    }
  }

  void searchNearestDriver() {
    print("search function called");
    if (availableDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }
    print("Available Drivers" + availableDrivers.toString());
    var driver = availableDrivers.elementAt(0);
    print("Driver " + driver.toString());

    driversRef.child(driver).child("type").once().then((DataSnapshot snap) {
      if (snap.value != null) {
        print("Cartype " + snap.value.toString());
        String carType = snap.value.toString();

        if (carType == carRideType) {
          notifyDriver(driver);
          availableDrivers.remove(driver);
        } else {
          Fluttertoast.showToast(
            msg: carRideType + " drivers not available. Try again.",
          );
        }
      } else {
        const secs = Duration(seconds: 1);
        Timer.periodic(secs, (timer) {
          setState(() {
            driverRequestTimeOut = driverRequestTimeOut - 1;
            print("DriverTimeout " + driverRequestTimeOut.toString());
          });
          if (driverRequestTimeOut == 0) {
            timer.cancel();
            Fluttertoast.showToast(
                msg:
                    "No drivers are available near the location please try after some time");
            cancelRideRequest();
            resetApp();
            noDriverFound();
            return;
          }
        });
      }
    });
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailable());
  }

  void notifyDriver(String driverskey) {
    print("NotifyDriver called");
    driversRef.child(driverskey).child("newRide").set(rideRequestRef.key);
    String driverkey = driverskey;
    print("Driver Id: " + driverkey);

    print("Driver Details " + availableDrivers.length.toString());

    driversRef
        .child(driverskey)
        .child("token")
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        String token = snapshot.value.toString();
        Assistancemethod.sendNotificationToDriver(
            token, context, rideRequestRef.key);
      } else {
        return;
      }

      const secs = Duration(seconds: 1);
      Timer.periodic(secs, (timer) {
        if (driverRequestTimeOut == 0) {
          driversRef.child(driverkey).child("newRide").set("timeout");
          driversRef.child(driverkey).child("newRide").onDisconnect();
          driverRequestTimeOut = 20;
          timer.cancel();

          searchNearestDriver();
        } else {
          print("state" + state);

          if (state == "requesting") {
            print("object" + state);
            driversRef.child(driverkey).child("newRide").set("cancelled");
            driversRef.child(driverkey).child("newRide").onDisconnect();
            driverRequestTimeOut = 20;
            timer.cancel();
          }

          driversRef.child(driverkey).child("newRide").onValue.listen((event) {
            if (event.snapshot.value.toString() == "accepted") {
              driversRef.child(driverkey).child("newRide").onDisconnect();
              driverRequestTimeOut = 20;
              timer.cancel();
            }
          });

          setState(() {
            driverRequestTimeOut = driverRequestTimeOut - 1;
            print("DriverTimeout " + driverRequestTimeOut.toString());
          });
        }
      });
    });
  }
}

class CancelDailog extends StatefulWidget {
  String requestId;
  CancelDailog({this.requestId});
  @override
  _CancelDailogState createState() => _CancelDailogState();
}

class _CancelDailogState extends State<CancelDailog> {
  int groupValue = 1;
  String reason;
  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
            padding: EdgeInsets.all(10),
            height: MediaQuery.of(context).size.height * 0.45,
            width: MediaQuery.of(context).size.width * 0.99,
            child: Column(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Text('Reason for cancellation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Divider(
                color: Colors.black,
              ),
              RadioListTile(
                  activeColor: Colors.black,
                  title: Text('Driver Denied to go to destination'),
                  value: 1,
                  groupValue: groupValue,
                  onChanged: (int value) {
                    setState(() {
                      reason = "Driver Denied to go to destination";
                      groupValue = value;
                    });
                  }),
              RadioListTile(
                  activeColor: Colors.black,
                  title: Text('Driver Denied to come for pickup'),
                  value: 2,
                  groupValue: groupValue,
                  onChanged: (int value) {
                    setState(() {
                      reason = "Driver Denied to come for pickup";
                      groupValue = value;
                    });
                  }),
              RadioListTile(
                  activeColor: Colors.black,
                  title: Text('Unable to contact driver'),
                  value: 3,
                  groupValue: groupValue,
                  onChanged: (int value) {
                    setState(() {
                      reason = "Unable to contact driver";
                      groupValue = value;
                    });
                  }),
              RadioListTile(
                  activeColor: Colors.black,
                  title: Text('My reason is not listed'),
                  value: 4,
                  groupValue: groupValue,
                  onChanged: (int value) {
                    setState(() {
                      reason = "My reason is not listed";
                      groupValue = value;
                    });
                  }),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: RaisedButton(
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(5.0),
                  ),
                  onPressed: () {
                    rideRef.doc(requestId).update(
                        {"status": "cancelled", "CancellationReason": reason});
                    FirebaseDatabase.instance
                        .reference()
                        .child("Ride Request")
                        .child(requestId)
                        .child("status")
                        .set("cancelled");
                    num = 5;

                    Navigator.of(context).pop();
                  },
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              )
            ])));
  }
}
