import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_device/safe_device.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'main_screen.dart';

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

@override
void initState() {
super.initState();
loadTodayAttendance();
}


bool get canCheckIn {
  return status == "Not Checked In";
}

bool get canCheckOut {
  return status == "Checked In";
}

Future<void> loadTodayAttendance() async {

  final userProvider =
      Provider.of<UserProvider>(context, listen: false);

  String? userId = userProvider.userId;

  if (userId == null || userId.isEmpty) {
    return;
  }

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

/// MONTHLY ATTENDANCE STREAM
Stream<QuerySnapshot>? monthlyAttendance() {

  final userProvider =
      Provider.of<UserProvider>(context, listen: false);

  String? userId = userProvider.userId;

  if (userId == null || userId.isEmpty) {
    return null;
  }

  DateTime now = DateTime.now();
  DateTime start = DateTime(now.year, now.month, 1);
  DateTime end = DateTime(now.year, now.month + 1, 0);

  return FirebaseFirestore.instance
      .collection("attendance")
      .doc(userId)
      .collection("logs")
      .where(
        "checkInTime",
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      )
      .where(
        "checkInTime",
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      )
      .orderBy("checkInTime", descending: true)
      .snapshots();
}

/// CAMERA
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

  var branchData = branchQuery.docs.first.data();

  double branchLat = branchData["lat"];
  double branchLng = branchData["lng"];
  double radius = branchData["attendanceRadius"];

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

  bool isMockLocation = await SafeDevice.isMockLocation;

  if (isMockLocation) {
    setState(() {
      message = "Mock location detected";
      loading = false;
    });
    return;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.best,
  );

  userLat = position.latitude;
  userLng = position.longitude;

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

/// CHECK IN
Future<void> checkIn() async {

  final userProvider =
      Provider.of<UserProvider>(context, listen:false);

  String userId = userProvider.userId ?? "";
  String userName = userProvider.userName ?? "";
  String branchCode = userProvider.branchCode ?? "";

  String todayId = getTodayId();

  var docRef = FirebaseFirestore.instance
      .collection("attendance")
      .doc(userId)
      .collection("logs")
      .doc(todayId);

  /// CHECK IF ALREADY CHECKED IN
  if ((await docRef.get()).exists) {
    setState(() {
      message = "Already checked in today";
    });
    return;
  }

  /// CAPTURE SELFIE
  File? selfie = await captureSelfie();
  if (selfie == null) return;

  /// UPLOAD IMAGE
  String imageUrl = await uploadSelfie(selfie, userId);

  /// SAVE ATTENDANCE
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

  /// UPDATE STATUS
  await loadTodayAttendance();

  setState(() {
    message = "Check-In Successful ✔ Redirecting...";
  });

  /// WAIT 1 SECOND
  await Future.delayed(const Duration(seconds: 1));

  if (!mounted) return;

  /// GO TO DASHBOARD
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => MainScreen(),
    ),
  );
}

/// CHECK OUT
Future<void> checkOut() async {


final userProvider =
    Provider.of<UserProvider>(context, listen:false);

String userId = userProvider.userId ?? "";
String todayId = getTodayId();

var docRef = FirebaseFirestore.instance
    .collection("attendance")
    .doc(userId)
    .collection("logs")
    .doc(todayId);

File? selfie = await captureSelfie();
if(selfie == null) return;

String imageUrl = await uploadSelfie(selfie, userId);

await docRef.set({
  "checkOutTime": FieldValue.serverTimestamp(),
  "checkOutSelfie": imageUrl
}, SetOptions(merge: true));

loadTodayAttendance();

setState(() {
  message = "Check-Out Successful ✔";
});


}

/// MONTHLY LIST
Widget monthlyList(){


return StreamBuilder(

 stream: monthlyAttendance() ?? const Stream.empty(),

  builder:(context,snapshot){

    if(!snapshot.hasData){
      return const Center(child:CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(
          "This Month Attendance",
          style: TextStyle(
            fontSize:18,
            fontWeight: FontWeight.bold
          ),
        ),

        const SizedBox(height:10),

        ...docs.map((doc){

          var data = doc.data() as Map<String,dynamic>;

          Timestamp checkIn = data["checkInTime"];
          Timestamp? checkOut = data["checkOutTime"];

          DateTime date = checkIn.toDate();

          return Container(

            margin: const EdgeInsets.only(bottom:10),
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow:[
                BoxShadow(
                  blurRadius:8,
                  color: Colors.black.withOpacity(.05)
                )
              ]
            ),

            child: Row(

              children: [

                const Icon(Icons.calendar_today,color: Colors.indigo),

                const SizedBox(width:10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "${date.day}/${date.month}/${date.year}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold
                        ),
                      ),

                      Text(
                        "In: ${TimeOfDay.fromDateTime(date).format(context)}"
                      ),

                      if(checkOut!=null)
                      Text(
                        "Out: ${TimeOfDay.fromDateTime(checkOut.toDate()).format(context)}"
                      )

                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal:10,
                    vertical:4
                  ),
                  decoration: BoxDecoration(
                    color: checkOut==null
                        ? Colors.orange.withOpacity(.2)
                        : Colors.green.withOpacity(.2),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    checkOut==null ? "Pending" : "Completed",
                    style: TextStyle(
                      color: checkOut==null
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                )

              ],

            ),

          );

        })

      ],

    );

  },

);


}

@override
Widget build(BuildContext context) {

final userProvider = Provider.of<UserProvider>(context);

const Color gold = Color(0xFFD4AF37);
const Color darkGold = Color(0xFF735C00);
const Color bg = Color(0xFFFBF9F8);
const Color card = Color(0xFFF6F3F2);

return Scaffold(

backgroundColor: bg,

appBar: AppBar(
  title: const Text("Attendance"),
  backgroundColor: bg,
  elevation: 0,
  foregroundColor: darkGold,
),

body: SingleChildScrollView(

padding: const EdgeInsets.all(20),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

/// USER INFO
Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: card,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(.05),
blurRadius: 18,
offset: const Offset(0,8),
)
],
),

child: Row(
children: [

Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: gold.withOpacity(.15),
shape: BoxShape.circle,
),

child: const Icon(
Icons.person,
color: darkGold,
),
),

const SizedBox(width:12),

Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

Text(
userProvider.userName ?? "",
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),

Text(
"Branch ${userProvider.branchCode}",
style: const TextStyle(
fontSize: 13,
color: Colors.grey,
),
),

],
)

],
),
),

const SizedBox(height:20),

/// TODAY STATUS CARD
Container(

padding: const EdgeInsets.all(20),

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

const Text(
"Today's Attendance",
style: TextStyle(
fontWeight: FontWeight.w700,
fontSize: 16,
),
),

const SizedBox(height:16),

Row(

mainAxisAlignment: MainAxisAlignment.spaceAround,

children: [

Column(
children: [

Icon(Icons.login,color: gold),

const SizedBox(height:6),

const Text("Check In"),

Text(
checkInTime ?? "-",
style: const TextStyle(
fontWeight: FontWeight.bold,
),
)

],
),

Column(
children: [

Icon(Icons.logout,color: gold),

const SizedBox(height:6),

const Text("Check Out"),

Text(
checkOutTime ?? "-",
style: const TextStyle(
fontWeight: FontWeight.bold,
),
)

],
),

Column(
children: [

Icon(Icons.verified,color: gold),

const SizedBox(height:6),

const Text("Status"),

Text(
status,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
)

],
)

],

)

],

),

),

const SizedBox(height:20),

/// LOCATION CARD
Container(

padding: const EdgeInsets.all(18),

decoration: BoxDecoration(

color: card,

borderRadius: BorderRadius.circular(20),

boxShadow: [

BoxShadow(
color: Colors.black.withOpacity(.05),
blurRadius: 18,
offset: const Offset(0,8),
)

],

),

child: Row(

children: [

Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: gold.withOpacity(.15),
shape: BoxShape.circle,
),

child: const Icon(
Icons.location_on,
color: darkGold,
),
),

const SizedBox(width:12),

Expanded(
child: Text(
message,
style: const TextStyle(
fontSize: 14,
),
),
)

],

),

),

const SizedBox(height:20),

/// BUTTONS
Row(

children: [

Expanded(

child: ElevatedButton.icon(

icon: const Icon(Icons.login),

onPressed: (!canCheckIn || loading)
    ? null
    : () async {

        await checkLocation();

        if (distance != null &&
            message.contains("Inside office")) {
          await checkIn();
        }

      },

style: ElevatedButton.styleFrom(

backgroundColor: gold,
foregroundColor: Colors.black,

minimumSize: const Size(0,55),

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),

),

label: const Text(
"CHECK IN",
style: TextStyle(fontWeight: FontWeight.bold),
),

),

),

const SizedBox(width:12),

Expanded(

child: ElevatedButton.icon(

icon: const Icon(Icons.logout),

onPressed: (!canCheckOut || loading)
    ? null
    : () async {

        await checkLocation();

        if (distance != null &&
            message.contains("Inside office")) {
          await checkOut();
        }

      },

style: ElevatedButton.styleFrom(

backgroundColor: darkGold,
foregroundColor: Colors.white,

minimumSize: const Size(0,55),

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),

),

label: const Text(
"CHECK OUT",
style: TextStyle(fontWeight: FontWeight.bold),
),

),

)

],

),
const SizedBox(height:16),

Center(
  child: TextButton(

    onPressed: () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(),
        ),
      );

    },

    child: const Text(
      "Do it later",
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF735C00),
      ),
    ),

  ),
),

const SizedBox(height:30),

monthlyList(),

const SizedBox(height:30),

],

),

),

);

}

}
