import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_device/safe_device.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {

  bool loading = false;
  String message = "Press check location";

  double? distance;
  double? userLat;
  double? userLng;
String status = "Loading";
String? checkInTime;
String? checkOutTime;
  String getTodayId() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
  Future<void> loadTodayAttendance() async {

  final userProvider =
      Provider.of<UserProvider>(context, listen: false);

  String userId = userProvider.userId ?? "";

  String todayId = getTodayId();

  var doc = await FirebaseFirestore.instance
      .collection("attendance")
      .doc(userId)
      .collection("logs")
      .doc(todayId)
      .get();

  if (!doc.exists) {
    setState(() {
      status = "Not Checked In";
      checkInTime = null;
      checkOutTime = null;
    });
    return;
  }

  var data = doc.data();

  Timestamp? checkIn = data?["checkInTime"];
  Timestamp? checkOut = data?["checkOutTime"];

  if (checkIn != null) {
    checkInTime =
        TimeOfDay.fromDateTime(checkIn.toDate()).format(context);
  }

  if (checkOut != null) {
    checkOutTime =
        TimeOfDay.fromDateTime(checkOut.toDate()).format(context);
  }

  if (checkIn != null && checkOut == null) {
    status = "Checked In";
  } else if (checkIn != null && checkOut != null) {
    status = "Completed";
  }

  setState(() {});
}

  /// CHECK LOCATION
  Future<void> checkLocation() async {

  setState(() {
    loading = true;
    message = "Checking location...";
  });

  try {

    final userProvider =
        Provider.of<UserProvider>(context, listen: false);

    String branchCode = userProvider.branchCode ?? "";

    var branchQuery = await FirebaseFirestore.instance
        .collection("branches")
        .where("branchCode", isEqualTo: branchCode)
        .get();

    if (branchQuery.docs.isEmpty) {

      setState(() {
        message = "Branch not found";
        loading = false;
      });

      return;
    }

    var branchData = branchQuery.docs.first.data();

    double branchLat = branchData["lat"];
    double branchLng = branchData["lng"];
    double radius = branchData["attendanceRadius"];

    /// LOCATION PERMISSION
    LocationPermission permission =
        await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {

      setState(() {
        message = "Location permission denied";
        loading = false;
      });

      return;
    }

    /// CHECK MOCK LOCATION APPS (Developer Options)
    bool isMockLocation = await SafeDevice.isMockLocation;

    if (isMockLocation) {
      setState(() {
        message = "Mock location app detected. Disable fake GPS.";
        loading = false;
      });
      return;
    }

    /// GET CURRENT LOCATION
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    /// CHECK IF LOCATION IS FAKE
    if (position.isMocked) {
      setState(() {
        message = "Fake GPS detected. Attendance blocked.";
        loading = false;
      });
      return;
    }

    /// CHECK LOCATION ACCURACY
    if (position.accuracy > 50) {
      setState(() {
        message = "Low GPS accuracy. Move outside and try again.";
        loading = false;
      });
      return;
    }

    userLat = position.latitude;
    userLng = position.longitude;

    /// CALCULATE DISTANCE
    distance = Geolocator.distanceBetween(
      branchLat,
      branchLng,
      userLat!,
      userLng!,
    );

    if (distance! > radius) {

      setState(() {
        message =
            "Outside office range\nDistance: ${distance!.toStringAsFixed(1)} m";
      });

    } else {

      setState(() {
        message =
            "Inside office ✔\nDistance: ${distance!.toStringAsFixed(1)} m";
      });

    }

  } catch (e) {

    setState(() {
      message = "Error: $e";
    });

  }

  setState(() {
    loading = false;
  });

}
Future<File?> captureSelfie() async {

  final picker = ImagePicker();

  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 60,
  );

  if(photo == null) return null;

  return File(photo.path);
}
Future<String> uploadSelfie(File image, String userId) async {

  final ref = FirebaseStorage.instance
      .ref()
      .child("attendance_selfies")
      .child("$userId-${DateTime.now().millisecondsSinceEpoch}.jpg");

  await ref.putFile(image);

  return await ref.getDownloadURL();
}
  /// CHECK IN
Future<void> checkIn() async {

  if(distance == null){

    setState(() {
      message = "Please check location first";
    });

    return;
  }

  final userProvider =
      Provider.of<UserProvider>(context, listen:false);

  String userName = userProvider.userName ?? "Unknown";
  String branchCode = userProvider.branchCode ?? "";
  String userId = userProvider.userId ?? "";

  String todayId = getTodayId();

  var docRef = FirebaseFirestore.instance
      .collection("attendance")
      .doc(userId)
      .collection("logs")
      .doc(todayId);

  var doc = await docRef.get();

  if(doc.exists){

    setState(() {
      message = "You already checked in today";
    });

    return;
  }

  /// 1️⃣ OPEN CAMERA
  File? selfie = await captureSelfie();

  if(selfie == null){
    setState(() {
      message = "Selfie required for attendance";
    });
    return;
  }

  /// 2️⃣ UPLOAD IMAGE
  String imageUrl = await uploadSelfie(selfie, userId);

  /// 3️⃣ SAVE ATTENDANCE
  await docRef.set({

    "userName": userName,
    "userId": userId,
    "branchCode": branchCode,

    "checkInTime": FieldValue.serverTimestamp(),

    "lat": userLat,
    "lng": userLng,

    "distance": distance,

    "selfieUrl": imageUrl

  });

  setState(() {
    message = "Check-In Successful ✔";
  });

}
Future<void> checkOut() async {

  if(distance == null){

    setState(() {
      message = "Please check location first";
    });

    return;
  }

  final userProvider =
      Provider.of<UserProvider>(context, listen:false);

  String userId = userProvider.userId ?? "";

  String todayId = getTodayId();

  var docRef = FirebaseFirestore.instance
      .collection("attendance")
      .doc(userId)
      .collection("logs")
      .doc(todayId);

  var doc = await docRef.get();

  /// NOT CHECKED IN
  if(!doc.exists){

    setState(() {
      message = "You must check in first";
    });

    return;
  }

  /// ALREADY CHECKED OUT
  if(doc.data()?["checkOutTime"] != null){

    setState(() {
      message = "You already checked out";
    });

    return;
  }

  /// 1️⃣ CAPTURE SELFIE
  File? selfie = await captureSelfie();

  if(selfie == null){

    setState(() {
      message = "Selfie required for check-out";
    });

    return;
  }

  /// 2️⃣ UPLOAD IMAGE
  String imageUrl = await uploadSelfie(selfie, userId);

  /// 3️⃣ UPDATE ATTENDANCE
  await docRef.update({

    "checkOutTime": FieldValue.serverTimestamp(),

    "checkOutSelfie": imageUrl,

    "checkOutLat": userLat,
    "checkOutLng": userLng

  });

  setState(() {
    message = "Check-Out Successful ✔";
  });

}

  @override
Widget build(BuildContext context) {

  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: const Color(0xFFF4F6FA),

    body: SafeArea(
      child: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF6366F1),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),

            child: Column(
              children: [

                const SizedBox(height: 10),

                const Text(
                  "Attendance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  DateTime.now().toString().split(" ")[0],
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Column(
              children: [

                /// STATUS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 12,
                      )
                    ],
                  ),

                  child: Column(
                    children: [

                      Icon(
                        Icons.location_on,
                        color: theme.primaryColor,
                        size: 40,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Location Status",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),

                      if(distance != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Distance: ${distance!.toStringAsFixed(1)} m",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        )
                      ]

                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// CHECK IN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(

                    onPressed: loading ? null : () async {

                      await checkLocation();

                      if(distance != null &&
                          message.contains("Inside office")){

                        await checkIn();

                      }

                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CHECK IN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                /// CHECK OUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(

                    onPressed: loading ? null : () async {

                      await checkLocation();

                      if(distance != null &&
                          message.contains("Inside office")){

                        await checkOut();

                      }

                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CHECK OUT",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "Location verification required for attendance",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

              ],
            ),
          )

        ],
      ),
    ),
  );
}
}