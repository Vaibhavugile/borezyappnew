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
  Map userDetails = {};
  List productSuggestions = [];
  int? activeProductIndex;
  List<TextEditingController> productControllers = [];

  @override
  void initState() {
    super.initState();
    products = getInitialProducts();
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
      return const Center(child: Text("Customer Step"));
    }

    if(wizardStep == 3){
      return const Center(child: Text("Review Step"));
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

              /// ⭐ PREMIUM AVAILABILITY BADGE
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
                        }
                      });
                    },
                  ),

                  const Spacer(),

                  /// CHECK AVAILABILITY
                  ElevatedButton(
                    onPressed: () async {

                      /// ensure product details loaded
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

  });
}

  void toggleAvailability1Form(bool fromWizard){

    setState(() {
      wizardStep = 2;
    });
  }
  
void handleProductChange(int index, String name, String value) async {

  List newProducts = [...products];

  newProducts[index][name] = value;

  if (name == "productCode" && value.trim().isNotEmpty) {

    /// Fetch suggestions from Firebase
    fetchProductSuggestions(value);

  } else {

    /// Clear suggestions
    setState(() {
      productSuggestions = [];
    });

  }

  setState(() {
    products = newProducts;
  });

}
Future<void> fetchProductSuggestions(String searchTerm) async {

  try {

    String branchCode = "7007"; // later from user provider

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

    String branchCode = "7007"; // later replace with provider

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
    int quantity = int.tryParse(product["quantity"] ?? "0") ?? 0;

    String branchCode = "7007";

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

      DateTime bookingPickup =
          (bookingData["pickupDate"] as Timestamp).toDate();

      DateTime bookingReturn =
          (bookingData["returnDate"] as Timestamp).toDate();

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

}