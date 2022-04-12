import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ourcabs/config.dart';
import 'package:ourcabs/mainscreen/homescreen.dart';

class Data extends StatefulWidget {
  @override
  _DataState createState() => _DataState();
}

class _DataState extends State<Data> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Container(
                width: MediaQuery.of(context).size.height * 0.19,
                height: MediaQuery.of(context).size.height * 0.19,
                decoration: new BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.redAccent,
                  size: MediaQuery.of(context).size.height * 0.11,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.04,
              ),
              Text("Personal Details",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900])),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.04,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name:"),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TextField(
                        controller: name,
                        decoration: InputDecoration(hintText: "Enter you Name"),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email:"),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: TextField(
                        controller: email,
                        decoration:
                            InputDecoration(hintText: "Enter you Email Id"),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.07,
                  width: MediaQuery.of(context).size.height * 0.49,
                  child: RaisedButton(
                      onPressed: () {
                        print("Name " + name.text + "Email" + email.text);
                        if (name.text.isNotEmpty && email.text.isNotEmpty) {
                          FirebaseAuth.instance.currentUser
                              .updateProfile(displayName: name.text);
                          if (email.text.contains("@") &&
                              email.text.contains(".com")) {
                            FirebaseAuth.instance.currentUser
                                .updateEmail(email.text);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Homescreen()));
                          } else {
                            Fluttertoast.showToast(
                                msg: "Enter a valid Email id");
                          }
                        } else {
                          print("Else is called");
                          Fluttertoast.showToast(
                              msg: "Name/Email feild cannot be empty");
                        }
                      },
                      color: Colors.grey[900],
                      textColor: Colors.white,
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Proceed further",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.height * 0.02),
                          Icon(Icons.arrow_forward),
                        ],
                      ))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
