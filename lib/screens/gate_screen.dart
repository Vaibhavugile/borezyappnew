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
  State<GateScreen> createState() =>
      _GateScreenState();
}

class _GateScreenState
    extends State<GateScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      checkRoute();

    });
  }

 Future<void> checkRoute() async {

  try {

    /// SMALL DELAY FOR iOS STARTUP
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    final authUser =
        FirebaseAuth.instance.currentUser;

    /// NOT LOGGED IN
    if (authUser == null) {

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(),
        ),
      );

      return;
    }

    final firestore =
        FirebaseFirestore.instance;

    final userProvider =
        Provider.of<UserProvider>(
      context,
      listen: false,
    );

    /// =====================================
    /// RESTORE USER DATA IF PROVIDER EMPTY
    /// =====================================

    if (userProvider.userData == null) {

      /// CHECK SUPER ADMIN
      /// =====================================
/// CHECK CUSTOMER
/// =====================================

final customerDoc = await firestore
    .collection('customers')
    .where(
      'email',
      isEqualTo: authUser.email,
    )
    .get();

if (customerDoc.docs.isNotEmpty) {

  final data =
      customerDoc.docs.first.data();

  data['role'] = 'customer';

  data['userId'] = authUser.uid;

  userProvider.setUserData(data);

  if (!mounted) return;

  Navigator.pushReplacement(

    context,

    MaterialPageRoute(
      builder: (_) =>
          const MainScreen(),
    ),
  );

  return;
}
      final adminDoc = await firestore
          .collection('superadmins')
          .where(
            'email',
            isEqualTo: authUser.email,
          )
          .get();

      if (adminDoc.docs.isNotEmpty) {

        final data =
            adminDoc.docs.first.data();

        data['role'] = 'admin';
        data['branchCode'] = 'ADMIN';
        data['userId'] = authUser.uid;

        userProvider.setUserData(data);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(),
          ),
        );

        return;
      }

      /// CHECK BRANCH
      final branchDoc = await firestore
          .collection('branches')
          .where(
            'emailId',
            isEqualTo: authUser.email,
          )
          .get();

      if (branchDoc.docs.isNotEmpty) {

        final data =
            branchDoc.docs.first.data();

        data['role'] = 'branch';
        data['userId'] = authUser.uid;

        userProvider.setUserData(data);
      }

      /// CHECK SUBUSER
      else {

        final subDoc = await firestore
            .collection('subusers')
            .where(
              'email',
              isEqualTo: authUser.email,
            )
            .get();

        if (subDoc.docs.isNotEmpty) {

          final data =
              subDoc.docs.first.data();

          data['role'] = 'subuser';
          data['userId'] = authUser.uid;

          userProvider.setUserData(data);
        }
      }
    }

    /// DEBUG
    debugPrint(
      "BranchCode: ${userProvider.branchCode}",
    );
    /// =====================================
/// CUSTOMER USERS SKIP ATTENDANCE
/// =====================================

if (userProvider.userData != null &&
    userProvider.userData!['role'] ==
        'customer') {

  if (!mounted) return;

  Navigator.pushReplacement(

    context,

    MaterialPageRoute(
      builder: (_) =>
          const MainScreen(),
    ),
  );

  return;
}

    String userId = authUser.uid;

    /// TODAY ID
    DateTime now = DateTime.now();

    String todayId =
        "${now.year}-${now.month}-${now.day}";

    /// FIRESTORE TIMEOUT
    var doc = await firestore
        .collection("attendance")
        .doc(userId)
        .collection("logs")
        .doc(todayId)
        .get()
        .timeout(
          const Duration(seconds: 15),
        );

    bool checkedIn = false;

    if (doc.exists) {

      var data = doc.data();

      checkedIn =
          data?["checkInTime"] != null;
    }

    if (!mounted) return;

    /// ROUTING
    if (!checkedIn) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AttendanceScreen(),
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

    debugPrint(
      "GateScreen Error: $e",
    );

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
        child:
            CircularProgressIndicator(),
      ),
    );
  }
}