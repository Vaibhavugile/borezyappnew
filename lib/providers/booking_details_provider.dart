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

  /// WHATSAPP TEMPLATES
  List<QueryDocumentSnapshot> templates = [];

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

        Map<String, dynamic> first =
            bookingSnap.docs.first.data() as Map<String, dynamic>;

        customerDetails = first["userDetails"] ?? {};

        for (var doc in bookingSnap.docs) {

          Map<String, dynamic> data =
              doc.data() as Map<String, dynamic>;

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

      /// FETCH WHATSAPP TEMPLATES
      await fetchTemplates();

    } catch (e) {

      print("BookingDetails Error: $e");

    }

    loading = false;
    notifyListeners();
  }

  /// FETCH WHATSAPP TEMPLATES
  Future<void> fetchTemplates() async {

    try {

      var snap = await FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("templates")
          .orderBy("order")
          .get();

      templates = snap.docs;

    } catch(e){

      print("Template fetch error: $e");

    }

  }

  /// STAGE UPDATE FUNCTION

  Future<void> handleSaveSecondPayment() async {

    if (bookings.isEmpty) return;

    try {

      WriteBatch batch = FirebaseFirestore.instance.batch();

      List<Map<String, dynamic>> changes = [];

      Map<String, dynamic> currentDetails =
          bookings.first["userDetails"] ?? {};

      Map<String, dynamic> updates = {};

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

      /// ACTIVITY LOG
      Map<String, dynamic> newLogEntry = {

        "action":
        "Updated:\n${changes.map((c) => '${c["field"]} updated from \"${c["previous"]}\" to \"${c["updated"]}\" by \"${c["updatedby"]}\"').join("\n\n")}",

        "timestamp": DateTime.now().toIso8601String(),

        "updates": changes

      };

      /// UPDATE BOOKINGS
      for (var booking in bookings) {

        Map<String, dynamic> data =
            booking.data() as Map<String, dynamic>;

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

      /// SYNC PAYMENT DOC
      var paymentRef = FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("payments")
          .doc(receiptNumber);

      await paymentRef.update({
        "bookingStage": stage
      });

      if (paymentDoc != null) {
        paymentDoc!["bookingStage"] = stage;
      }

      notifyListeners();

      print("Receipt updated for all products");

    } catch (error) {

      print("Failed to update receipt: $error");

    }
  }

  /// WHATSAPP MESSAGE BUILDER
  String buildWhatsAppMessage(Map template) {

  if (bookings.isEmpty) return "";

  Map<String, dynamic> booking =
      bookings.first.data() as Map<String, dynamic>;

  var user = customerDetails ?? {};
  var payment = paymentDoc ?? {};

  String contactNo = user["contact"] ?? "";

  Timestamp? createdAt = booking["createdAt"];
  Timestamp? pickupDate = booking["pickupDate"];
  Timestamp? returnDate = booking["returnDate"];

  /// PRODUCTS
  List<Map<String, dynamic>> productsList = bookings.map((doc) {

    Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>;

    return {
      "productCode": data["productCode"] ?? "",
      "productName": data["productName"] ?? "",
      "quantity": data["quantity"] ?? ""
    };

  }).toList();

  String productsString =
      productsList.map((p) => "${p["productCode"]} : ${p["quantity"]}")
      .join(", ");

  String productsString1 =
      productsList.map((p) => "${p["productName"]}")
      .join(", ");

  String templateBody = template["body"] ?? "";

  String message = templateBody
      .replaceAll('{clientName}', user["name"] ?? '')
      .replaceAll('{clientEmail}', user["email"] ?? '')
      .replaceAll('{CustomerBy}', user["customerby"] ?? '')
      .replaceAll('{ReceiptBy}', user["receiptby"] ?? '')
      .replaceAll('{Alterations}', user["alterations"] ?? '')
      .replaceAll('{SpecialNote}', user["specialnote"] ?? '')

      /// RENT
      .replaceAll('{GrandTotalRent}', "${user["grandTotalRent"] ?? ''}")
      .replaceAll('{DiscountOnRent}', "${user["discountOnRent"] ?? ''}")
      .replaceAll('{FinalRent}', "${user["finalrent"] ?? ''}")

      /// DEPOSIT
      .replaceAll('{GrandTotalDeposit}', "${user["grandTotalDeposit"] ?? ''}")
      .replaceAll('{DiscountOnDeposit}', "${user["discountOnDeposit"] ?? ''}")
      .replaceAll('{FinalDeposit}', "${user["finaldeposite"] ?? ''}")

      /// PAYMENT
      .replaceAll('{AmountToBePaid}', "${user["totalamounttobepaid"] ?? ''}")
      .replaceAll('{AmountPaid}', "${user["amountpaid"] ?? ''}")
      .replaceAll('{Balance}', "${user["balance"] ?? ''}")
      .replaceAll('{PaymentStatus}', user["paymentstatus"] ?? '')

      /// PAYMENT MODES
      .replaceAll('{FirstPaymentMode}', user["firstpaymentmode"] ?? '')
      .replaceAll('{FirstPaymentDetails}', user["firstpaymentdtails"] ?? '')
      .replaceAll('{SecondPaymentMode}', user["secondpaymentmode"] ?? '')
      .replaceAll('{SecondPaymentDetails}', user["secondpaymentdetails"] ?? '')

      /// PRODUCTS
      .replaceAll('{Products}', productsString)
      .replaceAll('{Products1}', productsString1)

      /// DATES
      .replaceAll(
          '{createdAt}',
          createdAt != null
              ? createdAt.toDate().toString().split(" ")[0]
              : '')
      .replaceAll(
          '{pickupDate}',
          pickupDate != null
              ? pickupDate.toDate().toString().split(" ")[0]
              : '')
      .replaceAll(
          '{returnDate}',
          returnDate != null
              ? returnDate.toDate().toString().split(" ")[0]
              : '')

      /// BASIC INFO
      .replaceAll('{receiptNumber}', receiptNumber)
      .replaceAll('{stage}', stage)
      .replaceAll('{ContactNo}', contactNo)
      .replaceAll('{IdentityProof}', user["identityproof"] ?? '')
      .replaceAll('{IdentityNumber}', user["identitynumber"] ?? '');

  return message;
}

}