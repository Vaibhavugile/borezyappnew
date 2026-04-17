import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {

  String branchCode = "222";

  bool loading = true;

  DateTime selectedDate = DateTime.now();

  List createdDocs = [];
  List pickupDocs = [];
  List returnDocs = [];

  /// PRODUCT CACHE
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

    var createdSnap = await paymentsRef
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .get();

    var pickupSnap = await paymentsRef
        .where("pickupDate", isGreaterThanOrEqualTo: start)
        .where("pickupDate", isLessThan: end)
        .get();

    var returnSnap = await paymentsRef
        .where("returnDate", isGreaterThanOrEqualTo: start)
        .where("returnDate", isLessThan: end)
        .get();

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

    /// CREATED BOOKINGS
    for (var doc in createdSnap.docs) {

      var data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      createdDocs.add(doc);
      createdCount++;

      String receipt = data["receiptNumber"] ?? "";

      if (receipt.isEmpty) continue;

      /// Fetch products for created bookings
      if (!receiptProducts.containsKey(receipt)) {

        var bookings = await FirebaseFirestore.instance
            .collectionGroup("bookings")
            .where("receiptNumber", isEqualTo: receipt)
            .get();

        receiptProducts[receipt] = [];

        for (var booking in bookings.docs) {

          var b = booking.data();

          int qty = (b["quantity"] ?? 1).toInt();
          String code = b["productCode"] ?? "-";

          receiptProducts[receipt]!.add({
            "productCode": code,
            "quantity": qty
          });
        }
      }
    }

    /// PICKUPS
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

      if (receipt.isEmpty) continue;

      if (!receiptProducts.containsKey(receipt)) {

        var bookings = await FirebaseFirestore.instance
            .collectionGroup("bookings")
            .where("receiptNumber", isEqualTo: receipt)
            .get();

        receiptProducts[receipt] = [];

        for (var booking in bookings.docs) {

          var b = booking.data();

          int qty = (b["quantity"] ?? 1).toInt();
          String code = b["productCode"] ?? "-";

          productsOutTotal += qty;

          receiptProducts[receipt]!.add({
            "productCode": code,
            "quantity": qty
          });

          if (data["bookingStage"] == "pickupPending") {
            productsOutPending += qty;
          }
        }
      }
    }

    /// RETURNS
    for (var doc in returnSnap.docs) {

      var data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      returnDocs.add(doc);
      returnTotal++;

      if (data["bookingStage"] == "returnPending") {
        returnPending++;
      }

      String receipt = data["receiptNumber"] ?? "";

      if (receipt.isEmpty) continue;

      if (!receiptProducts.containsKey(receipt)) {

        var bookings = await FirebaseFirestore.instance
            .collectionGroup("bookings")
            .where("receiptNumber", isEqualTo: receipt)
            .get();

        receiptProducts[receipt] = [];

        for (var booking in bookings.docs) {

          var b = booking.data();

          int qty = (b["quantity"] ?? 1).toInt();
          String code = b["productCode"] ?? "-";

          productsInTotal += qty;

          receiptProducts[receipt]!.add({
            "productCode": code,
            "quantity": qty
          });

          if (data["bookingStage"] == "returnPending") {
            productsInPending += qty;
          }
        }
      }
    }

    /// FINAL CALCULATIONS

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