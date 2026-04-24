import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  String getBranchCode() {
    return Provider.of<UserProvider>(context, listen: false).branchCode ?? "";
  }

  final productNameController = TextEditingController();
  final productCodeController = TextEditingController();
  final quantityController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandNameController = TextEditingController();
  final priceController = TextEditingController();
  final depositController = TextEditingController();
  final minimumRentalController = TextEditingController(text: "1");
  final extraRentController = TextEditingController(text: "1");

  String priceType = "";
  String extraChargeType = "₹";

  final ImagePicker picker = ImagePicker();
  List<File> images = [];

  bool isUploading = false;

  /// CAMERA
  Future<void> openCamera() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (picked == null) return;

      if (!mounted) return;

      setState(() {
        images.add(File(picked.path));
      });

    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  /// GALLERY
  Future<void> openGallery() async {
    try {
      final List<XFile> picked = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (picked.isEmpty) return;

      if (!mounted) return;

      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });

    } catch (e) {
      debugPrint("Gallery error: $e");
    }
  }

  /// IMAGE OPTIONS
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Open Camera"),
                onTap: (){
                  Navigator.pop(context);
                  openCamera();
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: (){
                  Navigator.pop(context);
                  openGallery();
                },
              ),

            ],
          ),
        );
      },
    );
  }

  /// ADD PRODUCT (SAME STRUCTURE AS WEB)
  Future<void> addProduct() async {

    if (isUploading) return;

    setState(() {
      isUploading = true;
    });

    try {

      String branchCode = getBranchCode();

      if (branchCode.isEmpty) {
        throw Exception("Branch code not found");
      }

      String productCode = productCodeController.text.trim();

if (productCode.isEmpty) {
  throw Exception("Product code is required");
}

/// Check if product already exists
final productRef = FirebaseFirestore.instance
    .doc("products/$branchCode/products/$productCode");

final existingProduct = await productRef.get();

if (existingProduct.exists) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Product code already exists"),
      backgroundColor: Colors.red,
    ),
  );

  setState(() {
    isUploading = false;
  });

  return;
}

      List<String> imageUrls = [];

      /// Upload Images (same path as web)
      for (var image in images) {

        final ref = FirebaseStorage.instance.ref(
          "products/$branchCode/$productCode/${DateTime.now().millisecondsSinceEpoch}-${image.path.split('/').last}"
        );

        UploadTask uploadTask = ref.putFile(image);

        TaskSnapshot snapshot = await uploadTask;

        final url = await snapshot.ref.getDownloadURL();

        imageUrls.add(url);
      }

      /// Product Data (same fields as web)
      final productData = {

        "productName": productNameController.text,
        "brandName": brandNameController.text,
        "quantity": int.tryParse(quantityController.text) ?? 0,
        "price": double.tryParse(priceController.text) ?? 0,
        "deposit": double.tryParse(depositController.text) ?? 0,
        "productCode": productCode,
        "description": descriptionController.text,
        "imageUrls": imageUrls,
        "branchCode": branchCode,
        "customFields": {},
        "priceType": priceType,
        "extraRent": int.tryParse(extraRentController.text) ?? 1,
        "minimumRentalPeriod": int.tryParse(minimumRentalController.text) ?? 1,
        "createdAt": FieldValue.serverTimestamp(),

      };

      /// Same Firestore path as WEB
    //   final productRef = FirebaseFirestore.instance
    //       .doc("products/$branchCode/products/$productCode");

      await productRef.set(productData);

      /// Create bookings subcollection (same as web)
      await productRef.collection("bookings").add({});

      ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Product added successfully")),
);

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const MainScreen(initialIndex: 3),
  ),
);

    } catch (e) {

      debugPrint("Add product error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    } finally {

      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }

    }

  }

final primaryColor = Color(0xFFD4AF37);
final bgColor = Color(0xFFF5F6FA);

InputDecoration inputStyle(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(color: primaryColor, width: 1.5),    ),
  );
}

Widget sectionCard({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: child,
  );
}
  @override
Widget build(BuildContext context) {

  return Scaffold(

    appBar: AppBar(
      title: const Text("Add Product"),
      backgroundColor: primaryColor,
    ),

    body: Container(
      color: bgColor,

      child: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// PRODUCT DETAILS CARD
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Product Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: productNameController,
                    decoration: inputStyle("Product Name"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: productCodeController,
                    decoration: inputStyle("Product Code"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle("Quantity"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: inputStyle("Description"),
                  ),

                ],
              ),
            ),

            /// IMAGE UPLOAD CARD
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Upload Images",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: showImageOptions,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),

                      child: images.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [

                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),

                                SizedBox(height: 10),

                                Text(
                                  "Upload Product Images",
                                  style: TextStyle(color: Colors.grey),
                                ),

                              ],
                            )

                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context,index){

                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      images[index],
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );

                              },
                            ),
                    ),
                  ),

                ],
              ),
            ),

            /// PRICING CARD
            sectionCard(
              child: Column(
                children: [

                  TextField(
                    controller: brandNameController,
                    decoration: inputStyle("Brand Name"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle("Base Rent"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: depositController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle("Deposit"),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField(
                    value: priceType.isEmpty ? null : priceType,
                    decoration: inputStyle("Rent Calculated By"),
                    items: const [

                      DropdownMenuItem(
                        value: "hourly",
                        child: Text("Hourly"),
                      ),

                      DropdownMenuItem(
                        value: "daily",
                        child: Text("Daily"),
                      ),

                    ],
                    onChanged: (value){
                      setState(() {
                        priceType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: minimumRentalController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle("Minimum Rental Period"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: extraRentController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle("Add-On Charges"),
                  ),

                ],
              ),
            ),

            /// ADD PRODUCT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: isUploading ? null : addProduct,

                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add Product",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

          ],
        ),
      ),
    ),
  );
}
}