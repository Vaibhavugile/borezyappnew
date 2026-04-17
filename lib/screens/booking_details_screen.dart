import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_details_provider.dart';

class BookingDetailsScreen extends StatefulWidget {

  final String receiptNumber;
  final String branchCode;

  const BookingDetailsScreen({
    super.key,
    required this.receiptNumber,
    required this.branchCode,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final TextEditingController specialNoteController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<BookingDetailsProvider>(context, listen:false)
          .fetchDetails();
    });
  }

  @override
  Widget build(BuildContext context) {

    var provider = Provider.of<BookingDetailsProvider>(context);

    if(provider.loading){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    var bookings = provider.bookings;
    var payment = provider.paymentDoc;
    var user = provider.customerDetails ?? {};

    if(bookings.isEmpty){
      return const Scaffold(
        body: Center(child: Text("No booking data found")),
      );
    }

    return Scaffold(

      backgroundColor: const Color(0xFFFBF9F8),

      appBar: AppBar(
        title: Text("Receipt ${widget.receiptNumber}"),
      ),

      body: RefreshIndicator(

        onRefresh: provider.fetchDetails,

        child: ListView(

          padding: const EdgeInsets.all(18),

          children: [

            _stageBadge(provider.stage),

            const SizedBox(height:16),

            _customerCard(user),
              const SizedBox(height:18),

  _updateReceiptSection(context),

            const SizedBox(height:18),

            _productCard(bookings),

            const SizedBox(height:18),

            _paymentCard(payment),

            const SizedBox(height:18),

            _paymentHistory(provider.transactions),

            const SizedBox(height:18),

            _accountSummary(payment),

          ],
        ),
      ),
    );
  }

  /// STAGE BADGE
  Widget _stageBadge(String stage){

    Color color = const Color(0xFFD4AF37);

    if(stage == "pickupPending") color = Colors.orange;
    if(stage == "pickup") color = Colors.blue;
    if(stage == "returnPending") color = Colors.purple;
    if(stage == "returned") color = Colors.green;
    if(stage == "cancelled") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical:10,horizontal:14),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        stage,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// CUSTOMER CARD
  Widget _customerCard(Map user){

    return _cardWrapper(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Customer Details",
            style: TextStyle(fontSize:18,fontWeight: FontWeight.w600),
          ),

          const SizedBox(height:16),

          _infoRow("Name", user["name"]),
          _infoRow("Email", user["email"]),
          _infoRow("Contact", user["contact"]),
          _infoRow("Identity", user["identityproof"]),
          _infoRow("Customer By", user["customerby"]),
          _infoRow("Receipt By", user["receiptby"]),
        ],
      ),
    );
  }
  Widget _updateReceiptSection(BuildContext context){

  var provider = Provider.of<BookingDetailsProvider>(context);

  return _cardWrapper(

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            const Text(
              "Update Receipt",
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.w600
              ),
            ),

            /// EDIT BUTTON
            if(!isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: (){
                  setState(() {
                    isEditing = true;
                    specialNoteController.text = provider.specialNote;
                  });
                },
              )

          ],
        ),

        const SizedBox(height:18),

        /// STAGE
        DropdownButtonFormField<String>(

          value: provider.stage,

          decoration: const InputDecoration(
            labelText: "Stage",
          ),

          items: const [

            DropdownMenuItem(
              value: "Booking",
              child: Text("Booking"),
            ),

            DropdownMenuItem(
              value: "pickupPending",
              child: Text("Pickup Pending"),
            ),

            DropdownMenuItem(
              value: "pickup",
              child: Text("Picked Up"),
            ),

            DropdownMenuItem(
              value: "returnPending",
              child: Text("Return Pending"),
            ),

            DropdownMenuItem(
              value: "return",
              child: Text("Returned"),
            ),

            DropdownMenuItem(
              value: "successful",
              child: Text("Successful"),
            ),

            DropdownMenuItem(
              value: "cancelled",
              child: Text("Cancelled"),
            ),

          ],

          onChanged: isEditing
              ? (value){
                  provider.stage = value!;
                }
              : null,

        ),

        const SizedBox(height:16),

        /// SPECIAL NOTE
        TextField(

          controller: specialNoteController,

          enabled: isEditing,

          decoration: const InputDecoration(
            labelText: "Special Note",
          ),

          onChanged: (v){
            provider.specialNote = v;
          },

        ),

        const SizedBox(height:20),

        /// SAVE BUTTON
        if(isEditing)
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(

              onPressed: () async {

                provider.userName =
                    provider.customerDetails?["receiptby"] ?? "Admin";

                await provider.handleSaveSecondPayment();
                // await provider.fetchDetails();

                if(context.mounted){

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1B1C1C),

      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      duration: const Duration(seconds: 3),

      content: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ),

          const SizedBox(width:12),

          const Expanded(
            child: Text(
              "Receipt updated successfully",
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        ],
      ),

    ),

  );

}

                setState(() {
                  isEditing = false;
                });

              },

              child: const Text("Save Changes"),

            ),
          )

      ],
    ),
  );
}

  /// PRODUCT CARD
  Widget _productCard(List bookings){

    return _cardWrapper(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Products",
            style: TextStyle(fontSize:18,fontWeight: FontWeight.w600),
          ),

          const SizedBox(height:16),

          ...bookings.map((doc){

            var data = doc.data();

            return Container(

              margin: const EdgeInsets.only(bottom:12),

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F2),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(

                children: [

                  Container(
                    width:46,
                    height:46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.checkroom),
                  ),

                  const SizedBox(width:12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          data["productName"] ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height:4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal:8,vertical:4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data["productCode"] ?? "",
                            style: const TextStyle(
                              fontSize:11,
                              color: Color(0xFF735C00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Text("Qty ${data["quantity"]}"),

                      Text(
                        "₹${data["price"]}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )

                    ],
                  )
                ],
              ),
            );

          }).toList()

        ],
      ),
    );
  }

  /// PAYMENT SUMMARY
  Widget _paymentCard(Map? payment){

  if(payment == null) return const SizedBox();

  return _cardWrapper(

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Payment Details",
          style: TextStyle(fontSize:18,fontWeight: FontWeight.w600),
        ),

        const SizedBox(height:18),

        /// RENT
        _infoRow("Grand Total Rent", "₹${payment["grandTotalRent"] ?? 0}"),
        _infoRow("Discount on Rent", "₹${payment["discountOnRent"] ?? 0}"),
        _infoRow("Final Rent", "₹${payment["finalRent"] ?? 0}"),

        const Divider(),

        /// DEPOSIT
        _infoRow("Grand Total Deposit", "₹${payment["grandTotalDeposit"] ?? 0}"),
        _infoRow("Discount on Deposit", "₹${payment["discountOnDeposit"] ?? 0}"),
        _infoRow("Final Deposit", "₹${payment["finalDeposit"] ?? 0}"),

        const Divider(),

        /// TOTAL
        _infoRow("Amount To Be Paid", "₹${payment["totalAmount"] ?? 0}"),
        _infoRow("Applied Credit", "₹${payment["appliedCredit"] ?? 0}"),
        _infoRow("Amount Paid", "₹${payment["amountPaid"] ?? 0}"),
        _infoRow("Balance", "₹${payment["balance"] ?? 0}"),

        // const Divider(),

        /// PAYMENT MODES
        // _infoRow("Payment Status", payment["paymentStatus"]),
        // _infoRow("First Payment Mode", payment["firstPaymentMode"]),
        // _infoRow("First Payment Details", payment["firstPaymentDetails"]),
        // _infoRow("Second Payment Mode", payment["secondPaymentMode"]),
        // _infoRow("Second Payment Details", payment["secondPaymentDetails"]),

      ],
    ),
  );
}

  /// PAYMENT HISTORY
  Widget _paymentHistory(List transactions){

    return _cardWrapper(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Payment History",
            style: TextStyle(fontSize:18,fontWeight: FontWeight.w600),
          ),

          const SizedBox(height:16),

          if(transactions.isEmpty)
            const Text("No payments recorded"),

          ...transactions.map((tx){

            var data = tx.data();

            return Container(

              margin: const EdgeInsets.only(bottom:12),

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F2),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Row(

                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          data["mode"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        Text(
                          data["details"] ?? "",
                          style: const TextStyle(fontSize:12),
                        ),

                      ],
                    ),
                  ),

                  Text(
                    "₹${data["amount"]}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )

                ],
              ),
            );

          })

        ],
      ),
    );
  }

  /// ACCOUNT SUMMARY
 Widget _accountSummary(Map? payment){

  if(payment == null) return const SizedBox();

  double rent = (payment["finalRent"] ?? 0).toDouble();
  double deposit = (payment["finalDeposit"] ?? 0).toDouble();

  double rentCollected = (payment["rentCollected"] ?? 0).toDouble();
  double rentPending = (payment["rentPending"] ?? 0).toDouble();

  double depositCollected = (payment["depositCollected"] ?? 0).toDouble();
  double depositPending = (payment["depositPending"] ?? 0).toDouble();

  double depositReturned = (payment["depositReturned"] ?? 0).toDouble();
  double depositWithYou = (payment["depositWithYou"] ?? 0).toDouble();

  return _cardWrapper(

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Account Summary",
          style: TextStyle(fontSize:18,fontWeight: FontWeight.w600),
        ),

        const SizedBox(height:16),

        /// RENT
        _infoRow("Total Rent", "₹$rent"),
        _infoRow("Rent Collected", "₹$rentCollected"),
        _infoRow("Rent Pending", "₹$rentPending"),

        const Divider(),

        /// DEPOSIT
        _infoRow("Total Deposit", "₹$deposit"),
        _infoRow("Deposit Collected", "₹$depositCollected"),
        _infoRow("Deposit Pending", "₹$depositPending"),

        const Divider(),

        /// REFUNDS
        _infoRow("Deposit Returned", "₹$depositReturned"),
        _infoRow("Deposit With You", "₹$depositWithYou"),

      ],
    ),
  );
}

  /// CARD WRAPPER
  Widget _cardWrapper({required Widget child}){

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  /// SAFE ROW (FIXES OVERFLOW)
  Widget _infoRow(String label, dynamic value){

    return Padding(
      padding: const EdgeInsets.only(bottom:10),

      child: Row(

        children: [

          Expanded(
            flex:4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          Expanded(
            flex:6,
            child: Text(
              value?.toString() ?? "-",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )

        ],
      ),
    );
  }

}