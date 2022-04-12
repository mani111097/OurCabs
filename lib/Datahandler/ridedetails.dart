class RideDetails {
  String pickUp_Address;
  String key;
  String dropOff_Address;
  String date;
  String paymentMethod;
  String fare;
  String requestorId;
  String status;

  RideDetails(
      {this.pickUp_Address,
      this.dropOff_Address,
      this.date,
      this.paymentMethod,
      this.fare,
      this.status,
      this.requestorId});
}
