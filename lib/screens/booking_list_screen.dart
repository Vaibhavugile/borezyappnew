import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import 'booking_details_screen.dart';
import '../providers/booking_details_provider.dart';

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

  List filteredBookings = [];

  String filter = "created";
  String searchText = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    applyFilter();
  }

  void applyFilter(){

    final provider =
        Provider.of<DashboardProvider>(context, listen:false);

    List source = [];

    if(filter == "created") source = provider.createdDocs;
    if(filter == "pickupTotal") source = provider.pickupDocs;

    if(filter == "pickupPending"){
      source = provider.pickupDocs
          .where((d)=>d["bookingStage"]=="pickupPending")
          .toList();
    }

    if(filter == "returnTotal") source = provider.returnDocs;

    if(filter == "returnPending"){
      source = provider.returnDocs
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

    if(mounted){
      setState(() {});
    }
  }
void openWhatsAppTemplates(BuildContext context, String receiptNumber) {

  final dashboardProvider =
      Provider.of<DashboardProvider>(context, listen:false);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => BookingDetailsProvider(
          branchCode: dashboardProvider.branchCode,
          receiptNumber: receiptNumber,
        )..fetchDetails(),
        child: BookingDetailsScreen(
          receiptNumber: receiptNumber,
          branchCode: dashboardProvider.branchCode,
        ),
      ),
    ),
  );

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

 Widget bookingCard(var doc) {

  final provider =
      Provider.of<DashboardProvider>(context, listen:false);

  var data = doc.data();

  String receipt =
      cleanReceipt(data["receiptNumber"] ?? "-");

  String name = data["clientName"] ?? "";

  String stage = data["bookingStage"] ?? "";

  DateTime? pickup =
      data["pickupDate"]?.toDate();

  DateTime? ret =
      data["returnDate"]?.toDate();

  List<Map<String,dynamic>> products =
      List<Map<String,dynamic>>.from(
          provider.receiptProducts[data["receiptNumber"]] ?? []);

  Color stageColor(){

    if(stage == "pickupPending") return const Color(0xFFF59E0B);
    if(stage == "pickedUp") return const Color(0xFF2563EB);
    if(stage == "returnPending") return const Color(0xFF10B981);
    if(stage == "returned") return const Color(0xFF6B7280);

    return Colors.grey;
  }

  return Dismissible(

    key: Key(data["receiptNumber"]),

    confirmDismiss: (direction) async {

      /// SWIPE RIGHT → WHATSAPP
      if(direction == DismissDirection.startToEnd){

        openWhatsAppTemplates(
          context,
          data["receiptNumber"],
        );

        return false;
      }

      /// SWIPE LEFT → OPEN BOOKING
      if(direction == DismissDirection.endToStart){

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => BookingDetailsProvider(
                branchCode: provider.branchCode,
                receiptNumber: data["receiptNumber"],
              ),
              child: BookingDetailsScreen(
                receiptNumber: data["receiptNumber"],
                branchCode: provider.branchCode,
              ),
            ),
          ),
        );

        return false;
      }

      return false;
    },

    /// RIGHT SWIPE BACKGROUND
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal:20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.message,color: Colors.white),
          SizedBox(width:8),
          Text(
            "WhatsApp",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    ),

    /// LEFT SWIPE BACKGROUND
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal:20),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Open",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width:8),
          Icon(Icons.open_in_new,color: Colors.white)
        ],
      ),
    ),

    child: Material(
      color: Colors.transparent,

      child: InkWell(

        borderRadius: BorderRadius.circular(20),

        onTap: (){

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => BookingDetailsProvider(
                  branchCode: provider.branchCode,
                  receiptNumber: data["receiptNumber"],
                ),
                child: BookingDetailsScreen(
                  receiptNumber: data["receiptNumber"],
                  branchCode: provider.branchCode,
                ),
              ),
            ),
          );

        },

        child: Container(

          margin: const EdgeInsets.only(bottom:18),

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0,8),
              )
            ],

          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TOP ROW
              Row(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal:12, vertical:6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      receipt,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:13,
                        color: Color(0xFF735C00),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal:10,
                        vertical:4),
                    decoration: BoxDecoration(
                      color: stageColor().withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(
                        fontSize:11,
                        fontWeight: FontWeight.w600,
                        color: stageColor(),
                      ),
                    ),
                  )

                ],
              ),

              const SizedBox(height:14),

              Text(
                name,
                style: const TextStyle(
                    fontSize:17,
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height:14),

              Row(
                children: [

                  const Icon(
                    Icons.login,
                    size:16,
                    color: Color(0xFF6B7280),
                  ),

                  const SizedBox(width:6),

                  Text(
                    pickup != null
                        ? "${pickup.day}/${pickup.month}/${pickup.year}"
                        : "-",
                    style: const TextStyle(fontSize:13),
                  ),

                  const SizedBox(width:14),

                  const Icon(
                    Icons.arrow_forward,
                    size:16,
                    color: Colors.grey,
                  ),

                  const SizedBox(width:14),

                  const Icon(
                    Icons.logout,
                    size:16,
                    color: Color(0xFF6B7280),
                  ),

                  const SizedBox(width:6),

                  Text(
                    ret != null
                        ? "${ret.day}/${ret.month}/${ret.year}"
                        : "-",
                    style: const TextStyle(fontSize:13),
                  ),

                ],
              ),

              const SizedBox(height:16),

              if(products.isNotEmpty)

                Wrap(
                  spacing:8,
                  runSpacing:8,
                  children: products.map((p){

                    String code = p["productCode"] ?? "-";
                    int qty = p["quantity"] ?? 1;

                    return Container(

                      padding: const EdgeInsets.symmetric(
                          horizontal:12,
                          vertical:6),

                      decoration: BoxDecoration(

                        color: const Color(0xFFF8F6F1),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: const Color(0xFFE5DFC9),
                        ),

                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.inventory_2_outlined,
                            size:14,
                            color: Color(0xFF735C00),
                          ),

                          const SizedBox(width:4),

                          Text(
                            "$code × $qty",
                            style: const TextStyle(
                              fontSize:12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF735C00),
                            ),
                          ),

                        ],
                      ),
                    );

                  }).toList(),
                )

            ],
          ),
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context){

    final provider = Provider.of<DashboardProvider>(context);

    /// Auto refresh list when provider updates
    WidgetsBinding.instance.addPostFrameCallback((_){
      applyFilter();
    });

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
                      initialDate: provider.selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );

                    if(picked != null){
                      provider.changeDate(picked);
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
                          "${provider.selectedDate.day}/${provider.selectedDate.month}/${provider.selectedDate.year}",
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
                  onPressed: provider.refresh,
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

                filterChip("Created","created",
                    provider.createdCount),

                const SizedBox(width:10),

                filterChip("Pickup","pickupTotal",
                    provider.pickupTotal),

                const SizedBox(width:10),

                filterChip("Pickup Pending","pickupPending",
                    provider.pickupPending),

                const SizedBox(width:10),

                filterChip("Return","returnTotal",
                    provider.returnTotal),

                const SizedBox(width:10),

                filterChip("Return Pending","returnPending",
                    provider.returnPending),

              ],
            ),
          ),

          const SizedBox(height:10),

          Expanded(
            child: provider.loading
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