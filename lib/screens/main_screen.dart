import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'booking_screen.dart';
import 'booking_list_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int currentIndex = 0;

  final List pages = [
    const DashboardScreen(),
    const Booking(),
    const BookingListScreen(),
    const Placeholder(),
    const Placeholder(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFFD4AF37),

        unselectedItemColor: Colors.grey,

        onTap: (index){
          setState(() {
            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Bookings",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            label: "Products",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Customers",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Reports",
          ),

        ],
      ),
    );
  }
}