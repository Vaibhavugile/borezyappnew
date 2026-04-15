import 'package:flutter/material.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {

  int wizardStep = 1;
  List products = [];
  Map userDetails = {};

  @override
  void initState() {
    super.initState();
    products = getInitialProducts();
  }

  List getInitialProducts() {

    DateTime pickupDate = DateTime.now();
    DateTime returnDate = pickupDate.add(const Duration(days: 2));

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

  var product = products.isNotEmpty ? products[0] : {};

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          const SizedBox(height:10),

          const Text(
            "STEP 01 — Check Availability",
            style: TextStyle(
              fontSize:20,
             fontWeight:FontWeight.w600,

              letterSpacing:2,
            ),
          ),

          const SizedBox(height:10),

          


          /// DATE + PRODUCT INPUT CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [

                /// PICKUP DATE
                TextField(
                  decoration: InputDecoration(
                    labelText: "Pickup Date & Time",
                    filled:true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height:15),

                /// RETURN DATE
                TextField(
                  decoration: InputDecoration(
                    labelText: "Return Date & Time",
                    filled:true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height:20),

                /// DRESS CODE + QTY
                Row(
                  children: [

                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Dress Code",
                          filled:true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value){
                          handleProductChange(0, value);
                        },
                      ),
                    ),

                    const SizedBox(width:12),

                    SizedBox(
                      width:110,
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
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height:30),

          /// PRODUCT PREVIEW CARD
          ...products.asMap().entries.map((entry){

            int index = entry.key;
            var product = entry.value;

            return buildProductCard(index, product);

          }).toList(),

          const SizedBox(height:20),

          /// EXISTING BOOKINGS
          buildBookingsSidebar(),

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
          child: Image.network(
            product["image"] ??
            "https://firebasestorage.googleapis.com/v0/b/renting-wala-27d06.appspot.com/o/products%2FWhatsApp%20Image%202025-02-15%20at%2016.56.04.jpeg?alt=media&token=2e329fbe-daa1-478a-b3c4-2e8bc71f0a81",
            width: 110,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(width:16),

        /// RIGHT SIDE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

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
                "₹${(product["price"] == null || product["price"].toString().isEmpty) ? "4500" : product["price"]}",
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
                "₹${(product["deposit"] == null || product["deposit"].toString().isEmpty) ? "200" : product["deposit"]}",
                style: const TextStyle(
                  fontSize:20,
                  fontWeight:FontWeight.w600,
                ),
              ),

              const SizedBox(height:10),

              /// AVAILABILITY
              Row(
                children: [
                  const Icon(Icons.circle,size:8,color:Colors.green),
                  const SizedBox(width:6),
                  Text(
                    "${product["stock"] ?? "8"} Available",
                    style: const TextStyle(
                      fontSize:13,
                      fontWeight:FontWeight.w500,
                    ),
                  ),
                ],
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
                        products.removeAt(index);
                      });
                    },
                  ),

                  const Spacer(),

                  /// CHECK AVAILABILITY
                  ElevatedButton(
                    onPressed: (){
                      checkAvailability(index);
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

  Widget buildBookingsSidebar(){

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Existing Bookings",
                style: TextStyle(
                  fontSize:18,
                  fontWeight:FontWeight.bold,
                ),
              ),
              Chip(label: Text("LIVE"))
            ],
          ),

          const SizedBox(height:15),

          buildBookingItem("RCT-29402","1 QTY • SIZE M","Nov 12 - Nov 15","Confirmed"),

          const SizedBox(height:10),

          buildBookingItem("RCT-29511","2 QTY • SIZE S,L","Dec 01 - Dec 04","Pending"),

        ],
      ),
    );
  }

  Widget buildBookingItem(id, qty, date, status){

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Chip(label: Text(status))
            ],
          ),

          const SizedBox(height:6),

          Text(qty, style: const TextStyle(fontSize:12)),

          const SizedBox(height:4),

          Text(date, style: const TextStyle(fontSize:11,color:Colors.grey))

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

    });
  }

  void toggleAvailability1Form(bool fromWizard){

    setState(() {
      wizardStep = 2;
    });
  }

  void handleProductChange(int index, value){

    setState(() {
      products[index]["productCode"] = value;
    });
  }

  void checkAvailability(int index){

    print("Checking availability for product index: $index");
  }

}