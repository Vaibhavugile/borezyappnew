import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {

  String branchCode = "7007";

  bool loading = true;

  DateTime selectedDate = DateTime.now();

  List createdDocs = [];
  List pickupDocs = [];
  List returnDocs = [];

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
      paymentsRef
          .where("createdAt", isGreaterThanOrEqualTo: start)
          .where("createdAt", isLessThan: end)
          .get(),

      paymentsRef
          .where("pickupDate", isGreaterThanOrEqualTo: start)
          .where("pickupDate", isLessThan: end)
          .get(),

      paymentsRef
          .where("returnDate", isGreaterThanOrEqualTo: start)
          .where("returnDate", isLessThan: end)
          .get(),
    ]);

    var createdSnap = results[0];
    var pickupSnap = results[1];
    var returnSnap = results[2];

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

      if (data["bookingStage"] == "cancelled") continue;

      createdDocs.add(doc);
      createdCount++;

      String receipt = data["receiptNumber"] ?? "";
      if (receipt.isNotEmpty) receipts.add(receipt);
    }

    for (var doc in pickupSnap.docs) {
      var data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      pickupDocs.add(doc);
      pickupTotal++;

      if (data["bookingStage"] == "pickupPending") {
        pickupPending++;
      }

      rentPendingCalc += (data["rentPending"] ?? 0).toDouble();
      depositPendingCalc += (data["depositPending"] ?? 0).toDouble();

      String receipt = data["receiptNumber"] ?? "";
      if (receipt.isNotEmpty) receipts.add(receipt);
    }

    for (var doc in returnSnap.docs) {
      var data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      returnDocs.add(doc);
      returnTotal++;

      if (data["bookingStage"] == "returnPending") {
        returnPending++;
      }

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