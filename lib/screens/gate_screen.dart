import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'attendance_screen.dart';
import 'main_screen.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {

  @override
  void initState() {
    super.initState();

    /// wait for first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkRoute();
    });
  }

  Future<void> checkRoute() async {
    try {

      final authUser = FirebaseAuth.instance.currentUser;

      /// NOT LOGGED IN
      if (authUser == null) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;

      /// GET USER FROM PROVIDER (set during login)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;

      /// USER NOT FOUND IN PROVIDER
      if (userData == null) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      }

      String userId = authUser.uid;

      /// CHECK TODAY ATTENDANCE
      DateTime now = DateTime.now();
      String todayId = "${now.year}-${now.month}-${now.day}";

      var doc = await firestore
          .collection("attendance")
          .doc(userId)
          .collection("logs")
          .doc(todayId)
          .get();

      bool checkedIn = false;

      if (doc.exists) {
        var data = doc.data();
        checkedIn = data?["checkInTime"] != null;
      }

      if (!mounted) return;

      /// ROUTING
      if (!checkedIn) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendanceScreen(),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(),
          ),
        );

      }

    } catch (e) {

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );

  }
}