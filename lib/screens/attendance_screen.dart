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

  String getTodayId() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
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

    return Scaffold(

      appBar: AppBar(
        title: const Text("Attendance"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Column(
                children: [

                  const Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: loading ? null : checkLocation,

                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text("Check Location"),

              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: checkIn,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),

                child: const Text("Check In"),

              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: checkOut,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),

                child: const Text("Check Out"),

              ),
            ),

          ],
        ),
      ),

    );

  }
}