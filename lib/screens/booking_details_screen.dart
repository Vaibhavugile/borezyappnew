import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_details_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
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
  bool isProcessingPayment = false;
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
final userProvider = Provider.of<UserProvider>(context);
String userName = userProvider.userData?["name"] ?? "";
String customerName = provider.customerDetails?["name"] ?? "";
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

  actions: [

    /// WHATSAPP TEMPLATE BUTTON
    IconButton(

      icon: const Icon(
  Icons.message,
  color: Colors.green,
),

      onPressed: (){
        _openTemplateModal(context);
      },

    ),

  ],

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
            const SizedBox(height:18),

Row(
  children: [

    Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payments_outlined),
        label: const Text("Add Payment"),
        onPressed: (){
           showAddPaymentModal(context);
        },
      ),
    ),

    const SizedBox(width:12),

    Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.undo),
        label: const Text("Refund Deposit"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
        onPressed: (){
         showRefundModal(context);
        },
      ),
    ),

  ],
),

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
          _infoRow("Alterations", user["alterations"]),
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
Widget _productCard(List<Map<String, dynamic>> bookings) {

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

          var data = doc;

          var img = data["product"]?["imageUrls"];

String? imageUrl;

if (img is List && img.isNotEmpty) {
  imageUrl = img.first;
} else if (img is String) {
  imageUrl = img;
} else {
  imageUrl = null;
}

          return Container(

            margin: const EdgeInsets.only(bottom:12),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F2),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Row(

              children: [

                GestureDetector(

                  onTap: (){
                    if(imageUrl != null && imageUrl.isNotEmpty){
                      _showImagePreview(context,imageUrl);
                    }
                  },

                  child: Container(
                    width:46,
                    height:46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),

                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___){
                                return const Icon(Icons.checkroom);
                              },
                            )
                          : const Icon(Icons.checkroom),
                    ),
                  ),
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
                      "₹${data["price"] ?? 0}",
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
        _infoRow("Payment Status", payment["paymentStatus"]),
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

      var data = tx.data() as Map<String, dynamic>;

      bool isRefund = data["type"] == "depositReturn";

      return Container(

        margin: const EdgeInsets.only(bottom:12),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F2),
          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(

          children: [

            /// LEFT ICON
            Container(
              width:42,
              height:42,
              decoration: BoxDecoration(
                color: isRefund
                    ? Colors.red.withOpacity(.1)
                    : const Color(0xFFD4AF37).withOpacity(.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRefund
                    ? Icons.undo_rounded
                    : Icons.payments_outlined,
                color: isRefund
                    ? Colors.red
                    : const Color(0xFF735C00),
              ),
            ),

            const SizedBox(width:12),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
  children: [

    Expanded(
      child: Text(
        isRefund
            ? "Deposit Refunded"
            : "Payment ${data["paymentNumber"] ?? ""}",
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),

    const SizedBox(width:8),

    if(isRefund)
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal:8,
          vertical:2,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          "Refunded",
          style: TextStyle(
            fontSize:11,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
  ],
),

                  const SizedBox(height:2),

                  Text(
                    data["mode"] ?? "",
                    style: const TextStyle(fontSize:12),
                  ),

                  if((data["details"] ?? "").toString().isNotEmpty)
                    Text(
                      data["details"],
                      style: const TextStyle(
                        fontSize:12,
                        color: Colors.grey,
                      ),
                    ),

                ],
              ),
            ),

            /// AMOUNT
            Text(
              "₹${data["amount"]}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isRefund
                    ? Colors.red
                    : Colors.green,
              ),
            )

          ],
        ),
      );

    }).toList()

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
 void _openTemplateModal(BuildContext context) {

  var provider = Provider.of<BookingDetailsProvider>(context, listen:false);

  showModalBottomSheet(

    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,

    builder: (context) {

      return Container(

        height: MediaQuery.of(context).size.height * 0.55,

        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),

        child: Column(

          children: [

            /// DRAG HANDLE
            Container(
              margin: const EdgeInsets.only(top:12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height:16),

            /// HEADER
            const Text(
              "Send WhatsApp Template",
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1C1C),
              ),
            ),

            const SizedBox(height:6),

            Text(
              "Choose a template to send",
              style: TextStyle(
                fontSize:13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height:20),

            /// TEMPLATE LIST
            Expanded(

              child: provider.templates.isEmpty
                  ? const Center(
                      child: Text(
                        "No templates available",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )

                  : ListView.builder(

                      padding: const EdgeInsets.symmetric(horizontal:20),

                      itemCount: provider.templates.length,

                      itemBuilder: (context,index){

                        Map<String,dynamic> template =
                            provider.templates[index].data()
                            as Map<String,dynamic>;

                        return Container(

                          margin: const EdgeInsets.only(bottom:12),

                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F3F2),
                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: ListTile(

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal:16,
                              vertical:6,
                            ),

                            leading: Container(

                              width:40,
                              height:40,

                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(.15),
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: const Icon(
                                Icons.message_outlined,
                                color: Color(0xFF735C00),
                                size:20,
                              ),

                            ),

                            title: Text(
                              template["name"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:14,
                              ),
                            ),

                            subtitle: Text(
                              "Tap to send WhatsApp message",
                              style: TextStyle(
                                fontSize:12,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size:14,
                              color: Colors.grey,
                            ),

                            onTap: () async {

                              String message =
                                  provider.buildWhatsAppMessage(template);

                              String phone =
                                  provider.customerDetails?["contact"] ?? "";

                              /// CLEAN PHONE
                              phone = phone
                                  .replaceAll("+", "")
                                  .replaceAll(" ", "");

                              if (!phone.startsWith("91")) {
                                phone = "91$phone";
                              }

                              await sendWhatsAppMessage(phone, message);

                              if(context.mounted){
                                Navigator.pop(context);
                              }

                            },

                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height:20)

          ],
        ),
      );
    },
  );
}
void _showImagePreview(BuildContext context,String imageUrl){

  showDialog(
    context: context,
    builder: (_) {

      return Dialog(
        backgroundColor: Colors.transparent,

        child: Stack(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl),
            ),

            Positioned(
              right:8,
              top:8,
              child: GestureDetector(
                onTap: (){
                  Navigator.pop(context);
                },
                child: const CircleAvatar(
                  radius:16,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close,color: Colors.white,size:18),
                ),
              ),
            )

          ],
        ),
      );

    },
  );
}
Future<void> sendWhatsAppMessage(String phone, String message) async {

  try {

    /// CLEAN PHONE NUMBER
    phone = phone.replaceAll("+", "").replaceAll(" ", "");

    /// ADD INDIA CODE IF MISSING
    if (!phone.startsWith("91")) {
      phone = "91$phone";
    }

    /// ENCODE MESSAGE
    final encodedMessage = Uri.encodeComponent(message);

    /// PRIMARY WHATSAPP URL
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phone?text=$encodedMessage"
    );

    /// LAUNCH WHATSAPP
    await launchUrl(
      whatsappUrl,
      mode: LaunchMode.externalApplication,
    );

  } catch (e) {

    print("WhatsApp launch failed: $e");

    /// FALLBACK URL (more compatible)
    final fallbackUrl = Uri.parse(
      "https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}"
    );

    try {

      await launchUrl(
        fallbackUrl,
        mode: LaunchMode.externalApplication,
      );

    } catch (e) {

      print("Fallback WhatsApp launch failed: $e");

    }

  }


}
void showAddPaymentModal(BuildContext context) {

  final provider =
      Provider.of<BookingDetailsProvider>(context, listen:false);

  final userProvider =
      Provider.of<UserProvider>(context, listen:false);

  String userName = userProvider.userData?["name"] ?? "";
  String customerName = provider.customerDetails?["name"] ?? "";

  TextEditingController amountController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  String mode = "Cash";

  showDialog(
    context: context,
    builder: (context){

      bool isProcessing = false;

      return StatefulBuilder(
        builder: (context, setModalState) {

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Add Payment",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600
                    ),
                  ),

                  const SizedBox(height:20),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount"
                    ),
                  ),

                  const SizedBox(height:12),

                  DropdownButtonFormField<String>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "UPI", child: Text("UPI")),
                      DropdownMenuItem(value: "Card", child: Text("Card")),
                      DropdownMenuItem(value: "Bank", child: Text("Bank Transfer")),
                    ],
                    onChanged: (v){
                      mode = v!;
                    },
                    decoration: const InputDecoration(
                      labelText: "Payment Mode"
                    ),
                  ),

                  const SizedBox(height:12),

                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: "Details (optional)"
                    ),
                  ),

                  const SizedBox(height:20),

                  Row(
                    children: [

                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width:10),

                      Expanded(
                        child: ElevatedButton(

                          onPressed: isProcessing ? null : () async {

                            setModalState(() {
                              isProcessing = true;
                            });

                            double amount =
                                double.tryParse(amountController.text) ?? 0;

                            if(amount <= 0){
                              setModalState(() {
                                isProcessing = false;
                              });
                              return;
                            }

                            await provider.handleAddPayment(
                              amount,
                              mode,
                              detailsController.text,
                              userName,
                              customerName
                            );

                            if(context.mounted){
                              Navigator.pop(context);
                            }

                          },

                          child: isProcessing
                              ? const SizedBox(
                                  height:20,
                                  width:20,
                                  child: CircularProgressIndicator(
                                    strokeWidth:2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Add Payment"),

                        ),
                      )

                    ],
                  )

                ],
              ),
            ),
          );

        },
      );
    },
  );
}
void showRefundModal(BuildContext context){

  final provider =
      Provider.of<BookingDetailsProvider>(context, listen:false);

  final userProvider =
      Provider.of<UserProvider>(context, listen:false);

  String userName = userProvider.userData?["name"] ?? "";
  String customerName = provider.customerDetails?["name"] ?? "";

  TextEditingController amountController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  String mode = "Cash";

  showDialog(
    context: context,
    builder:(context){

      bool isProcessing = false;

      return StatefulBuilder(
        builder: (context, setModalState) {

          return Dialog(

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Refund Deposit",
                    style: TextStyle(
                      fontSize:20,
                      fontWeight: FontWeight.w600
                    ),
                  ),

                  const SizedBox(height:20),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Refund Amount"
                    ),
                  ),

                  const SizedBox(height:12),

                  DropdownButtonFormField<String>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value:"Cash", child: Text("Cash")),
                      DropdownMenuItem(value:"UPI", child: Text("UPI")),
                      DropdownMenuItem(value:"Bank", child: Text("Bank Transfer")),
                    ],
                    onChanged:(v){
                      mode = v!;
                    },
                    decoration: const InputDecoration(
                      labelText: "Refund Mode"
                    ),
                  ),

                  const SizedBox(height:12),

                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: "Details"
                    ),
                  ),

                  const SizedBox(height:20),

                  ElevatedButton(

                    onPressed: isProcessing ? null : () async {

                      setModalState(() {
                        isProcessing = true;
                      });

                      double amount =
                          double.tryParse(amountController.text) ?? 0;

                      if(amount <= 0){
                        setModalState(() {
                          isProcessing = false;
                        });
                        return;
                      }

                      await provider.handleReturnDeposit(
                        amount,
                        mode,
                        detailsController.text,
                        userName,
                        customerName
                      );

                      if(context.mounted){
                        Navigator.pop(context);
                      }

                    },

                    child: isProcessing
                        ? const SizedBox(
                            height:20,
                            width:20,
                            child: CircularProgressIndicator(
                              strokeWidth:2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Refund Deposit"),

                  ),

                ],
              ),
            ),
          );

        },
      );
    },
  );
}
}