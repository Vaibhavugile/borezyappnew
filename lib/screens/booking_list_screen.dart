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

  List allBookings = [];
  List filteredBookings = [];

  String filter = "today";

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {

    setState(() {
      loading = true;
    });

    var snap = await FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments")
        .orderBy("createdAt", descending: true)
        .limit(100)
        .get();

    allBookings = snap.docs;

    applyFilter();

    setState(() {
      loading = false;
    });
  }

  void applyFilter() {

    DateTime start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    DateTime end = start.add(const Duration(days: 1));

    filteredBookings = allBookings.where((doc) {

      var data = doc.data();

      DateTime? created = (data["createdAt"] as Timestamp?)?.toDate();
      DateTime? pickup = (data["pickupDate"] as Timestamp?)?.toDate();
      DateTime? ret = (data["returnDate"] as Timestamp?)?.toDate();

      String stage = data["bookingStage"] ?? "";

      if(filter == "today"){
        return created != null &&
            created.isAfter(start) &&
            created.isBefore(end);
      }

      if(filter == "pickupPending"){
        return stage == "pickupPending";
      }

      if(filter == "returnPending"){
        return stage == "returnPending";
      }

      if(filter == "pickedToday"){
        return pickup != null &&
            pickup.isAfter(start) &&
            pickup.isBefore(end) &&
            stage == "pickup";
      }

      if(filter == "returnedToday"){
        return ret != null &&
            ret.isAfter(start) &&
            ret.isBefore(end) &&
            stage == "return";
      }

      return true;

    }).toList();

    setState(() {});
  }

  Widget filterChip(String label,String key){

    bool selected = filter == key;

    return GestureDetector(

      onTap: (){
        setState(() {
          filter = key;
        });
        applyFilter();
      },

      child: Container(

        padding: const EdgeInsets.symmetric(
          horizontal:18,
          vertical:10,
        ),

        decoration: BoxDecoration(

          color: selected ? gold : Colors.white,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: selected ? gold : Colors.grey.shade300,
          ),

        ),

        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget stageBadge(String stage){

    Color color = Colors.grey;

    if(stage == "pickupPending") color = Colors.orange;
    if(stage == "returnPending") color = Colors.blue;
    if(stage == "pickup") color = Colors.green;
    if(stage == "return") color = Colors.purple;

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal:12,
        vertical:6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        stage,
        style: TextStyle(
          fontSize:12,
          fontWeight:FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget bookingCard(var doc){

    var data = doc.data();

    String receipt = data["receiptNumber"] ?? "-";
    String name = data["clientName"] ?? "";
    String stage = data["bookingStage"] ?? "";

    DateTime? pickup =
        (data["pickupDate"] as Timestamp?)?.toDate();

    DateTime? ret =
        (data["returnDate"] as Timestamp?)?.toDate();

    return Container(

      margin: const EdgeInsets.only(bottom:18),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Expanded(
                child: Text(
                  "Receipt #$receipt",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:17,
                  ),
                ),
              ),

              stageBadge(stage)

            ],
          ),

          const SizedBox(height:8),

          Text(
            name,
            style: const TextStyle(
              color: Colors.grey,
              fontSize:14,
            ),
          ),

          const SizedBox(height:12),

          Row(
            children: [

              const Icon(Icons.login,size:16,color:Colors.grey),
              const SizedBox(width:6),

              Text(
                pickup != null
                    ? "${pickup.day}/${pickup.month}/${pickup.year}"
                    : "-",
              ),

              const SizedBox(width:20),

              const Icon(Icons.logout,size:16,color:Colors.grey),
              const SizedBox(width:6),

              Text(
                ret != null
                    ? "${ret.day}/${ret.month}/${ret.year}"
                    : "-",
              ),

            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: bg,

      appBar: AppBar(

        backgroundColor: bg,
        elevation: 0,

        title: Text(
          "Bookings",
          style: TextStyle(
            color: darkGold,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),

      ),

      body: Column(

        children: [

          const SizedBox(height:10),

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
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );

                    if(picked != null){

                      setState(() {
                        selectedDate = picked;
                      });

                      applyFilter();
                    }
                  },

                  child: Container(

                    padding: const EdgeInsets.symmetric(
                      horizontal:16,
                      vertical:10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Row(
                      children: [

                        const Icon(Icons.calendar_today,size:16),

                        const SizedBox(width:8),

                        Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )
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

          SizedBox(

            height:45,

            child: ListView(

              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal:20),

              children: [

                filterChip("Today","today"),
                const SizedBox(width:10),

                filterChip("Pickup Pending","pickupPending"),
                const SizedBox(width:10),

                filterChip("Return Pending","returnPending"),
                const SizedBox(width:10),

                filterChip("Picked Today","pickedToday"),
                const SizedBox(width:10),

                filterChip("Returned Today","returnedToday"),

              ],
            ),
          ),

          const SizedBox(height:10),

          Expanded(

            child: loading

                ? const Center(child: CircularProgressIndicator())

                : RefreshIndicator(

                    onRefresh: fetchBookings,

                    child: ListView.builder(

                      padding: const EdgeInsets.all(20),

                      itemCount: filteredBookings.length,

                      itemBuilder: (context,index){

                        return bookingCard(filteredBookings[index]);
                      },

                    ),
                  ),
          )

        ],
      ),
    );
  }
}