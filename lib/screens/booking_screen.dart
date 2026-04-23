import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';
import '../providers/booking_details_provider.dart';
import 'booking_details_screen.dart';
class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
DateTime getFixedPickupTime(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    1,
    0,
    0,
  );
}
String getBranchCode() {
  return Provider.of<UserProvider>(context, listen: false).branchCode ?? "";
}
bool validateCustomerStep() {

  if(userDetails["name"].toString().trim().isEmpty){
    showError("Customer name is required");
    return false;
  }

  if(userDetails["contact"].toString().trim().isEmpty){
    showError("Mobile number is required");
    return false;
  }

  if(userDetails["contact"].toString().length != 10){
    showError("Enter valid 10 digit mobile number");
    return false;
  }

  if(userDetails["customerby"].toString().trim().isEmpty){
    showError("Please select Customer By");
    return false;
  }

  if(userDetails["receiptby"].toString().trim().isEmpty){
    showError("Please select Receipt By");
    return false;
  }

  return true;
}
void showError(String message){

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );

}

DateTime getFixedReturnTime(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    23,
    0,
    0,
  );
}
  int wizardStep = 1;
  List products = [];
  List subUsers = [];
  Map userDetails = {
  "name": "",
  "email": "",
  "contact": "",
  "alternativecontactno": "",
  "identityproof": "",
  "identitynumber": "",
  "source": "",
  "customerby": "",
  "receiptby": "",
  "stage": "Booking",
  "alterations": "",
  "grandTotalRent": "",
  "grandTotalDeposit": "",
  "discountOnRent": "",
  "discountOnDeposit": "",
  "finalrent": "",
  "finaldeposite": "",
  "totalamounttobepaid": "",
  "amountpaid": "",
  "paymentstatus": "",
  "firstpaymentmode": "",
  "firstpaymentdtails": "",
  "secondpaymentmode": "",
  "secondpaymentdetails": "",
  "specialnote": ""
};
Map receipt = {};
  List productSuggestions = [];
  int? activeProductIndex;
  List<TextEditingController> productControllers = [];
double availableCredit = 0;
String? creditNoteId;
double appliedCredit = 0;
bool isButtonDisabled = false;

 @override
void initState() {
  super.initState();
  products = getInitialProducts();
  fetchSubUsers();
}

 List getInitialProducts() {

  DateTime pickupDate = getFixedPickupTime(DateTime.now());

  DateTime returnDate =
      getFixedReturnTime(DateTime.now().add(const Duration(days: 2)));

  productControllers.add(TextEditingController());

  return [
    {
      "pickupDate": pickupDate,
      "returnDate": returnDate,
      "productCode": "",
      "quantity": "",
      "availableQuantity": null,
      "errorMessage": "",
      "price": "",
      "deposit": "",
      "productName": "",
      "allBookings": []
    }
  ];
}

  @override
  Widget build(BuildContext context) {
return WillPopScope(
onWillPop: () async {


  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainScreen()),
    (route) => false,
  );

  return false;
},
child: Scaffold(
  backgroundColor: const Color(0xFFFBF9F8),

 appBar: AppBar(
  backgroundColor: const Color(0xFFFBF9F8),
  elevation: 0,
  title: const Text(
    "Borezy",
    style: TextStyle(
      color: Color(0xFF735C00),
      fontWeight: FontWeight.w600,
      fontSize: 22,
    ),
  ),

  actions: [

    /// REFRESH BUTTON (Only Step 1)
    if(wizardStep == 1)

      IconButton(
        icon: const Icon(
          Icons.refresh,
          color: Color(0xFF735C00),
        ),

        onPressed: () {

          setState(() {

            products = getInitialProducts();

            productControllers.clear();
            productControllers.add(TextEditingController());

            activeProductIndex = null;
            productSuggestions = [];

          });

        },

      ),

  ],
),

  body: buildStep(),
),


);
}


  Widget buildStep(){

    if(wizardStep == 1){
      return buildProductsStep();
    }

   if(wizardStep == 2){
  return buildCustomerStep();
}

  if(wizardStep == 3){
  return buildReviewStep();
}

    if(wizardStep == 4){
  return buildPaymentStep();
}

    return const SizedBox();
  }
Widget buildProductsStep() {

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          const Text(
            "STEP 01 — Check Availability",
            style: TextStyle(
              fontSize:20,
              fontWeight:FontWeight.w600,
              letterSpacing:2,
            ),
          ),

          const SizedBox(height:20),

          /// PRODUCT FORMS
          ...products.asMap().entries.map((entry){

            int index = entry.key;
            var product = entry.value;

            DateTime? pickup = product["pickupDate"];
            DateTime? drop = product["returnDate"];

            String pickupText = pickup == null
                ? ""
                : "${pickup.day}/${pickup.month}/${pickup.year}";

            String returnText = drop == null
                ? ""
                : "${drop.day}/${drop.month}/${drop.year}";

            return Container(
              margin: const EdgeInsets.only(bottom:25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F2),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                children: [

                  /// PICKUP DATE
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: pickupText),
                    decoration: InputDecoration(
                      labelText: "Pickup Date",
                      filled:true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today,size:18),
                    ),
                    onTap: () async {

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: pickup ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if(pickedDate != null){

                        setState(() {
                          products[index]["pickupDate"] = getFixedPickupTime(pickedDate);
                        });

                      }

                    },
                  ),

                  const SizedBox(height:15),

                  /// RETURN DATE
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: returnText),
                    decoration: InputDecoration(
                      labelText: "Return Date",
                      filled:true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today,size:18),
                    ),
                    onTap: () async {

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: drop ?? DateTime.now().add(const Duration(days:2)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if(pickedDate != null){

                        setState(() {
                         products[index]["returnDate"] = getFixedReturnTime(pickedDate);
                        });

                      }

                    },
                  ),

                  const SizedBox(height:20),

                  /// PRODUCT CODE + QTY
                  Column(
                    children: [

                      Row(
                        children: [

                          Expanded(
                            child: TextField(
                              controller: productControllers[index],
                              decoration: InputDecoration(
                                hintText: "Dress Code",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {

                                setState(() {
                                  activeProductIndex = index;
                                });

                                handleProductChange(index, "productCode", value);

                              },
                            ),
                          ),

                          const SizedBox(width:12),

                          SizedBox(
                            width:100,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Qty",
                                filled:true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value){
                                handleProductChange(index, "quantity", value);
                              },
                            ),
                          ),

                        ],
                      ),

                      /// SUGGESTIONS
                      if (activeProductIndex == index && productSuggestions.isNotEmpty)

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top:6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),

                          child: ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: productSuggestions.map((suggestion){

                              return ListTile(

                                title: Text(
                                  suggestion["productCode"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600
                                  ),
                                ),

                                subtitle: Text(
                                  suggestion["productName"],
                                ),

                                onTap: (){
                                  handleSuggestionClick(index, suggestion);
                                },

                              );

                            }).toList(),
                          ),
                        ),

                    ],
                  ),

                  const SizedBox(height:20),

                  /// PRODUCT CARD
                  buildProductCard(index, product),

                  const SizedBox(height:16),

                  /// BOOKINGS
                  buildBookingsSidebar(product),

                ],
              ),
            );

          }).toList(),

          /// ADD PRODUCT
          GestureDetector(
            onTap: addProductForm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical:14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(Icons.add,color:Color(0xFFD4AF37)),
                  SizedBox(width:8),

                  Text(
                    "Add Product",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w600,
                    ),
                  )

                ],
              ),
            ),
          ),

          const SizedBox(height:30),

          /// CONTINUE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => toggleAvailability1Form(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1C1C),
                padding: const EdgeInsets.symmetric(vertical:18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "CONTINUE TO CUSTOMER DETAILS",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height:80)

        ],
      ),
    ),
  );
}

Widget buildProductCard(int index, var product) {

  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F3F2),
      borderRadius: BorderRadius.circular(18),
    ),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// IMAGE LEFT
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: product["image"] == null || product["image"].toString().isEmpty
              ? Container(
                  width:110,
                  height:160,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_outlined,
                    size:40,
                    color:Colors.grey,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: product["image"],
                  width:110,
                  height:160,
                  fit: BoxFit.cover,

                  placeholder: (context, url) => Container(
                    width:110,
                    height:160,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth:2),
                    ),
                  ),

                  errorWidget: (context, url, error) => Container(
                    width:110,
                    height:160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
        ),

        const SizedBox(width:16),

        /// RIGHT SIDE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// PRODUCT NAME
              if(product["productName"] != null &&
                  product["productName"].toString().isNotEmpty)
                Text(
                  product["productName"],
                  style: const TextStyle(
                    fontSize:14,
                    fontWeight:FontWeight.w600,
                  ),
                ),

              const SizedBox(height:8),

              /// RENT
              const Text(
                "RENT",
                style: TextStyle(
                  fontSize:11,
                  letterSpacing:1,
                  color:Colors.grey,
                ),
              ),

              Text(
                product["price"] == null ||
                        product["price"].toString().isEmpty
                    ? "-"
                    : "₹${product["price"]}",
                style: const TextStyle(
                  fontSize:20,
                  fontWeight:FontWeight.w600,
                ),
              ),

              const SizedBox(height:6),

              /// DEPOSIT
              const Text(
                "DEPOSIT",
                style: TextStyle(
                  fontSize:11,
                  letterSpacing:1,
                  color:Colors.grey,
                ),
              ),

              Text(
                product["deposit"] == null ||
                        product["deposit"].toString().isEmpty
                    ? "-"
                    : "₹${product["deposit"]}",
                style: const TextStyle(
                  fontSize:20,
                  fontWeight:FontWeight.w600,
                ),
              ),

              const SizedBox(height:12),

              /// ⭐ AVAILABILITY BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal:14,
                  vertical:8,
                ),
                decoration: BoxDecoration(
                  color: product["availableQuantity"] == null
                      ? Colors.grey.shade200
                      : (product["availableQuantity"] > 0
                          ? const Color(0xFFEBF7EF)
                          : const Color(0xFFFDECEC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  product["availableQuantity"] == null
                      ? "Check Availability"
                      : "${product["availableQuantity"]} Available",
                  style: TextStyle(
                    fontSize:15,
                    fontWeight:FontWeight.w700,
                    color: product["availableQuantity"] == null
                        ? Colors.black54
                        : (product["availableQuantity"] > 0
                            ? Colors.green
                            : Colors.red),
                  ),
                ),
              ),

              /// 🔴 ERROR MESSAGE (NEW)
              if(product["errorMessage"] != null &&
                 product["errorMessage"].toString().isNotEmpty)

                Padding(
                  padding: const EdgeInsets.only(top:6),
                  child: Text(
                    product["errorMessage"],
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height:12),

              /// ACTION ROW
              Row(
                children: [

                  /// DELETE
                  IconButton(
                    icon: const Icon(Icons.delete_outline,size:20),
                    onPressed: (){
                      setState(() {
                        if(products.length > 1){
                          products.removeAt(index);
                          productControllers.removeAt(index);
                        }
                      });
                    },
                  ),

                  const Spacer(),

                  /// CHECK AVAILABILITY
                  ElevatedButton(
                    onPressed: () async {

                      if(product["productCode"] != null &&
                         product["productCode"].toString().isNotEmpty){

                        await fetchProductDetails(
                          product["productCode"],
                          index,
                        );

                      }

                      await checkAvailability(index);

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal:16,
                        vertical:8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Check",
                      style: TextStyle(
                        fontWeight:FontWeight.w600,
                      ),
                    ),
                  ),

                ],
              ),

            ],
          ),
        ),

      ],
    ),
  );
}
Widget buildPriceBoxPremium(String title, String value) {

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [

        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
  Widget buildPriceBox(title, value){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize:12)),
          const SizedBox(height:5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
Widget buildBookingsSidebar(var product){

  List bookings = product["allBookings"] ?? [];

  return Container(
    margin: const EdgeInsets.only(top:12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            const Text(
              "Existing Bookings",
              style: TextStyle(
                fontSize:15,
                fontWeight:FontWeight.w600,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal:10,
                vertical:4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                bookings.isEmpty ? "NONE" : "LIVE",
                style: const TextStyle(fontSize:11),
              ),
            )

          ],
        ),

        const SizedBox(height:10),

        /// IF NO BOOKINGS
        if(bookings.isEmpty)
          const Text(
            "No bookings found",
            style: TextStyle(
              fontSize:12,
              color:Colors.grey,
            ),
          ),

        /// BOOKINGS LIST
        ...bookings.map((booking){

          DateTime pickup = booking["pickupDate"];
          DateTime drop = booking["returnDate"];

          String date =
              "${pickup.day}/${pickup.month} - ${drop.day}/${drop.month}";

          return Padding(
  padding: const EdgeInsets.only(bottom:6),

  child: InkWell(

    borderRadius: BorderRadius.circular(10),

    onTap: () {

      String branchCode = getBranchCode();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => BookingDetailsProvider(
              branchCode: branchCode,
              receiptNumber: booking["receiptNumber"],
            )..fetchDetails(),
            child: BookingDetailsScreen(
              receiptNumber: booking["receiptNumber"],
              branchCode: branchCode,
            ),
          ),
        ),
      );

    },

    child: buildBookingItemCompact(
      booking["receiptNumber"] ?? "",
      "${booking["quantity"]} QTY",
      date,
      booking["status"] ?? "Booking",
    ),

  ),
);

        }).toList(),

      ],
    ),
  );
}

  Widget buildBookingItemCompact(id, qty, date, status){

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal:10,
      vertical:8,
    ),

    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xFFF6F3F2),
    ),

    child: Row(
      children: [

        /// LEFT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                id,
                style: const TextStyle(
                  fontWeight:FontWeight.w600,
                  fontSize:13,
                ),
              ),

              const SizedBox(height:2),

              Text(
                qty,
                style: const TextStyle(
                  fontSize:11,
                  color:Colors.grey,
                ),
              ),

              Text(
                date,
                style: const TextStyle(
                  fontSize:11,
                  color:Colors.grey,
                ),
              ),

            ],
          ),
        ),

        /// STATUS
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal:10,
            vertical:4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: Text(
            status,
            style: const TextStyle(fontSize:11),
          ),
        )

      ],
    ),
  );
}
Widget buildCustomerStep() {

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "STEP 02 — Customer Details",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height:20),

        buildPremiumCard(
          title: "Customer Details",
          icon: Icons.person_outline,
          child: Column(
            children: [

              TextField(
                decoration: InputDecoration(
                  labelText: "Full Name",
                  hintText: "e.g. Advait Malhotra",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged:(v)=>handleInputChange("name",v),
              ),

              const SizedBox(height:14),

              TextField(
                decoration: InputDecoration(
                  labelText: "Email Address",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged:(v)=>handleInputChange("email",v),
              ),

            ],
          ),
        ),

        const SizedBox(height:16),

          buildPremiumCard(
      title: "Contact Information",
      icon: Icons.phone_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// MOBILE NUMBER
          TextField(
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: "Mobile Number",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              handleInputChange("contact", value);

              if (value.length == 10) {
                fetchCreditNote(value);
              }
            },
          ),

          /// CREDIT BADGE
          if (availableCredit > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.withOpacity(.3),
                ),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "Store Credit Available ₹$availableCredit",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),

                ],
              ),
            ),

          const SizedBox(height:14),

          /// ALTERNATIVE PHONE
          TextField(
            decoration: InputDecoration(
              labelText: "Alternative Phone",
              hintText: "Optional",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged:(v)=>handleInputChange("alternativecontactno",v),
          ),

        ],
      ),
    ),
        const SizedBox(height:16),

        buildPremiumCard(
          title: "Identity Verification",
          icon: Icons.verified_user_outlined,
          child: Column(
            children: [

              DropdownButtonFormField<String>(
                value: userDetails["identityproof"] == "" ? null : userDetails["identityproof"],

                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),

                items: const [

                  DropdownMenuItem(value:"aadharcard",child:Text("Aadhaar Card")),
                  DropdownMenuItem(value:"pancard",child:Text("PAN Card")),
                  DropdownMenuItem(value:"drivinglicence",child:Text("Driving Licence")),
                  DropdownMenuItem(value:"passport",child:Text("Passport")),
                  DropdownMenuItem(value:"college/officeid",child:Text("Office / College ID")),

                ],

                onChanged:(v)=>handleInputChange("identityproof",v),

                decoration: InputDecoration(
                  labelText:"Document Type",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height:14),

              TextField(
                decoration: InputDecoration(
                  labelText:"Identity Number",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged:(v)=>handleInputChange("identitynumber",v),
              ),

            ],
          ),
        ),

        const SizedBox(height:16),

        if(availableCredit > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD4AF37),
                  Color(0xFFB8962E),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "STORE CREDIT AVAILABLE",
                  style: TextStyle(
                    fontSize:12,
                    color:Colors.white70,
                  ),
                ),

                const SizedBox(height:6),

                Text(
                  "₹$availableCredit",
                  style: const TextStyle(
                    fontSize:28,
                    fontWeight:FontWeight.bold,
                    color:Colors.white,
                  ),
                ),

              ],
            ),
          ),

        const SizedBox(height:16),

        buildPremiumCard(
          title: "Lead & Assignment",
          icon: Icons.assignment_outlined,
          child: Column(
            children: [

              DropdownButtonFormField<String>(
                value:userDetails["source"]==""?null:userDetails["source"],
                icon: const Icon(Icons.keyboard_arrow_down_rounded),

                items: const [

                  DropdownMenuItem(value:"google",child:Text("Google")),
                  DropdownMenuItem(value:"instagram",child:Text("Instagram")),
                  DropdownMenuItem(value:"facebook",child:Text("Facebook")),
                  DropdownMenuItem(value:"referal",child:Text("Referral")),
                  DropdownMenuItem(value:"walkin",child:Text("Walk-In")),
                  DropdownMenuItem(value:"repeatcustomer",child:Text("Repeat Customer")),

                ],

                onChanged:(v)=>handleInputChange("source",v),

                decoration: InputDecoration(
                  labelText:"Lead Source",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height:14),

              DropdownButtonFormField<String>(
                value:userDetails["customerby"]==""?null:userDetails["customerby"],

                icon: const Icon(Icons.keyboard_arrow_down_rounded),

                items: subUsers.map<DropdownMenuItem<String>>((user){

                  return DropdownMenuItem<String>(
                    value:user["name"].toString(),
                    child: Text(user["name"].toString()),
                  );

                }).toList(),

                onChanged:(v)=>handleInputChange("customerby",v),

                decoration: InputDecoration(
                  labelText:"Customer By",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height:14),

              DropdownButtonFormField<String>(
                value:userDetails["receiptby"]==""?null:userDetails["receiptby"],

                icon: const Icon(Icons.keyboard_arrow_down_rounded),

                items: subUsers.map<DropdownMenuItem<String>>((user){

                  return DropdownMenuItem<String>(
                    value:user["name"].toString(),
                    child: Text(user["name"].toString()),
                  );

                }).toList(),

                onChanged:(v)=>handleInputChange("receiptby",v),

                decoration: InputDecoration(
                  labelText:"Receipt By",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height:14),

              DropdownButtonFormField<String>(
                value:userDetails["stage"]==""?null:userDetails["stage"],

                icon: const Icon(Icons.keyboard_arrow_down_rounded),

                items: const [
                  DropdownMenuItem(value:"Booking",child:Text("Booking Reserved")),
                  DropdownMenuItem(value:"pickup",child:Text("Dress Pickup")),
                ],

                onChanged:(v)=>handleInputChange("stage",v),

                decoration: InputDecoration(
                  labelText:"Initial Status",
                  filled:true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

            ],
          ),
        ),

        const SizedBox(height:30),

        Row(
          children: [

            Expanded(
              child: ElevatedButton(
                onPressed: (){
                  setState(() {
                    wizardStep = 1;
                  });
                },
                child: const Text("Back"),
              ),
            ),

            const SizedBox(width:12),

            Expanded(
              child: ElevatedButton(
                onPressed: (){

  if(!validateCustomerStep()){
    return;
  }

  handleBookingConfirmation();

},
                child: const Text("Continue to Review"),
              ),
            ),

          ],
        ),

        const SizedBox(height:60),

      ],
    ),
  );
}

Widget buildPremiumCard({
  required String title,
  required IconData icon,
  required Widget child,
}) {

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0,6),
        )
      ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Icon(icon,size:18,color:const Color(0xFF735C00)),

            const SizedBox(width:8),

            Text(
              title,
              style: const TextStyle(
                fontSize:15,
                fontWeight:FontWeight.w600,
              ),
            ),

          ],
        ),

        const SizedBox(height:16),

        child,

      ],
    ),
  );
}
Widget buildReviewStep() {

  List reviewProducts = receipt["products"] ?? [];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "STEP 03 — Review Products",
          style: TextStyle(
            fontSize:20,
            fontWeight:FontWeight.w600,
            letterSpacing:1.5,
          ),
        ),

        const SizedBox(height:20),

        /// PRODUCT LIST
        ...reviewProducts.map((product){

          return Container(
            margin: const EdgeInsets.only(bottom:20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius:16,
                  offset: const Offset(0,6),
                )
              ],
            ),

            child: Column(
              children: [

                /// TOP ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: product["productImageUrl"] ?? "",
                        width:90,
                        height:120,
                        fit: BoxFit.cover,

                        placeholder:(c,u)=>Container(
                          width:90,
                          height:120,
                          color:Colors.grey.shade200,
                        ),

                        errorWidget:(c,u,e)=>Container(
                          width:90,
                          height:120,
                          color:Colors.grey.shade200,
                          child:const Icon(Icons.image),
                        ),
                      ),
                    ),

                    const SizedBox(width:14),

                    /// DETAILS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// TITLE + DELETE BUTTON
                          Row(
                            children: [

                              Expanded(
                                child: Text(
                                  product["productName"] ?? "",
                                  style: const TextStyle(
                                    fontSize:16,
                                    fontWeight:FontWeight.w600,
                                  ),
                                ),
                              ),

                              GestureDetector(
                                onTap: (){
                                  handleDeleteProduct(product["productCode"]);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size:20,
                                  ),
                                ),
                              )

                            ],
                          ),

                          const SizedBox(height:6),

                          Text(
                            "Code: ${product["productCode"]}",
                            style: const TextStyle(
                              color:Colors.grey,
                              fontSize:13,
                            ),
                          ),

                          const SizedBox(height:6),

                          Text(
                            "Qty: ${product["quantity"]}",
                            style: const TextStyle(
                              fontSize:14,
                              fontWeight:FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height:10),

                          /// RENT / DEPOSIT CHIPS
                          Wrap(
                            spacing:10,
                            runSpacing:6,
                            children: [

                              buildPriceChip(
                                "Rent",
                                "₹${product["price"]}",
                              ),

                              buildPriceChip(
                                "Deposit",
                                "₹${product["deposit"]}",
                              ),

                            ],
                          ),

                        ],
                      ),
                    ),

                  ],
                ),

                const SizedBox(height:14),

                /// TOTAL BAR
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal:14,
                    vertical:10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3F2),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Total Rent",
                            style: TextStyle(
                              fontSize:12,
                              color:Colors.grey,
                            ),
                          ),

                          Text(
                            "₹${product["totalPrice"]}",
                            style: const TextStyle(
                              fontSize:16,
                              fontWeight:FontWeight.bold,
                            ),
                          ),

                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          const Text(
                            "Total Deposit",
                            style: TextStyle(
                              fontSize:12,
                              color:Colors.grey,
                            ),
                          ),

                          Text(
                            "₹${product["totaldeposite"]}",
                            style: const TextStyle(
                              fontSize:16,
                              fontWeight:FontWeight.bold,
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),
                )

              ],
            ),
          );

        }).toList(),

        const SizedBox(height:20),

        /// ALTERATIONS
        TextField(
          decoration: InputDecoration(
            labelText:"Alterations / Notes",
            filled:true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged:(v){
            userDetails["alterations"] = v;
          },
        ),

        const SizedBox(height:30),

        /// BUTTONS
        Row(
          children: [

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical:16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: (){
                  setState(() {
                    wizardStep = 2;
                  });
                },
                child: const Text("Back"),
              ),
            ),

            const SizedBox(width:12),

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical:16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              onPressed: (){

  calculateGrandTotals();

  setState(() {
    wizardStep = 4;
  });

},
                child: const Text("Proceed to Payment"),
              ),
            ),

          ],
        ),

        const SizedBox(height:80),

      ],
    ),
  );
}
Widget buildPriceChip(String title,String value){

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal:10,
      vertical:6,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F3F2),
      borderRadius: BorderRadius.circular(8),
    ),

    child: Row(
      children: [

        Text(
          "$title: ",
          style: const TextStyle(
            fontSize:12,
            color:Colors.grey,
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight:FontWeight.w600,
            fontSize:13,
          ),
        ),

      ],
    ),
  );

}
Widget buildPaymentStep() {

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal:20, vertical:10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height:10),

        const Text(
          "STEP 04 — Payment",
          style: TextStyle(
            fontSize:24,
            fontWeight:FontWeight.bold,
            letterSpacing:1.5,
          ),
        ),

        const SizedBox(height:4),

        Text(
          "Finalize the booking payment",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize:14,
          ),
        ),

        const SizedBox(height:24),

        /// GRAND TOTAL CARD
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors:[Color(0xFFD4AF37),Color(0xFFB8962E)]
            ),
          ),

          child: Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Grand Rent",
                      style: TextStyle(color:Colors.white70,fontSize:12),
                    ),

                    const SizedBox(height:4),

                    Text(
                      "₹${userDetails["grandTotalRent"] ?? 0}",
                      style: const TextStyle(
                        color:Colors.white,
                        fontSize:22,
                        fontWeight:FontWeight.bold
                      ),
                    )

                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [

                    const Text(
                      "Grand Deposit",
                      style: TextStyle(color:Colors.white70,fontSize:12),
                    ),

                    const SizedBox(height:4),

                    Text(
                      "₹${userDetails["grandTotalDeposit"] ?? 0}",
                      style: const TextStyle(
                        color:Colors.white,
                        fontSize:22,
                        fontWeight:FontWeight.bold
                      ),
                    )

                  ],
                ),
              ),

            ],
          ),
        ),

        const SizedBox(height:24),

        /// DISCOUNTS
        _premiumInput(
  label: "Discount On Rent",
  keyboardType: TextInputType.number,
  onChanged: (v) {
    setState(() => userDetails["discountOnRent"] = v);
    calculateTotals();
  },
),

        const SizedBox(height:16),

        _premiumInput(
          label:"Discount On Deposit",
            keyboardType: TextInputType.number,
          onChanged:(v){
            setState(()=>userDetails["discountOnDeposit"]=v);
            calculateTotals();
          },
        ),

        const SizedBox(height:24),

        /// FINAL TOTALS
        Row(
          children: [

            Expanded(
              child: _priceHighlight(
                "Final Rent",
                "₹${userDetails["finalrent"] ?? 0}",
                Colors.green,
              ),
            ),

            const SizedBox(width:14),

            Expanded(
              child: _priceHighlight(
                "Final Deposit",
                "₹${userDetails["finaldeposite"] ?? 0}",
                Colors.blue,
              ),
            ),

          ],
        ),

        const SizedBox(height:24),

        /// CREDIT
        if(availableCredit>0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFE8F5E9),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Available Credit"),

                    Text(
                      "₹$availableCredit",
                      style: const TextStyle(
                        fontSize:20,
                        fontWeight:FontWeight.bold,
                        color:Colors.green,
                      ),
                    ),

                  ],
                ),

                ElevatedButton(
                  onPressed: handleApplyCredit,
                  child: const Text("Apply"),
                )

              ],
            ),
          ),

        const SizedBox(height:24),
        if(appliedCredit > 0)
  Container(
    margin: const EdgeInsets.only(top:12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFE3F2FD),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Applied Credit",
              style: TextStyle(
                fontSize:12,
                color:Colors.black54,
              ),
            ),

          ],
        ),

        Text(
          "- ₹$appliedCredit",
          style: const TextStyle(
            fontSize:20,
            fontWeight:FontWeight.bold,
            color:Colors.blue,
          ),
        ),

      ],
    ),
  ),
          const SizedBox(height:24),


        /// TOTAL + BALANCE
        Row(
          children: [

            Expanded(
              child: _priceHighlight(
                "Total Payable",
                "₹${userDetails["totalamounttobepaid"] ?? 0}",
                Colors.orange,
              ),
            ),

            const SizedBox(width:14),

            Expanded(
              child: _priceHighlight(
                "Balance",
                "₹${userDetails["balance"] ?? 0}",
                Colors.red,
              ),
            ),

          ],
        ),

        const SizedBox(height:24),

        /// AMOUNT PAID
        _premiumInput(
  label: "Amount Paid",
  keyboardType: TextInputType.number,
  onChanged: (v) {
    setState(() => userDetails["amountpaid"] = v);
    calculateTotals();
  },
),

        const SizedBox(height:20),

        /// PAYMENT STATUS
        DropdownButtonFormField<String>(
          value:userDetails["paymentstatus"]==""?null:userDetails["paymentstatus"],

          items: const [
            DropdownMenuItem(value:"fullpayment",child:Text("Full Payment")),
            DropdownMenuItem(value:"depositpending",child:Text("Deposit Pending")),
            DropdownMenuItem(value:"partialpayment",child:Text("Partial Payment")),
          ],

          decoration:_dropdownDecoration("Payment Status"),

          onChanged:(v){
            setState(()=>userDetails["paymentstatus"]=v);
          },
        ),

        const SizedBox(height:20),

        /// FIRST PAYMENT MODE
        DropdownButtonFormField<String>(
          value:userDetails["firstpaymentmode"]==""?null:userDetails["firstpaymentmode"],

          items: const [

            DropdownMenuItem(value:"cash",child:Text("Cash")),
            DropdownMenuItem(value:"upi",child:Text("UPI")),
            DropdownMenuItem(value:"card",child:Text("Card")),
            DropdownMenuItem(value:"banktransfer",child:Text("Bank Transfer")),

          ],

          decoration:_dropdownDecoration("First Payment Mode"),

          onChanged:(v){
            setState(()=>userDetails["firstpaymentmode"]=v);
          },
        ),

        const SizedBox(height:16),

        _premiumInput(
          label:"First Payment Details",
          onChanged:(v){
            userDetails["firstpaymentdtails"]=v;
          },
        ),

        const SizedBox(height:20),

        /// SECOND PAYMENT MODE
        DropdownButtonFormField<String>(
          value:userDetails["secondpaymentmode"]==""?null:userDetails["secondpaymentmode"],

          items: const [

            DropdownMenuItem(value:"cash",child:Text("Cash")),
            DropdownMenuItem(value:"upi",child:Text("UPI")),
            DropdownMenuItem(value:"card",child:Text("Card")),
            DropdownMenuItem(value:"banktransfer",child:Text("Bank Transfer")),

          ],

          decoration:_dropdownDecoration("Second Payment Mode"),

          onChanged:(v){
            setState(()=>userDetails["secondpaymentmode"]=v);
          },
        ),

        const SizedBox(height:16),

        _premiumInput(
          label:"Second Payment Details",
          onChanged:(v){
            userDetails["secondpaymentdetails"]=v;
          },
        ),

        const SizedBox(height:20),

        /// SPECIAL NOTE
        _premiumInput(
          label:"Special Notes",
          maxLines:3,
          onChanged:(v){
            setState(()=>userDetails["specialnote"]=v);
          },
        ),

        const SizedBox(height:30),

        /// BUTTONS
        Row(
          children: [

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical:16),
                ),
                onPressed: (){
                  setState(()=>wizardStep=3);
                },
                child: const Text("Back"),
              ),
            ),

            const SizedBox(width:14),

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical:16),
                ),
                onPressed: () {

  calculatePaymentSummary();

  handleConfirmPayment();

},
                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(fontWeight:FontWeight.bold),
                ),
              ),
            ),

          ],
        ),

        const SizedBox(height:80)

      ],
    ),
  );
}
Widget _premiumInput({
  required String label,
  required Function(String) onChanged,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) {

  return TextField(
    maxLines: maxLines,
    keyboardType: keyboardType,

    decoration: InputDecoration(
      labelText: label,

      filled: true,
      fillColor: Colors.grey.shade100,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
    ),

    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),

    onChanged: onChanged,
  );
}

Widget _priceHighlight(String title,String value,Color color){

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: color.withOpacity(.1),
      border: Border.all(color: color.withOpacity(.4))
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: TextStyle(
            fontSize:12,
            color:Colors.grey.shade600
          ),
        ),

        const SizedBox(height:4),

        Text(
          value,
          style: TextStyle(
            fontSize:20,
            fontWeight:FontWeight.bold,
            color:color
          ),
        )

      ],
    ),
  );
}

InputDecoration _dropdownDecoration(String label){

  return InputDecoration(
    labelText:label,
    filled:true,
    fillColor:Colors.grey.shade100,
    border:OutlineInputBorder(
      borderRadius:BorderRadius.circular(14),
      borderSide:BorderSide.none
    ),
  );
}
void addProductForm(){

  setState(() {

    DateTime pickupDate = products[0]["pickupDate"];
    DateTime returnDate = products[0]["returnDate"];

    products.add({
      "pickupDate": pickupDate,
      "returnDate": returnDate,
      "productCode": "",
      "quantity": "",
      "availableQuantity": null,
      "errorMessage": "",
      "price": "",
      "deposit": "",
      "productName": "",
      "allBookings": []
    });

    productControllers.add(TextEditingController());

    activeProductIndex = null;
    productSuggestions = [];

  });

}

  void toggleAvailability1Form(bool fromWizard){

    setState(() {
      wizardStep = 2;
    });
  }
  
void handleProductChange(int index, String name, String value) async {

  setState(() {
    products[index][name] = value;
  });

  if (name == "productCode" && value.trim().isNotEmpty) {

    setState(() {
      activeProductIndex = index;
    });

    await fetchProductSuggestions(value);

  } else {

    setState(() {
      productSuggestions = [];
    });

  }

}
Future<void> fetchProductSuggestions(String searchTerm) async {

  try {

   String branchCode = getBranchCode(); // later from user provider

    var productsRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("products");

    var querySnapshot = await productsRef
        .where("productCode", isGreaterThanOrEqualTo: searchTerm)
        .where("productCode", isLessThanOrEqualTo: searchTerm + "\uf8ff")
        .get();

    List suggestions = [];

    for (var doc in querySnapshot.docs) {

      var data = doc.data();

      if (data["productCode"] != null &&
          data["productCode"]
    .toString()
    .toLowerCase()
    .contains(searchTerm.toLowerCase())) {

        suggestions.add({
          "productCode": data["productCode"],
          "productName": data["productName"] ?? "N/A",
        });

      }

    }

    setState(() {
      productSuggestions = suggestions;
    });

  } catch (e) {

    print("Error fetching product suggestions: $e");

  }

}
void handleSuggestionClick(int index, Map suggestion){

  List newProducts = [...products];

  newProducts[index]["productCode"] = suggestion["productCode"];

  productControllers[index].text = suggestion["productCode"];

  setState(() {

    products = newProducts;
    productSuggestions = [];
    activeProductIndex = null;

  });

  fetchProductDetails(suggestion["productCode"], index);

}
Future<void> fetchProductDetails(String productCode, int index) async {

  try {

    String branchCode = getBranchCode(); // later replace with provider

    /// Firestore reference
    var productRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("products")
        .doc(productCode);

    var productDoc = await productRef.get();

    if (!productDoc.exists) {
      print("Product not found in Firestore");
      return;
    }

    var productData = productDoc.data();

    /// Verify branch
    String productBranchCode = productData?["branchCode"] ?? "";

    if (productBranchCode != branchCode) {
      print("Product does not belong to this branch");
      return;
    }

    /// IMAGE (Firestore already stores full URL)
    String imageUrl = "";

    if (productData?["imageUrls"] != null &&
        productData?["imageUrls"].length > 0) {

      imageUrl = productData?["imageUrls"][0];

    }

    /// PRODUCT DATA
    var price = productData?["price"] ?? "";
    var deposit = productData?["deposit"] ?? "";
    var totalQuantity = productData?["quantity"] ?? 0;
    var priceType = productData?["priceType"] ?? "daily";
    var minimumRentalPeriod = productData?["minimumRentalPeriod"] ?? 1;
    var extraRent = productData?["extraRent"] ?? 0;
    var productName = productData?["productName"] ?? "";

    /// UPDATE STATE
    setState(() {

      products[index]["image"] = imageUrl;
      products[index]["price"] = price;
      products[index]["deposit"] = deposit;
      products[index]["totalQuantity"] = totalQuantity;
      products[index]["priceType"] = priceType;
      products[index]["minimumRentalPeriod"] = minimumRentalPeriod;
      products[index]["extraRent"] = extraRent;
      products[index]["productName"] = productName;

    });

  } catch (e) {

    print("Error fetching product details: $e");

  }

}
  Future<void> checkAvailability(int index) async {

  try {

    var product = products[index];

    String productCode = product["productCode"];
    DateTime pickupDate = product["pickupDate"];
    DateTime returnDate = product["returnDate"];
int quantity = int.tryParse(product["quantity"].toString()) ?? 0;

if (quantity <= 0) {
  setState(() {
    products[index]["errorMessage"] = "Enter quantity first";
    products[index]["availableQuantity"] = null;
  });
  return;
}
    String branchCode = getBranchCode();

    /// Fetch product
    var productRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("products")
        .doc(productCode);

    var productDoc = await productRef.get();

    if (!productDoc.exists) {

      setState(() {
        products[index]["errorMessage"] = "Product not found";
      });

      return;
    }

    var productData = productDoc.data();

    int maxAvailableQuantity = productData?["quantity"] ?? 0;

    /// Fetch bookings
    var bookingsSnapshot = await productRef
        .collection("bookings")
        .get();

    int bookedQuantity = 0;

    List allBookings = [];

    for (var doc in bookingsSnapshot.docs) {

      var bookingData = doc.data();

      Timestamp? pickupTimestamp = bookingData["pickupDate"];
Timestamp? returnTimestamp = bookingData["returnDate"];

if (pickupTimestamp == null || returnTimestamp == null) {
  continue;
}

DateTime bookingPickup = pickupTimestamp.toDate();
DateTime bookingReturn = returnTimestamp.toDate();

      int bookingQty = bookingData["quantity"] ?? 0;

      String status =
          bookingData["userDetails"]?["stage"] ?? "booking";

      /// Store booking for UI
      /// Store booking for UI (hide completed/cancelled bookings)

if (status != "successful" &&
    status != "cancelled" &&
    status != "postponed") {

  allBookings.add({
    "receiptNumber": bookingData["receiptNumber"],
    "pickupDate": bookingPickup,
    "returnDate": bookingReturn,
    "quantity": bookingQty,
    "status": status
  });

}

      /// Ignore these statuses for stock calculation
      if (status == "cancelled" ||
          status == "return" ||
          status == "successful" ||
          status == "postponed") {
        continue;
      }

      /// Check date overlap
      bool overlap =
          bookingPickup.isBefore(returnDate) &&
          bookingReturn.isAfter(pickupDate);

      if (overlap) {

        bookedQuantity += bookingQty;

      }

    }

    /// Calculate available stock
    int availableQuantity = maxAvailableQuantity - bookedQuantity;

    if (availableQuantity < 0) {
      availableQuantity = 0;
    }

    /// Check requested quantity
    if (quantity > availableQuantity) {

      setState(() {

        products[index]["availableQuantity"] = availableQuantity;

        products[index]["errorMessage"] =
            "Only $availableQuantity item(s) available";

        products[index]["allBookings"] = allBookings;

      });

      return;

    }

    /// Success
    setState(() {

      products[index]["availableQuantity"] = availableQuantity;
      products[index]["errorMessage"] = "";
      products[index]["allBookings"] = allBookings;

    });

  } catch (e) {

    print("Error checking availability: $e");

    setState(() {

      products[index]["errorMessage"] =
          "Failed to check availability";

    });

  }

}
void handleInputChange(String name, dynamic value) {

  setState(() {
    userDetails[name] = value;
  });

  /// Same logic as web
  if(name == "contact"){
    fetchCreditNote(value);
  }

}
void calculateTotals() {

  double rent =
      double.tryParse(userDetails["grandTotalRent"].toString()) ?? 0;

  double deposit =
      double.tryParse(userDetails["grandTotalDeposit"].toString()) ?? 0;

  double discountRent =
      double.tryParse(userDetails["discountOnRent"].toString()) ?? 0;

  double discountDeposit =
      double.tryParse(userDetails["discountOnDeposit"].toString()) ?? 0;

  double paid =
      double.tryParse(userDetails["amountpaid"].toString()) ?? 0;

  /// APPLY CREDIT HERE
  double finalRent = rent - discountRent - appliedCredit;
  double finalDeposit = deposit - discountDeposit;

  if (finalRent < 0) finalRent = 0;
  if (finalDeposit < 0) finalDeposit = 0;

  double totalAmount = finalRent + finalDeposit;

  double balance = totalAmount - paid;

  if (balance < 0) balance = 0;

  setState(() {

    userDetails["finalrent"] = finalRent;
    userDetails["finaldeposite"] = finalDeposit;
    userDetails["totalamounttobepaid"] = totalAmount;
    userDetails["balance"] = balance;

  });

}
void calculateGrandTotals() {

  if(receipt["products"] == null) return;

  List reviewProducts = receipt["products"];

  double grandRent = 0;
  double grandDeposit = 0;

  for(var product in reviewProducts){

    grandRent +=
        double.tryParse(product["totalPrice"].toString()) ?? 0;

    grandDeposit +=
        double.tryParse(product["totaldeposite"].toString()) ?? 0;

  }

  setState(() {

    userDetails["grandTotalRent"] = grandRent;
    userDetails["grandTotalDeposit"] = grandDeposit;

  });

  calculateTotals();
}
void handleApplyCredit(){
  if(appliedCredit > 0) return;

  double finalRent =
      double.tryParse(userDetails["finalrent"].toString()) ?? 0;

  if(availableCredit > 0 && finalRent > 0){

    double creditToApply =
        availableCredit > finalRent ? finalRent : availableCredit;

    double updatedRent = finalRent - creditToApply;

    double deposit =
        double.tryParse(userDetails["finaldeposite"].toString()) ?? 0;

    double totalAmount = updatedRent + deposit;

    double paid =
        double.tryParse(userDetails["amountpaid"].toString()) ?? 0;

    double balance = totalAmount - paid;

    setState(() {

      appliedCredit = creditToApply;

      userDetails["finalrent"] = updatedRent;
      userDetails["totalamounttobepaid"] = totalAmount;
      userDetails["balance"] = balance;

    });

  }

}
Future<void> fetchCreditNote(String contactNumber) async {

try {


/// Clean input
contactNumber = contactNumber.trim();

print("📞 Searching credit for mobile: $contactNumber");

String branchCode = getBranchCode();
print("🏢 Branch Code: $branchCode");

var creditRef = FirebaseFirestore.instance
    .collection("products")
    .doc(branchCode)
    .collection("creditNotes");

print("📂 Querying Firestore creditNotes...");

var query = await creditRef
    .where("mobileNumber", isEqualTo: contactNumber)
    .where("status", isEqualTo: "active")
    .get();

print("📊 Documents Found: ${query.docs.length}");

if (query.docs.isNotEmpty) {

  var creditData = query.docs.first.data();
  print("💰 Credit Document Data: $creditData");

  double balance = 0;

  /// Handle int / double safely
  if (creditData["Balance"] != null) {
    balance = double.tryParse(
      creditData["Balance"].toString(),
    ) ?? 0;
  }

  setState(() {
    availableCredit = balance;
    creditNoteId = query.docs.first.id;
  });

  print("✅ Credit Applied: ₹$availableCredit");

} else {

  print("❌ No credit note found for this mobile");

  setState(() {
    availableCredit = 0;
    creditNoteId = null;
  });

}


} catch (e, stackTrace) {


print("🔥 Credit note error: $e");
print(stackTrace);

setState(() {
  availableCredit = 0;
  creditNoteId = null;
});


}

}

Future<void> fetchSubUsers() async {

  try {

    String branchCode = getBranchCode(); // later from auth

    var ref = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("subusers");

    var snapshot = await ref.get();

    setState(() {
      subUsers = snapshot.docs.map((doc){
        return {
          "id": doc.id,
          ...doc.data()
        };
      }).toList();
    });

  } catch(e){
    print("Error fetching subusers: $e");
  }

}
Future<void> handleBookingConfirmation() async {

  try {

    /// 🔴 STEP 0 — SAME VALIDATION LOGIC AS WEB
    bool allQuantitiesAvailable = products.every((product) {

      return product["availableQuantity"] != null &&
          (int.tryParse(product["quantity"].toString()) ?? 0)
              <= product["availableQuantity"];

    });

    if (!allQuantitiesAvailable) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Entered quantities exceed available quantities for one or more products."
          ),
        ),
      );

      return;
    }

    List<Map<String, dynamic>> bookingDetails = [];

    for (var product in products) {

      DateTime pickupDateObj = product["pickupDate"];
      DateTime returnDateObj = product["returnDate"];

      const millisecondsPerDay = 1000 * 60 * 60 * 24;

      int days = ((returnDateObj.millisecondsSinceEpoch -
              pickupDateObj.millisecondsSinceEpoch) /
          millisecondsPerDay)
          .ceil();

      /// 🔥 BRANCH CODE (same as web)
    String branchCode = getBranchCode();// later replace with userData.branchCode

      var productRef = FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("products")
          .doc(product["productCode"]);

      var productDoc = await productRef.get();

      if (!productDoc.exists) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Product ${product["productCode"]} not found")
          ),
        );

        return;
      }

      Map<String, dynamic> productData =
          productDoc.data() as Map<String, dynamic>;

     int price =
    int.tryParse(productData["price"].toString()) ?? 0;

int deposit =
    int.tryParse(productData["deposit"].toString()) ?? 0;

String priceType =
    productData["priceType"]?.toString() ?? "daily";

int minimumRentalPeriod =
    int.tryParse(productData["minimumRentalPeriod"].toString()) ?? 1;

int extraRent =
    int.tryParse(productData["extraRent"].toString()) ?? 0;
      String productName = productData["productName"] ?? "";

      int quantity = int.tryParse(product["quantity"].toString()) ?? 0;

      /// 🔥 SAME calculateTotalPrice FUNCTION AS WEB
      Map<String, dynamic> calculateTotalPrice(
        int price,
        int deposit,
        String priceType,
        int quantity,
        DateTime pickupDate,
        DateTime returnDate,
        int minimumRentalPeriod,
        int extraRent,
      ) {

        const millisecondsPerHour = 1000 * 60 * 60;
        const millisecondsPerDay = 1000 * 60 * 60 * 24;

        int duration = 0;

        if (priceType == "hourly") {

          duration = ((returnDate.millisecondsSinceEpoch -
                  pickupDate.millisecondsSinceEpoch) /
              millisecondsPerHour)
              .ceil();

        } else if (priceType == "monthly") {

          duration = ((returnDate.millisecondsSinceEpoch -
                  pickupDate.millisecondsSinceEpoch) /
              (millisecondsPerDay * 30))
              .ceil();

        } else {

          duration = ((returnDate.millisecondsSinceEpoch -
                  pickupDate.millisecondsSinceEpoch) /
              millisecondsPerDay)
              .ceil();
        }

        int totalPrice = price * quantity;

        if (duration > minimumRentalPeriod) {

          int extraDuration = duration - minimumRentalPeriod;

          totalPrice += extraRent * extraDuration * quantity;
        }

        int totalDeposit = deposit * quantity;

        return {
          "totalPrice": totalPrice,
          "totaldeposite": totalDeposit,
          "grandTotal": totalPrice + totalDeposit
        };
      }

      Map<String, dynamic> totalCost = calculateTotalPrice(
        price,
        deposit,
        priceType,
        quantity,
        pickupDateObj,
        returnDateObj,
        minimumRentalPeriod,
        extraRent,
      );

      /// 🔥 SAME bookingId logic as web
      await getNextBookingId(pickupDateObj, product["productCode"]);

      bookingDetails.add({

        "productCode": product["productCode"],
        "productImageUrl": product["image"] ?? "",
        "productName": productName,
        "price": price,
        "deposit": deposit,
        "quantity": product["quantity"],
        "numDays": days,
        "totalPrice": totalCost["totalPrice"],
        "totaldeposite": totalCost["totaldeposite"],
        "grandTotal": totalCost["grandTotal"]

      });
    }

    /// ✅ STEP 3 — CREATE RECEIPT FIRST
    setState(() {

      receipt = {
        "products": bookingDetails
      };

      /// ✅ STEP 4 — MOVE TO REVIEW STEP
      wizardStep = 3;

    });

  } catch (error) {

    print(error);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "An error occurred while confirming your booking."
        ),
      ),
    );
  }
}
Future<int?> getNextBookingId(DateTime pickupDateObj, String productCode) async {
  try {
    // Check if productCode is valid
    if (productCode.isEmpty) {
      throw Exception('Invalid product code');
    }

    // Fetch branchCode (same as web)
    String branchCode = getBranchCode(); // later replace with userData.branchCode

    // Firestore reference
    var productRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("products")
        .doc(productCode);

    var bookingsRef = productRef.collection("bookings");

    var querySnapshot = await bookingsRef
        .orderBy("pickupDate", descending: false)
        .get();

    List<Map<String, dynamic>> existingBookings = [];

    // Loop through bookings
    for (var doc in querySnapshot.docs) {
      var bookingData = doc.data();

      existingBookings.add({
        "id": doc.id,
        "bookingId": bookingData["bookingId"],
        "pickupDate": (bookingData["pickupDate"] as Timestamp).toDate(),
        "returnDate": (bookingData["returnDate"] as Timestamp).toDate(),
        "quantity": bookingData["quantity"],
      });
    }

    // Calculate next booking ID
    int newBookingId = existingBookings.length + 1;

    for (int i = 0; i < existingBookings.length; i++) {
      DateTime existingPickup = existingBookings[i]["pickupDate"];

      if (pickupDateObj.isBefore(existingPickup)) {
        newBookingId = i + 1;
        break;
      }
    }

    // Batch update existing bookings
    WriteBatch batch = FirebaseFirestore.instance.batch();

    if (newBookingId <= existingBookings.length) {
      for (int i = 0; i < existingBookings.length; i++) {
        if ((i + 1) >= newBookingId) {
          var bookingDocRef = bookingsRef.doc(existingBookings[i]["id"]);

          batch.update(bookingDocRef, {
            "bookingId": i + 2,
          });
        }
      }
    }

    await batch.commit();

    // Return new booking ID
    return newBookingId;
  } catch (error) {
    print("Error getting next booking ID: $error");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to get booking ID. Please try again."),
      ),
    );

    return null;
  }
}
void handleDeleteProduct(String productCode){

  List reviewProducts = receipt["products"];

  reviewProducts.removeWhere(
    (product) => product["productCode"] == productCode
  );

  setState(() {
    receipt["products"] = reviewProducts;
  });

}
Future<void> handleConfirmPayment() async {

  setState(() {
    isButtonDisabled = true;
  });

  try {

    String branchCode = getBranchCode();

    /// GENERATE RECEIPT NUMBER
    String receiptNumber = await generateReceiptNumber(branchCode);

    /// STOCK VALIDATION
    for (var product in products) {

      int availableQuantity =
          int.tryParse(product["availableQuantity"].toString()) ?? 0;

      int requestedQuantity =
          int.tryParse(product["quantity"].toString()) ?? 0;

      if (requestedQuantity > availableQuantity) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Not enough stock for product: ${product["productCode"]}"
            ),
          ),
        );

        setState(() {
          isButtonDisabled = false;
        });

        return;
      }
    }

    /// CREATE BOOKINGS
    for (var product in products) {

      DateTime pickupDateObj = product["pickupDate"];
      DateTime returnDateObj = product["returnDate"];

      var productRef = FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("products")
          .doc(product["productCode"]);

      var productDoc = await productRef.get();

      if (!productDoc.exists) continue;

      var productData = productDoc.data();

int price =
    int.tryParse((productData?["price"] ?? "0").toString()) ?? 0;

int deposit =
    int.tryParse((productData?["deposit"] ?? "0").toString()) ?? 0;

int quantity =
    int.tryParse(product["quantity"].toString()) ?? 0;

      int bookingId =
          await getNextBookingId(pickupDateObj, product["productCode"]) ?? 1;

      await productRef.collection("bookings").add({

        "bookingId": bookingId,
        "receiptNumber": receiptNumber,

        "pickupDate": pickupDateObj,
        "returnDate": returnDateObj,

        "quantity": quantity,

        "branchCode": branchCode,
        "productCode": product["productCode"],

        "userDetails": userDetails,

        "price": price,
        "deposit": deposit,

        "createdAt": FieldValue.serverTimestamp(),

        "appliedCredit": appliedCredit

      });
    }

    /// PAYMENT CALCULATION (same as web)

    int amountPaid =
        int.tryParse(userDetails["amountpaid"].toString()) ?? 0;

    int finalRent =
        int.tryParse(userDetails["finalrent"].toString()) ?? 0;

    int finalDeposit =
        int.tryParse(userDetails["finaldeposite"].toString()) ?? 0;

    int rentCollected = amountPaid >= finalRent ? finalRent : amountPaid;

    int rentPending = finalRent - rentCollected;

    int remainingAfterRent = amountPaid - rentCollected;

    int depositCollected =
        remainingAfterRent > 0
            ? remainingAfterRent.clamp(0, finalDeposit)
            : 0;

    int depositPending = finalDeposit - depositCollected;

    int depositReturned = 0;

    int depositWithYou = depositCollected;

    /// OVERALL DATES

    DateTime overallPickup = products
        .map((p) => p["pickupDate"] as DateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    DateTime overallReturn = products
        .map((p) => p["returnDate"] as DateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    /// PAYMENT DOCUMENT

    var paymentRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments")
        .doc(receiptNumber);

          List reviewProducts = receipt["products"] ?? [];

    await paymentRef.set({

      "receiptNumber": receiptNumber,
      "branchCode": branchCode,

      "clientName": userDetails["name"] ?? "",
      "contact": userDetails["contact"] ?? "",

      "customerBy": userDetails["customerby"] ?? "",
      "receiptBy": userDetails["receiptby"] ?? "",

      "pickupDate": overallPickup,
      "returnDate": overallReturn,

      "grandTotalRent":
          double.tryParse(userDetails["grandTotalRent"].toString()) ?? 0,

      "grandTotalDeposit":
          double.tryParse(userDetails["grandTotalDeposit"].toString()) ?? 0,

      "discountOnRent":
          double.tryParse(userDetails["discountOnRent"].toString()) ?? 0,

      "discountOnDeposit":
          double.tryParse(userDetails["discountOnDeposit"].toString()) ?? 0,

      "finalRent": finalRent,
      "finalDeposit": finalDeposit,

      "totalAmount":
          double.tryParse(userDetails["totalamounttobepaid"].toString()) ?? 0,

      "amountPaid": amountPaid,

      "balance":
          double.tryParse(userDetails["balance"].toString()) ?? 0,

      "paymentStatus": userDetails["paymentstatus"] ?? "pending",

      "firstPaymentMode": userDetails["firstpaymentmode"] ?? "",
      "firstPaymentDetails": userDetails["firstpaymentdtails"] ?? "",

      "secondPaymentMode": userDetails["secondpaymentmode"] ?? "",
      "secondPaymentDetails": userDetails["secondpaymentdetails"] ?? "",

      "appliedCredit": appliedCredit,

      "bookingStage": userDetails["stage"] ?? "Booking",

      "specialNote": userDetails["specialnote"] ?? "",

      "rentCollected": rentCollected,
      "rentPending": rentPending,

      "depositCollected": depositCollected,
      "depositPending": depositPending,

      "depositReturned": depositReturned,
      "depositWithYou": depositWithYou,


"productsSummary": reviewProducts.map((p) => {

  "productCode": p["productCode"],
  "productName": p["productName"] ?? "",
  "quantity": int.tryParse(p["quantity"].toString()) ?? 0,

  "rent": int.tryParse(p["price"].toString()) ?? 0,
  "deposit": int.tryParse(p["deposit"].toString()) ?? 0,

}).toList(),

      "createdAt": FieldValue.serverTimestamp()

    });

    /// CREATE TRANSACTION (tx1 like web)

    if (amountPaid > 0) {

      await paymentRef
          .collection("transactions")
          .doc("tx1")
          .set({

        "amount": amountPaid,
        "mode": userDetails["firstpaymentmode"] ?? "",
        "details": userDetails["firstpaymentdtails"] ?? "",

        "paymentNumber": 1,
        "type": "bookingPayment",

        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": userDetails["receiptby"] ?? "System"

      });

    }

    /// LEDGER ENTRIES

    var ledgerRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("ledger");

    int rentPay = rentCollected;
    int depositPay = depositCollected;

    if (rentPay > 0) {

      await ledgerRef.add({

        "receiptNumber": receiptNumber,
        "customerName": userDetails["name"] ?? "",
        "type": "rentPayment",
        "amount": rentPay,
        "mode": userDetails["firstpaymentmode"] ?? "",
        "details": userDetails["firstpaymentdtails"] ?? "",
        "createdAt": FieldValue.serverTimestamp()

      });
    }

    if (depositPay > 0) {

      await ledgerRef.add({

        "receiptNumber": receiptNumber,
        "customerName": userDetails["name"] ?? "",
        "type": "depositPayment",
        "amount": depositPay,
        "mode": userDetails["firstpaymentmode"] ?? "",
        "details": userDetails["firstpaymentdtails"] ?? "",
        "createdAt": FieldValue.serverTimestamp()

      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Bill Created Successfully. Receipt: $receiptNumber"
        ),
      ),
    );

  } catch (error) {

    print(error);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error confirming payment"),
      ),
    );

  } finally {

    Future.delayed(const Duration(seconds: 10), () {

      if (mounted) {
        setState(() {
          isButtonDisabled = false;
        });
      }

    });

  }
}
void calculatePaymentSummary() {

  double grandRent =
      double.tryParse(userDetails["grandTotalRent"].toString()) ?? 0;

  double grandDeposit =
      double.tryParse(userDetails["grandTotalDeposit"].toString()) ?? 0;

  double discountRent =
      double.tryParse(userDetails["discountOnRent"].toString()) ?? 0;

  double discountDeposit =
      double.tryParse(userDetails["discountOnDeposit"].toString()) ?? 0;

  double finalRent = grandRent - discountRent;
  double finalDeposit = grandDeposit - discountDeposit;

  double totalAmount = finalRent + finalDeposit;

  double amountPaid =
      double.tryParse(userDetails["amountpaid"].toString()) ?? 0;

  double balance = totalAmount - amountPaid;

  userDetails["finalrent"] = finalRent.toInt();
  userDetails["finaldeposite"] = finalDeposit.toInt();
  userDetails["totalamounttobepaid"] = totalAmount.toInt();
  userDetails["balance"] = balance.toInt();

  if (amountPaid == 0) {
    userDetails["paymentstatus"] = "pending";
  } else if (amountPaid < totalAmount) {
    userDetails["paymentstatus"] = "partialpayment";
  } else {
    userDetails["paymentstatus"] = "paid";
  }

  setState(() {});
}

Future<String> generateReceiptNumber(String branchCode) async {

  try {

    /// Firestore path
    var receiptCounterRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("branchCounters")
        .doc("receipt");

    /// Get current counter
    var receiptCounterDoc = await receiptCounterRef.get();

    int receiptNumber = 1;

    if (receiptCounterDoc.exists) {

      var data = receiptCounterDoc.data();

      int currentValue = data?["currentValue"] ?? 0;

      receiptNumber = currentValue + 1;

    }

    /// Update counter in Firestore
    await receiptCounterRef.set({
      "currentValue": receiptNumber
    });

    /// Format receipt number
    String formattedNumber =
        receiptNumber.toString().padLeft(6, '0');

    return "$branchCode-REC-$formattedNumber";

  } catch (e) {

    print("Error generating receipt number: $e");

    return "$branchCode-REC-000001";

  }

}
}