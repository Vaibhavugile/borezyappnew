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
List<Map<String, dynamic>> bookings = [];
  /// PAYMENT DOC
  Map<String, dynamic>? paymentDoc;

  /// TRANSACTIONS
  List<QueryDocumentSnapshot> transactions = [];
  List<dynamic> activityLogs = [];

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
      /// FETCH ALL PRODUCTS
var productsSnap = await FirebaseFirestore.instance
    .collection("products")
    .doc(branchCode)
    .collection("products")
    .get();

Map<String, dynamic> productsMap = {};

for (var doc in productsSnap.docs) {
  productsMap[doc.id] = doc.data();
}

      /// FETCH BOOKINGS
     var bookingSnap = await FirebaseFirestore.instance
    .collectionGroup("bookings")
    .where("receiptNumber", isEqualTo: receiptNumber)
    .get();

List<Map<String, dynamic>> bookingList = [];

if (bookingSnap.docs.isNotEmpty) {

  Map<String, dynamic> first =
      bookingSnap.docs.first.data() as Map<String, dynamic>;

  customerDetails = first["userDetails"] ?? {};
    specialNote = customerDetails?["specialnote"] ?? "";
}
productCodes = [];
totalProducts = 0;

for (var doc in bookingSnap.docs) {

  Map<String, dynamic> data =
      doc.data() as Map<String, dynamic>;

  /// GET PRODUCT ID
  String productId = doc.reference.parent.parent!.id;

  /// GET PRODUCT DATA
  Map<String, dynamic>? productData = productsMap[productId];

  bookingList.add({
    ...data,
    "product": productData,
    "docRef": doc.reference
  });

  String code = data["productCode"] ?? "";
  int qty = (data["quantity"] ?? 1).toInt();

  if (code.isNotEmpty) {
    productCodes.add(code);
  }

  totalProducts += qty;
}

bookings = bookingList;
if (bookingList.isNotEmpty) {
  activityLogs = bookingList.first["activityLog"] ?? [];
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

        Map<String, dynamic> data = booking;
        if (data.containsKey("archived") && data["archived"] == true) {
          continue;
        }

        var bookingRef = booking["docRef"];

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

  Map<String, dynamic> booking = bookings.first;

  var user = customerDetails ?? {};
  var payment = paymentDoc ?? {};

  String contactNo = user["contact"] ?? "";

  Timestamp? createdAt = booking["createdAt"];
  Timestamp? pickupDate = booking["pickupDate"];
  Timestamp? returnDate = booking["returnDate"];

  /// PRODUCTS
List<Map<String, dynamic>> productsList = bookings.map((doc) {

  Map<String, dynamic> data = doc;

    return {
      "productCode": data["productCode"] ?? "",
      "productName": data["product"]?["productName"] ?? "",
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
Future<void> handleAddPayment(
  double amount,
  String mode,
  String details,
  String userName,
  String customerName,
) async {

  final db = FirebaseFirestore.instance;

  final paymentRef = db
      .collection("products")
      .doc(branchCode)
      .collection("payments")
      .doc(receiptNumber);

  final transactionsRef = paymentRef.collection("transactions");

  final paymentSnap = await paymentRef.get();

  Map<String, dynamic> paymentDoc = paymentSnap.data() ?? {};

  double newPaid = (paymentDoc["amountPaid"] ?? 0).toDouble() + amount;
  double totalAmount = (paymentDoc["totalAmount"] ?? 0).toDouble();

  double newBalance = totalAmount - newPaid;
  if (newBalance < 0) newBalance = 0;

  /// GET NEXT TRANSACTION NUMBER
  var snapshot = await transactionsRef.get();
  int nextPaymentNumber = snapshot.docs.length + 1;

  String transactionId = "tx$nextPaymentNumber";

  /// SAVE TRANSACTION
  await transactionsRef.doc(transactionId).set({
    "amount": amount,
    "mode": mode,
    "details": details,
    "paymentNumber": nextPaymentNumber,
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": userName
  });

  /// CALCULATE RENT / DEPOSIT SPLIT
  double rent = (paymentDoc["finalRent"] ?? 0).toDouble();
  double deposit = (paymentDoc["finalDeposit"] ?? 0).toDouble();
  double alreadyPaid = (paymentDoc["amountPaid"] ?? 0).toDouble();

  double rentCollectedBefore = alreadyPaid > rent ? rent : alreadyPaid;
  double rentPending = rent - rentCollectedBefore;

  double rentPay = amount > rentPending ? rentPending : amount;
  double depositPay = amount - rentPay;

  final ledgerRef = db
      .collection("products")
      .doc(branchCode)
      .collection("ledger");

  /// RENT LEDGER ENTRY
  if (rentPay > 0) {
    await ledgerRef.add({
      "receiptNumber": receiptNumber,
      "customerName": customerName,
      "type": "rentPayment",
      "amount": rentPay,
      "mode": mode,
      "details": details,
      "createdAt": FieldValue.serverTimestamp(),
      "createdBy": userName
    });
  }

  /// DEPOSIT LEDGER ENTRY
  if (depositPay > 0) {
    await ledgerRef.add({
      "receiptNumber": receiptNumber,
      "customerName": customerName,
      "type": "depositPayment",
      "amount": depositPay,
      "mode": mode,
      "details": details,
      "createdAt": FieldValue.serverTimestamp(),
      "createdBy": userName
    });
  }

  /// UPDATE PAYMENT DOCUMENT
  await paymentRef.update({
    "amountPaid": newPaid,
    "balance": newBalance
  });

  /// UPDATE ALL BOOKING DOCUMENTS
  WriteBatch batch = db.batch();

  for (var booking in bookings) {

    DocumentReference bookingRef = booking["docRef"];

    batch.update(bookingRef, {
      "userDetails.amountpaid": newPaid,
      "userDetails.balance": newBalance
    });

  }

  await batch.commit();
  await updateAccountSummary();

  await fetchDetails();
}
Future<void> handleReturnDeposit(
  double amount,
  String mode,
  String details,
  String userName,
  String customerName,
) async {

  final db = FirebaseFirestore.instance;

  final transactionsRef = db
      .collection("products")
      .doc(branchCode)
      .collection("payments")
      .doc(receiptNumber)
      .collection("transactions");

  final snapshot = await transactionsRef.get();

  int nextPaymentNumber = snapshot.docs.length + 1;
  String transactionId = "tx$nextPaymentNumber";

  /// SAVE REFUND TRANSACTION
  await transactionsRef.doc(transactionId).set({
    "amount": amount,
    "mode": mode,
    "details": details,
    "paymentNumber": nextPaymentNumber,
    "type": "depositReturn",
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": userName
  });

  /// SAVE LEDGER ENTRY
  await db
      .collection("products")
      .doc(branchCode)
      .collection("ledger")
      .add({
    "receiptNumber": receiptNumber,
    "customerName": customerName,
    "type": "depositReturn",
    "amount": amount,
    "mode": mode,
    "details": details,
    "createdAt": FieldValue.serverTimestamp(),
    "createdBy": userName
  });
await updateAccountSummary();
  await fetchDetails();
}
Future<void> updateAccountSummary() async {

  final db = FirebaseFirestore.instance;

  final paymentRef = db
      .collection("products")
      .doc(branchCode)
      .collection("payments")
      .doc(receiptNumber);

  final transactionsRef = paymentRef.collection("transactions");

  final paymentSnap = await paymentRef.get();
  final txSnap = await transactionsRef.get();

  Map<String,dynamic> paymentDoc = paymentSnap.data() ?? {};

  double totalPaid = 0;
  double totalRefunded = 0;

  for(var doc in txSnap.docs){

    var data = doc.data();

    if(data["type"] == "depositReturn"){
      totalRefunded += (data["amount"] ?? 0).toDouble();
    }else{
      totalPaid += (data["amount"] ?? 0).toDouble();
    }

  }

  double rent = (paymentDoc["finalRent"] ?? 0).toDouble();
  double deposit = (paymentDoc["finalDeposit"] ?? 0).toDouble();

  double rentCollected = totalPaid > rent ? rent : totalPaid;
  double rentPending = rent - rentCollected;

  double depositCollected = totalPaid > rent ? totalPaid - rent : 0;

  double depositPending = deposit - depositCollected;

  if(depositPending < 0) depositPending = 0;

  double depositReturned = totalRefunded;

  double depositWithYou =
      (depositCollected - depositReturned) < 0
          ? 0
          : (depositCollected - depositReturned);

  await paymentRef.update({

    "rentCollected": rentCollected,
    "rentPending": rentPending,

    "depositCollected": depositCollected,
    "depositPending": depositPending,

    "depositReturned": depositReturned,
    "depositWithYou": depositWithYou,

  });

}
}