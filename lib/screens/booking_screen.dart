import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {

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
 @override
void initState() {
  super.initState();
  products = getInitialProducts();
  fetchSubUsers();
}

  List getInitialProducts() {

  DateTime pickupDate = DateTime.now();
  DateTime returnDate = pickupDate.add(const Duration(days: 2));

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

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        title: const Text(
          "Digital Atelier",
          style: TextStyle(
            color: Color(0xFF735C00),
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),

      body: buildStep(),
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
      return const Center(child: Text("Payment Step"));
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
                          products[index]["pickupDate"] = pickedDate;
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
                          products[index]["returnDate"] = pickedDate;
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
            child: buildBookingItemCompact(
              booking["receiptNumber"] ?? "",
              "${booking["quantity"]} QTY",
              date,
              booking["status"] ?? "Booking",
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
            children: [

              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged:(v)=>handleInputChange("contact",v),
              ),

              const SizedBox(height:14),

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

    String branchCode = "222"; // later from user provider

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

    String branchCode = "222"; // later replace with provider

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
    String branchCode = "222";

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
      if (status != "successful") {

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
Future<void> fetchCreditNote(String contactNumber) async {

  try{

    String branchCode = "222"; // later from provider

    var creditRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("creditNotes");

    var query = await creditRef
        .where("mobileNumber", isEqualTo: contactNumber)
        .where("status", isEqualTo: "active")
        .get();

    if(query.docs.isNotEmpty){

      var creditData = query.docs.first.data();

      setState(() {
        availableCredit = creditData["Balance"] ?? 0;
        creditNoteId = query.docs.first.id;
      });

    }

  }catch(e){
    print("Credit note error $e");
  }

}
Future<void> fetchSubUsers() async {

  try {

    String branchCode = "222"; // later from auth

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
              "Entered quantities exceed available quantities for one or more products."),
        ),
      );

      return;
    }

    List bookingDetails = [];

    for (var product in products) {

      DateTime pickupDateObj = product["pickupDate"];
      DateTime returnDateObj = product["returnDate"];

      const millisecondsPerDay = 1000 * 60 * 60 * 24;

      int days = ((returnDateObj.millisecondsSinceEpoch -
              pickupDateObj.millisecondsSinceEpoch) /
          millisecondsPerDay)
          .ceil();

      String branchCode = "222"; // later use userData.branchCode

      var productRef = FirebaseFirestore.instance
          .collection("products")
          .doc(branchCode)
          .collection("products")
          .doc(product["productCode"]);

      var productDoc = await productRef.get();

      if (!productDoc.exists) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Product ${product["productCode"]} not found")),
        );

        return;
      }

      var productData = productDoc.data();

      int price = productData?["price"] ?? 0;
      int deposit = productData?["deposit"] ?? 0;
      String priceType = productData?["priceType"] ?? "daily";
      int minimumRentalPeriod = productData?["minimumRentalPeriod"] ?? 1;
      int extraRent = productData?["extraRent"] ?? 0;
      String productName = productData?["productName"] ?? "";

      int quantity = int.tryParse(product["quantity"].toString()) ?? 0;

      /// 🔥 SAME calculateTotalPrice FUNCTION AS WEB
      Map calculateTotalPrice(
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

        int totaldeposite = deposit * quantity;

        return {
          "totalPrice": totalPrice,
          "totaldeposite": totaldeposite,
          "grandTotal": totalPrice + totaldeposite
        };
      }

      Map totalCost = calculateTotalPrice(
        price,
        deposit,
        priceType,
        quantity,
        pickupDateObj,
        returnDateObj,
        minimumRentalPeriod,
        extraRent,
      );

      /// SAME bookingId generation as web
      await getNextBookingId(pickupDateObj, product["productCode"]);

      bookingDetails.add({

        "productCode": product["productCode"],
        "productImageUrl": product["image"],
        "productName": productName,
        "price": price,
        "deposit": deposit,
        "quantity": quantity,
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
        content: Text("An error occurred while confirming your booking."),
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
    String branchCode = "222"; // later replace with userData.branchCode

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

}