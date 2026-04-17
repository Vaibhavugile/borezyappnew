import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {

        return Scaffold(

          backgroundColor: const Color(0xFFF4F6FB),

          appBar: AppBar(
            title: const Text("Dashboard"),
            backgroundColor: Colors.white,
            elevation: 0,
          ),

          body: provider.loading
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

                const SizedBox(height:24),

                headerCard(provider),

                const SizedBox(height:26),

                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.1,
                  ),

                  children: [

                    statCard(
                      "Pickup Pending",
                      "${provider.pickupPending} / ${provider.pickupTotal}",
                      Icons.checkroom,
                      const Color(0xFFF59E0B),
                      provider.pickupTotal == 0
                          ? 0
                          : provider.pickupPending /
                          provider.pickupTotal,
                    ),

                    statCard(
                      "Return Pending",
                      "${provider.returnPending} / ${provider.returnTotal}",
                      Icons.assignment_return,
                      const Color(0xFF10B981),
                      provider.returnTotal == 0
                          ? 0
                          : provider.returnPending /
                          provider.returnTotal,
                    ),

                    statCard(
                      "Products Out Today",
                      "${provider.productsOutDone} / ${provider.productsOutToday}",
                      Icons.north_east,
                      const Color(0xFF6366F1),
                      provider.productsOutToday == 0
                          ? 0
                          : provider.productsOutDone /
                          provider.productsOutToday,
                    ),

                    statCard(
                      "Products In Today",
                      "${provider.productsInDone} / ${provider.productsInToday}",
                      Icons.south_west,
                      const Color(0xFF06B6D4),
                      provider.productsInToday == 0
                          ? 0
                          : provider.productsInDone /
                          provider.productsInToday,
                    ),

                    statCard(
                      "Rent Pending",
                      "₹${provider.rentPendingToday.toStringAsFixed(0)}",
                      Icons.payments,
                      const Color(0xFFEF4444),
                      1,
                    ),

                    statCard(
                      "Deposit Pending",
                      "₹${provider.depositPendingToday.toStringAsFixed(0)}",
                      Icons.account_balance_wallet,
                      const Color(0xFF8B5CF6),
                      1,
                    ),

                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget headerCard(DashboardProvider provider){

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

          const Text(
            "Bookings",
            style: TextStyle(
                color: Colors.white70,
                fontSize:14),
          ),

          const SizedBox(height:8),

          Text(
            "${provider.createdCount}",
            style: const TextStyle(
                fontSize:42,
                fontWeight:FontWeight.bold,
                color:Colors.white),
          ),

        ],
      ),
    );
  }

  Widget statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      double progress){

    return Container(

      padding: const EdgeInsets.all(16),

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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,color: color,size:18),
          ),

          const SizedBox(height:10),

          Text(
            value,
            style: const TextStyle(
                fontSize:22,
                fontWeight:FontWeight.bold),
          ),

          const SizedBox(height:4),

          Text(
            title,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize:12),
          ),

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