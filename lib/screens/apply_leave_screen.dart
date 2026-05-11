import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';

import '../providers/user_provider.dart';



class ApplyLeaveScreen extends StatefulWidget {

  const ApplyLeaveScreen({
    super.key,
  });



  @override
  State<ApplyLeaveScreen> createState() =>

      _ApplyLeaveScreenState();
}



class _ApplyLeaveScreenState

    extends State<ApplyLeaveScreen> {

  DateTime? fromDate;

  DateTime? toDate;



  final reasonController =

      TextEditingController();



  bool loading = false;



  /// PICK DATE
  Future<void> pickDate({
    required bool isFrom,
  }) async {

    DateTime now = DateTime.now();



    final picked =

        await showDatePicker(

      context: context,

      initialDate: now,

      firstDate: now,

      lastDate:

          DateTime(now.year + 1),
    );



    if (picked == null) return;



    setState(() {

      if (isFrom) {

        fromDate = picked;

      } else {

        toDate = picked;
      }
    });
  }



  /// SUBMIT LEAVE
  Future<void> submitLeave() async {

    if (fromDate == null ||

        toDate == null ||

        reasonController.text
            .trim()
            .isEmpty) {

      ScaffoldMessenger.of(context)

          .showSnackBar(

        const SnackBar(

          content: Text(
            "Fill all fields",
          ),
        ),
      );

      return;
    }



    setState(() {
      loading = true;
    });



    try {

      final userProvider =

          Provider.of<UserProvider>(
        context,
        listen: false,
      );



      final branchCode =

          userProvider.branchCode ?? "";



      await FirebaseFirestore.instance

          .collection("products")

          .doc(branchCode)

          .collection("leaveRequests")

          .add({

        "userId":
            userProvider.userId,



        "userName":
            userProvider.userName,



        "branchCode":
            branchCode,



        "fromDate":
            Timestamp.fromDate(
          fromDate!,
        ),



        "toDate":
            Timestamp.fromDate(
          toDate!,
        ),



        "reason":
            reasonController.text
                .trim(),



        "status":
            "pending",



        "createdAt":
            FieldValue
                .serverTimestamp(),
      });



      if (!mounted) return;



      ScaffoldMessenger.of(context)

          .showSnackBar(

        const SnackBar(

          content: Text(
            "Leave request submitted ✔",
          ),
        ),
      );



      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(
          content: Text("$e"),
        ),
      );
    }



    setState(() {
      loading = false;
    });
  }



  @override
  Widget build(BuildContext context) {

    const gold =
        Color(0xFFD4AF37);

    const darkGold =
        Color(0xFF735C00);



    return Scaffold(

      resizeToAvoidBottomInset:
          true,



      backgroundColor:
          const Color(0xFFFBF9F8),



      appBar: AppBar(

        title:
            const Text("Apply Leave"),



        backgroundColor:
            Colors.transparent,



        elevation: 0,



        foregroundColor:
            darkGold,
      ),



      body: SafeArea(

        child: SingleChildScrollView(

          keyboardDismissBehavior:

              ScrollViewKeyboardDismissBehavior
                  .onDrag,



          padding:
              const EdgeInsets.all(20),



          child: ConstrainedBox(

            constraints: BoxConstraints(

              minHeight:

                  MediaQuery.of(context)
                          .size
                          .height -
                      140,
            ),



            child: IntrinsicHeight(

              child: Column(

                crossAxisAlignment:

                    CrossAxisAlignment
                        .start,

                children: [

                  /// FROM DATE
                  const Text(
                    "From Date",
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  InkWell(

                    onTap: () =>
                        pickDate(
                      isFrom: true,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    child: Container(

                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(

                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child: Text(

                        fromDate == null

                            ? "Select date"

                            : "${fromDate!.day}/${fromDate!.month}/${fromDate!.year}",
                      ),
                    ),
                  ),



                  const SizedBox(
                    height: 20,
                  ),

                  /// TO DATE
                  const Text(
                    "To Date",
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  InkWell(

                    onTap: () =>
                        pickDate(
                      isFrom: false,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    child: Container(

                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(

                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child: Text(

                        toDate == null

                            ? "Select date"

                            : "${toDate!.day}/${toDate!.month}/${toDate!.year}",
                      ),
                    ),
                  ),



                  const SizedBox(
                    height: 20,
                  ),

                  /// REASON
                  const Text(
                    "Reason",
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(

                    controller:
                        reasonController,

                    maxLines: 5,

                    textInputAction:
                        TextInputAction.done,

                    decoration:
                        InputDecoration(

                      hintText:
                          "Enter leave reason",

                      filled: true,

                      fillColor:
                          Colors.white,

                      contentPadding:
                          const EdgeInsets.all(
                        18,
                      ),

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),



                  const Spacer(),



                  /// BUTTON
                  SizedBox(

                    width:
                        double.infinity,

                    child: ElevatedButton(

                      onPressed:

                          loading
                              ? null
                              : submitLeave,

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            gold,

                        foregroundColor:
                            Colors.black,

                        minimumSize:
                            const Size(
                          0,
                          58,
                        ),

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),

                      child: loading

                          ? const SizedBox(

                              height: 22,

                              width: 22,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                              ),
                            )

                          : const Text(

                              "Submit Leave Request",

                              style: TextStyle(

                                fontWeight:
                                    FontWeight.bold,

                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}