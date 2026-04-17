import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailsProvider extends ChangeNotifier {

  String branchCode;
  String receiptNumber;

  BookingDetailsProvider({
    required this.branchCode,
    required this.receiptNumber,
  });

  bool loading = true;

  /// PRODUCT BOOKINGS
  List<QueryDocumentSnapshot> bookings = [];

  /// PAYMENT DOC
  Map<String, dynamic>? paymentDoc;

  /// TRANSACTIONS
  List<QueryDocumentSnapshot> transactions = [];

  /// CUSTOMER DETAILS
  Map<String, dynamic>? customerDetails;

  /// BOOKING STAGE
  String stage = "";

  /// PAYMENT UPDATE FIELDS
  String secondPaymentMode = "";
  String secondPaymentDetails = "";
  String specialNote = "";
  String userName = "";

  /// PRODUCT CODES LIST
  List<String> productCodes = [];

  /// TOTAL QUANTITY
  int totalProducts = 0;

  Future<void> fetchDetails() async {

    loading = true;
    notifyListeners();

    try {

      /// FETCH BOOKINGS
      var bookingSnap = await FirebaseFirestore.instance
          .collectionGroup("bookings")
          .where("receiptNumber", isEqualTo: receiptNumber)
          .get();

      bookings = bookingSnap.docs;

      productCodes = [];
      totalProducts = 0;

      if (bookingSnap.docs.isNotEmpty) {

        customerDetails =
            bookingSnap.docs.first.data()["userDetails"] ?? {};

        for (var doc in bookingSnap.docs) {

          var data = doc.data();

          String code = data["productCode"] ?? "";
          int qty = (data["quantity"] ?? 1).toInt();

          if (code.isNotEmpty) {
            productCodes.add(code);
          }

          totalProducts += qty;
        }
      }

      /// FETCH PAYMENT DOC
      var paymentSnap = await FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("payments")
          .doc(receiptNumber)
          .get();

      if (paymentSnap.exists) {

        paymentDoc = paymentSnap.data();

        stage = paymentDoc?["bookingStage"] ?? "";

      }

      /// FETCH PAYMENT TRANSACTIONS
      var txSnap = await FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("payments")
          .doc(receiptNumber)
          .collection("transactions")
          .orderBy("paymentNumber")
          .get();

      transactions = txSnap.docs;

    } catch (e) {

      print("BookingDetails Error: $e");

    }

    loading = false;
    notifyListeners();
  }

  /// EXACT STAGE UPDATE FUNCTION (Same logic as Web)

 Future<void> handleSaveSecondPayment() async {

  if (bookings.isEmpty) return;

  try {

    WriteBatch batch = FirebaseFirestore.instance.batch();

    List<Map<String, dynamic>> changes = [];

    var currentDetails = bookings.first["userDetails"] ?? {};

    Map<String, dynamic> updates = {};

    /// SECOND PAYMENT MODE
    if (currentDetails["secondpaymentmode"] != secondPaymentMode &&
        secondPaymentMode.isNotEmpty) {

      updates["userDetails.secondpaymentmode"] = secondPaymentMode;

      changes.add({
        "field": "Second Payment Mode",
        "previous": currentDetails["secondpaymentmode"] ?? "N/A",
        "updated": secondPaymentMode,
        "updatedby": userName,
      });
    }

    /// SECOND PAYMENT DETAILS
    if (currentDetails["secondpaymentdetails"] != secondPaymentDetails &&
        secondPaymentDetails.isNotEmpty) {

      updates["userDetails.secondpaymentdetails"] = secondPaymentDetails;

      changes.add({
        "field": "Second Payment Details",
        "previous": currentDetails["secondpaymentdetails"] ?? "N/A",
        "updated": secondPaymentDetails,
        "updatedby": userName,
      });
    }

    /// SPECIAL NOTE
    if (currentDetails["specialnote"] != specialNote &&
        specialNote.isNotEmpty) {

      updates["userDetails.specialnote"] = specialNote;

      changes.add({
        "field": "Special Note",
        "previous": currentDetails["specialnote"] ?? "N/A",
        "updated": specialNote,
        "updatedby": userName,
      });
    }

    /// STAGE UPDATE
    String currentStage = currentDetails["stage"] ?? "";

    if (currentStage != stage && stage.isNotEmpty) {

      updates["userDetails.stage"] = stage;

      if (stage == "successful") {
        updates["userDetails.stageUpdatedAt"] =
            FieldValue.serverTimestamp();
      }

      if (stage == "cancelled") {
        updates["userDetails.stageCancelledAt"] =
            FieldValue.serverTimestamp();
      }

      changes.add({
        "field": "Stage",
        "previous": currentStage.isEmpty ? "N/A" : currentStage,
        "updated": stage,
        "updatedby": userName,
      });
    }

    if (changes.isEmpty) {
      print("No changes detected");
      return;
    }

    /// ACTIVITY LOG ENTRY
    Map<String, dynamic> newLogEntry = {
      "action":
          "Updated:\n${changes.map((c) => '${c["field"]} updated from \"${c["previous"]}\" to \"${c["updated"]}\" by \"${c["updatedby"]}\"').join("\n\n")}",
      "timestamp": DateTime.now().toIso8601String(),
      "updates": changes
    };

    /// UPDATE ALL BOOKINGS
    for (var booking in bookings) {

      Map data = booking.data() as Map;

      /// SAFE ARCHIVED CHECK
      if (data.containsKey("archived") && data["archived"] == true) {
        continue;
      }

      var bookingRef = booking.reference;

      batch.update(bookingRef, {
        ...updates,
        "activityLog": FieldValue.arrayUnion([newLogEntry]),
      });
    }

    await batch.commit();

    /// SYNC STAGE TO PAYMENT DOC
    var paymentRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments")
        .doc(receiptNumber);

    await paymentRef.update({
      "bookingStage": stage
    });

    /// UPDATE LOCAL STATE
    if (paymentDoc != null) {
      paymentDoc!["bookingStage"] = stage;
    }

    notifyListeners();

    print("Receipt updated for all products");

  } catch (error) {

    print("Failed to update receipt: $error");

  }
}

}