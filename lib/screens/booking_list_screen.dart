import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {

  final Color gold = const Color(0xFFD4AF37);
  final Color darkGold = const Color(0xFF735C00);
  final Color bg = const Color(0xFFFBF9F8);
  final Color card = const Color(0xFFF6F3F2);

  String branchCode = "7007";

  bool loading = true;

  List createdBookings = [];
  List pickupBookings = [];
  List returnBookings = [];

  List filteredBookings = [];

  String filter = "created";
  String searchText = "";

  DateTime selectedDate = DateTime.now();

  int createdCount = 0;
  int pickupTotalCount = 0;
  int pickupPendingCount = 0;
  int returnTotalCount = 0;
  int returnPendingCount = 0;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {

    loading = true;
    setState(() {});

    DateTime start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    DateTime end = start.add(const Duration(days: 1));

    var paymentsRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments");

    var createdSnap = await paymentsRef
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .get();

    var pickupSnap = await paymentsRef
        .where("pickupDate", isGreaterThanOrEqualTo: start)
        .where("pickupDate", isLessThan: end)
        .get();

    var returnSnap = await paymentsRef
        .where("returnDate", isGreaterThanOrEqualTo: start)
        .where("returnDate", isLessThan: end)
        .get();

    createdBookings = [];
    pickupBookings = [];
    returnBookings = [];

    createdCount = 0;
    pickupTotalCount = 0;
    pickupPendingCount = 0;
    returnTotalCount = 0;
    returnPendingCount = 0;

    for (var doc in createdSnap.docs) {

      final data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      createdBookings.add(doc);
      createdCount++;
    }

    for (var doc in pickupSnap.docs) {

      final data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      pickupBookings.add(doc);
      pickupTotalCount++;

      if (data["bookingStage"] == "pickupPending") {
        pickupPendingCount++;
      }
    }

    for (var doc in returnSnap.docs) {

      final data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      returnBookings.add(doc);
      returnTotalCount++;

      if (data["bookingStage"] == "returnPending") {
        returnPendingCount++;
      }
    }

    applyFilter();

    loading = false;
    setState(() {});
  }

  void applyFilter(){

    List source = [];

    if(filter == "created") source = createdBookings;
    if(filter == "pickupTotal") source = pickupBookings;

    if(filter == "pickupPending"){
      source = pickupBookings
          .where((d)=>d["bookingStage"]=="pickupPending")
          .toList();
    }

    if(filter == "returnTotal") source = returnBookings;

    if(filter == "returnPending"){
      source = returnBookings
          .where((d)=>d["bookingStage"]=="returnPending")
          .toList();
    }

    if(searchText.isEmpty){
      filteredBookings = source;
    } else {

      filteredBookings = source.where((doc){

        var data = doc.data();

        String name =
            (data["clientName"] ?? "").toLowerCase();

        String receipt =
            (data["receiptNumber"] ?? "").toLowerCase();

        return name.contains(searchText) ||
            receipt.contains(searchText);

      }).toList();
    }

    setState(() {});
  }

  String cleanReceipt(String raw){

    List parts = raw.split("-");

    if(parts.length >= 3){
      return "${parts[0]}-${parts[2]}";
    }

    return raw;
  }

  Widget filterChip(String label,String key,int count){

    bool selected = filter == key;

    return GestureDetector(

      onTap: (){
        filter = key;
        applyFilter();
      },

      child: Container(

        padding: const EdgeInsets.symmetric(
            horizontal:18, vertical:10),

        decoration: BoxDecoration(
          color: selected ? gold : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? gold : Colors.grey.shade300,
          ),
        ),

        child: Text(
          "$label ($count)",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget bookingCard(var doc){

    var data = doc.data();

    String receipt =
        cleanReceipt(data["receiptNumber"] ?? "-");

    String name = data["clientName"] ?? "";

    DateTime? pickup =
        (data["pickupDate"] as Timestamp?)?.toDate();

    DateTime? ret =
        (data["returnDate"] as Timestamp?)?.toDate();

    return Container(

      margin: const EdgeInsets.only(bottom:18),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal:12, vertical:6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  receipt,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:14,
                  ),
                ),
              ),

              const Spacer(),

              Text(data["bookingStage"] ?? "")
            ],
          ),

          const SizedBox(height:14),

          Text(name,
              style: const TextStyle(
                  fontSize:17,
                  fontWeight: FontWeight.w600)),

          const SizedBox(height:16),

          Row(
            children: [

              const Icon(Icons.login,size:18,color:Colors.grey),
              const SizedBox(width:6),

              Text(pickup != null
                  ? "${pickup.day}/${pickup.month}/${pickup.year}"
                  : "-"),

              const SizedBox(width:14),

              const Icon(Icons.arrow_forward,size:16),

              const SizedBox(width:14),

              const Icon(Icons.logout,size:18,color:Colors.grey),
              const SizedBox(width:6),

              Text(ret != null
                  ? "${ret.day}/${ret.month}/${ret.year}"
                  : "-"),

            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text("Bookings",
            style: TextStyle(
                color: darkGold,
                fontSize: 24,
                fontWeight: FontWeight.w600)),
      ),

      body: Column(

        children: [

          const SizedBox(height:10),

          /// DATE SELECTOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:20),
            child: Row(
              children: [

                GestureDetector(

                  onTap: () async {

                    DateTime? picked =
                    await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );

                    if(picked != null){

                      selectedDate = picked;

                      fetchBookings();

                    }
                  },

                  child: Container(

                    padding: const EdgeInsets.symmetric(
                        horizontal:16,
                        vertical:10),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.grey.shade300),
                    ),

                    child: Row(
                      children: [

                        const Icon(Icons.calendar_today,
                            size:16),

                        const SizedBox(width:8),

                        Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),

                      ],
                    ),
                  ),
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: fetchBookings,
                )

              ],
            ),
          ),

          const SizedBox(height:16),

          /// SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:20),
            child: TextField(

              onChanged: (v){
                searchText = v.toLowerCase();
                applyFilter();
              },

              decoration: InputDecoration(
                hintText: "Search receipt or customer",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height:16),

          /// FILTERS
          SizedBox(
            height:45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal:20),
              children: [

                filterChip("Created","created",createdCount),
                const SizedBox(width:10),

                filterChip("Pickup","pickupTotal",
                    pickupTotalCount),
                const SizedBox(width:10),

                filterChip("Pickup Pending",
                    "pickupPending",
                    pickupPendingCount),

                const SizedBox(width:10),

                filterChip("Return","returnTotal",
                    returnTotalCount),

                const SizedBox(width:10),

                filterChip("Return Pending",
                    "returnPending",
                    returnPendingCount),

              ],
            ),
          ),

          const SizedBox(height:10),

          Expanded(
            child: loading
                ? const Center(
                child: CircularProgressIndicator())
                : ListView.builder(

                padding:
                const EdgeInsets.all(20),

                itemCount:
                filteredBookings.length,

                itemBuilder:(context,index){

                  return bookingCard(
                      filteredBookings[index]);
                }),
          )

        ],
      ),
    );
  }
}