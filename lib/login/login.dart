//import 'package:cab_demo/login/otp.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:international_phone_input/international_phone_input.dart';
import 'package:ourcabs/login/otp.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _phone = "";

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      _phone = internationalizedPhoneNumber;
      print(internationalizedPhoneNumber);
    });
  }

  numbercheck() {
    if (_phone == "") {
      Fluttertoast.showToast(msg: "Number could not be validated");
    }
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit an App'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("NO"),
              ),
              SizedBox(
                width: 10,
              ),
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Text("YES"),
              ),
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.67,
                width: MediaQuery.of(context).size.width,
                //color: Colors.green,
                child: Stack(children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(250),
                            bottomRight: Radius.circular(250))),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotatedBox(
                            quarterTurns: 1,
                            child: Container(
                              //color: Colors.red,
                              child: Image.asset(
                                'images/clipart66856.png',
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                              ),
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ]),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: 'Welcome to ',
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.03,
                        color: Colors.grey[900])),
                TextSpan(
                    text: 'Our Cabs',
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.03,
                        color: Colors.grey[900],
                        fontWeight: FontWeight.bold))
              ])),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: InternationalPhoneInput(
                    decoration:
                        InputDecoration.collapsed(hintText: 'Mobile Number'),
                    onPhoneNumberChange: onPhoneNumberChange,
                    initialPhoneNumber: _phone,
                    initialSelection: 'IN',
                    showCountryFlags: true,
                    showCountryCodes: true),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.07,
                  width: MediaQuery.of(context).size.height * 0.49,
                  child: RaisedButton(
                      onPressed: () {
                        //print("Button Pressed");
                        if (_phone.isEmpty && _phone.length < 10) {
                          Fluttertoast.showToast(
                              msg: "Number could not be validated");
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Otp(_phone)));
                        }
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
                              width: MediaQuery.of(context).size.height * 0.01),
                          Text(
                            "Verify your Phone Number",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
