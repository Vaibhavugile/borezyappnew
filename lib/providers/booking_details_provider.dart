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

  /// PRODUCT CODES LIST
  List<String> productCodes = [];

  /// TOTAL QUANTITY
  int totalProducts = 0;

  Future<void> fetchDetails() async {

    loading = true;
    notifyListeners();

    try {

      /// 1️⃣ FETCH BOOKINGS (PRODUCTS)
      var bookingSnap = await FirebaseFirestore.instance
          .collectionGroup("bookings")
          .where("receiptNumber", isEqualTo: receiptNumber)
          .get();

      bookings = bookingSnap.docs;

      productCodes = [];
      totalProducts = 0;

      if (bookingSnap.docs.isNotEmpty) {

        /// CUSTOMER DETAILS FROM FIRST BOOKING
        customerDetails =
            bookingSnap.docs.first.data()["userDetails"] ?? {};

        /// EXTRACT PRODUCT CODES
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

      /// 2️⃣ FETCH PAYMENT DOC
      var paymentSnap = await FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("payments")
          .doc(receiptNumber)
          .get();

      if (paymentSnap.exists) {

        paymentDoc = paymentSnap.data();

        /// STAGE
        stage = paymentDoc?["bookingStage"] ?? "";

      }

      /// 3️⃣ FETCH PAYMENT TRANSACTIONS
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

}