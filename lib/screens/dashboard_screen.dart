import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  bool loading = true;

  int todaysBookings = 0;

  int pickupPending = 0;
  int pickupTotal = 0;

  int returnPending = 0;
  int returnTotal = 0;

  int productsOutToday = 0;
  int productsInToday = 0;

  int productsOutDone = 0;
  int productsInDone = 0;

  double rentPendingToday = 0;
  double depositPendingToday = 0;

  DateTime selectedDate = DateTime.now();

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fetchDashboard();
  }

  Future<void> fetchDashboard() async {

    setState(() {
      loading = true;
    });

    String branchCode = "7007";

    DateTime todayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    DateTime tomorrow = todayStart.add(const Duration(days: 1));

    var paymentsRef = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments");

    /// BOOKINGS CREATED
    var todaySnap = await paymentsRef
        .where("createdAt", isGreaterThanOrEqualTo: todayStart)
        .where("createdAt", isLessThan: tomorrow)
        .get();

    int todayCount = 0;

    for (var doc in todaySnap.docs) {
      final data = doc.data();

      if (data["bookingStage"] != "cancelled") {
        todayCount++;
      }
    }

    /// PICKUPS
    var pickupSnap = await paymentsRef
        .where("pickupDate", isGreaterThanOrEqualTo: todayStart)
        .where("pickupDate", isLessThan: tomorrow)
        .get();

    int pickupPendingCount = 0;
    int pickupTotalCount = 0;

    int productsOutTotal = 0;
    int productsOutPending = 0;

    double rentPendingCalc = 0;
    double depositPendingCalc = 0;

    for (var doc in pickupSnap.docs) {

      final data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      pickupTotalCount++;

      if (data["bookingStage"] == "pickupPending") {
        pickupPendingCount++;
      }

      rentPendingCalc += (data["rentPending"] ?? 0).toDouble();
      depositPendingCalc += (data["depositPending"] ?? 0).toDouble();

      String receiptNumber = data["receiptNumber"] ?? "";

      if (receiptNumber.isEmpty) continue;

      var bookings = await FirebaseFirestore.instance
          .collectionGroup("bookings")
          .where("receiptNumber", isEqualTo: receiptNumber)
          .get();

      for (var booking in bookings.docs) {

        final bookingData = booking.data();

        int qty = (bookingData["quantity"] ?? 1).toInt();

        productsOutTotal += qty;

        if (data["bookingStage"] == "pickupPending") {
          productsOutPending += qty;
        }
      }
    }

    /// RETURNS
    var returnSnap = await paymentsRef
        .where("returnDate", isGreaterThanOrEqualTo: todayStart)
        .where("returnDate", isLessThan: tomorrow)
        .get();

    int returnPendingCount = 0;
    int returnTotalCount = 0;

    int productsInTotal = 0;
    int productsInPending = 0;

    for (var doc in returnSnap.docs) {

      final data = doc.data();

      if (data["bookingStage"] == "cancelled") continue;

      returnTotalCount++;

      if (data["bookingStage"] == "returnPending") {
        returnPendingCount++;
      }

      String receiptNumber = data["receiptNumber"] ?? "";

      if (receiptNumber.isEmpty) continue;

      var bookings = await FirebaseFirestore.instance
          .collectionGroup("bookings")
          .where("receiptNumber", isEqualTo: receiptNumber)
          .get();

      for (var booking in bookings.docs) {

        final bookingData = booking.data();

        int qty = (bookingData["quantity"] ?? 1).toInt();

        productsInTotal += qty;

        if (data["bookingStage"] == "returnPending") {
          productsInPending += qty;
        }
      }
    }

    setState(() {

      todaysBookings = todayCount;

      pickupTotal = pickupTotalCount;
      pickupPending = pickupPendingCount;

      returnTotal = returnTotalCount;
      returnPending = returnPendingCount;

      productsOutToday = productsOutTotal;
      productsInToday = productsInTotal;

      productsOutDone = productsOutTotal - productsOutPending;
      productsInDone = productsInTotal - productsInPending;

      rentPendingToday = rentPendingCalc;
      depositPendingToday = depositPendingCalc;

      loading = false;

    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F6FB),

      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(

        padding: const EdgeInsets.fromLTRB(20,20,20,90),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// DATE SELECTOR
            Row(
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

                      setState(() {
                        selectedDate = picked;
                      });

                      fetchDashboard();
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

                        const Icon(Icons.calendar_today,size:16),

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
                  onPressed: fetchDashboard,
                )

              ],
            ),

            const SizedBox(height:24),

            headerCard(),

            const SizedBox(height:26),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 1.1,
              children: [

                statCard("Pickup Pending","$pickupPending / $pickupTotal",
                    Icons.checkroom,const Color(0xFFF59E0B),
                    pickupTotal == 0 ? 0 : pickupPending / pickupTotal),

                statCard("Return Pending","$returnPending / $returnTotal",
                    Icons.assignment_return,const Color(0xFF10B981),
                    returnTotal == 0 ? 0 : returnPending / returnTotal),

                statCard("Products Out Today","$productsOutDone / $productsOutToday",
                    Icons.north_east,const Color(0xFF6366F1),
                    productsOutToday == 0 ? 0 : productsOutDone / productsOutToday),

                statCard("Products In Today","$productsInDone / $productsInToday",
                    Icons.south_west,const Color(0xFF06B6D4),
                    productsInToday == 0 ? 0 : productsInDone / productsInToday),

                statCard("Rent Pending","₹${rentPendingToday.toStringAsFixed(0)}",
                    Icons.payments,const Color(0xFFEF4444),1),

                statCard("Deposit Pending","₹${depositPendingToday.toStringAsFixed(0)}",
                    Icons.account_balance_wallet,const Color(0xFF8B5CF6),1),

              ],
            )
          ],
        ),
      ),
    );
  }

  Widget headerCard(){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text("Bookings",
              style: TextStyle(color: Colors.white70,fontSize:14)),

          const SizedBox(height:8),

          Text("$todaysBookings",
              style: const TextStyle(
                  fontSize:42,
                  fontWeight:FontWeight.bold,
                  color:Colors.white)),
        ],
      ),
    );
  }

  Widget statCard(String title,String value,IconData icon,Color color,double progress){

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0,6),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,color: color,size:18),
          ),

          const SizedBox(height:8),

          Text(value,
              style: const TextStyle(
                  fontSize:22,
                  fontWeight:FontWeight.bold)),

          const SizedBox(height:2),

          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize:12)),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        ],
      ),
    );
  }
}