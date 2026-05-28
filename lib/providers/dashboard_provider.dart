import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {

  
  late String branchCode;

  DashboardProvider(this.branchCode);

  bool loading = true;

  DateTime selectedDate = DateTime.now();

  List createdDocs = [];
  List pickupDocs = [];
  List returnDocs = [];
  List pickupPendingDocs = [];
List returnPendingDocs = [];

  Map<String, List<Map<String, dynamic>>> receiptProducts = {};

  int createdCount = 0;
  int pickupTotal = 0;
  int pickupPending = 0;
  int returnTotal = 0;
  int returnPending = 0;

  int productsOutToday = 0;
  int productsOutDone = 0;

  int productsInToday = 0;
  int productsInDone = 0;

  double rentPendingToday = 0;
  double depositPendingToday = 0;

  Future<void> fetchData() async {
  if(branchCode.isEmpty) return;
    loading = true;
    notifyListeners();

    DateTime start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    DateTime end = start.add(const Duration(days: 1));

    var paymentsRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments");

      

    /// RUN PAYMENT QUERIES IN PARALLEL
    final results = await Future.wait([

  /// CREATED TODAY
  paymentsRef
      .where("createdAt", isGreaterThanOrEqualTo: start)
      .where("createdAt", isLessThan: end)
      .get(),

  /// PICKUPS TODAY
  paymentsRef
      .where("pickupDate", isGreaterThanOrEqualTo: start)
      .where("pickupDate", isLessThan: end)
      .get(),

  /// RETURNS TODAY
  paymentsRef
      .where("returnDate", isGreaterThanOrEqualTo: start)
      .where("returnDate", isLessThan: end)
      .get(),

  /// ALL PICKUP PENDING
  paymentsRef
      .where("bookingStage", isEqualTo: "pickupPending")
      .get(),

  /// ALL RETURN PENDING
  paymentsRef
      .where("bookingStage", isEqualTo: "returnPending")
      .get(),

]);
    var createdSnap = results[0];
var pickupSnap = results[1];
var returnSnap = results[2];

var pickupPendingSnap = results[3];
var returnPendingSnap = results[4];
pickupPendingDocs = pickupPendingSnap.docs;
returnPendingDocs = returnPendingSnap.docs;

    createdDocs = [];
    pickupDocs = [];
    returnDocs = [];

    receiptProducts = {};

    createdCount = 0;
    pickupTotal = 0;
    pickupPending = 0;
    returnTotal = 0;
    returnPending = 0;

    int productsOutTotal = 0;
    int productsOutPending = 0;

    int productsInTotal = 0;
    int productsInPending = 0;

    double rentPendingCalc = 0;
    double depositPendingCalc = 0;

    /// COLLECT RECEIPTS
    Set<String> receipts = {};

    for (var doc in createdSnap.docs) {
      var data = doc.data();

      if (data["bookingStage"] == "cancelled" || data["bookingStage"] == "postponed") continue;

      createdDocs.add(doc);
      createdCount++;

      String receipt = data["receiptNumber"] ?? "";
      if (receipt.isNotEmpty) receipts.add(receipt);
    }

    for (var doc in pickupSnap.docs) {
      var data = doc.data();

      if (data["bookingStage"] == "cancelled" || data["bookingStage"] == "postponed") continue;

      pickupDocs.add(doc);
      pickupTotal++;


      rentPendingCalc += (data["rentPending"] ?? 0).toDouble();
      depositPendingCalc += (data["depositPending"] ?? 0).toDouble();

      String receipt = data["receiptNumber"] ?? "";
      if (receipt.isNotEmpty) receipts.add(receipt);
    }

    for (var doc in returnSnap.docs) {
      var data = doc.data();

      if (data["bookingStage"] == "cancelled" || data["bookingStage"] == "postponed") continue;

      returnDocs.add(doc);
      returnTotal++;

      
      String receipt = data["receiptNumber"] ?? "";
      if (receipt.isNotEmpty) receipts.add(receipt);
    }

    /// FETCH BOOKINGS (BATCHED WHEREIN)
    Map<String, List<Map<String, dynamic>>> bookingsByReceipt = {};

    if (receipts.isNotEmpty) {

      List<String> receiptList = receipts.toList();

      for (int i = 0; i < receiptList.length; i += 30) {

        List<String> batch = receiptList.skip(i).take(30).toList();

        var bookingSnap = await FirebaseFirestore.instance
            .collectionGroup("bookings")
            .where("receiptNumber", whereIn: batch)
            .get();

        for (var doc in bookingSnap.docs) {

          var data = doc.data();

          String receipt = data["receiptNumber"] ?? "";
          int qty = (data["quantity"] ?? 1).toInt();
          String code = data["productCode"] ?? "-";

          bookingsByReceipt.putIfAbsent(receipt, () => []);

          bookingsByReceipt[receipt]!.add({
            "productCode": code,
            "quantity": qty
          });
        }
      }
    }

    receiptProducts = bookingsByReceipt;


    /// CALCULATE PICKUPS
    for (var doc in pickupDocs) {

      var data = doc.data();
      String receipt = data["receiptNumber"] ?? "";

      if (!bookingsByReceipt.containsKey(receipt)) continue;

      for (var product in bookingsByReceipt[receipt]!) {

        int qty = product["quantity"];

        productsOutTotal += qty;

        if (data["bookingStage"] == "pickupPending") {
          productsOutPending += qty;
        }
      }
    }

    /// CALCULATE RETURNS
    for (var doc in returnDocs) {

      var data = doc.data();
      String receipt = data["receiptNumber"] ?? "";

      if (!bookingsByReceipt.containsKey(receipt)) continue;

      for (var product in bookingsByReceipt[receipt]!) {

        int qty = product["quantity"];

        productsInTotal += qty;

        if (data["bookingStage"] == "returnPending") {
          productsInPending += qty;
        }
      }
    }
pickupPending = pickupPendingSnap.docs.length;
returnPending = returnPendingSnap.docs.length;
    productsOutToday = productsOutTotal;
    productsOutDone = productsOutTotal - productsOutPending;

    productsInToday = productsInTotal;
    productsInDone = productsInTotal - productsInPending;

    rentPendingToday = rentPendingCalc;
    depositPendingToday = depositPendingCalc;

    loading = false;
    notifyListeners();
  }

  void changeDate(DateTime newDate) {
    selectedDate = newDate;
    fetchData();
  }

  Future<void> refresh() async {
    await fetchData();
  }
}