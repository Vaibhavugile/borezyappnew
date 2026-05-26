import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {

  final TextEditingController
      nameController =
      TextEditingController();

  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  bool loading = false;

  String? error;

  Future<void> signup() async {

    setState(() {
      loading = true;
      error = null;
    });

    try {

      /// CREATE AUTH USER
      final result =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email:
            emailController.text.trim(),
        password:
            passwordController.text.trim(),
      );

      final user = result.user;

      if (user == null) {
        throw Exception("User not found");
      }

      /// SAVE CUSTOMER
      await FirebaseFirestore.instance
          .collection("customers")
          .doc(user.uid)
          .set({

        "name":
            nameController.text.trim(),

        "email":
            emailController.text.trim(),

        "role": "customer",

        /// DEMO BRANCH
        "branchCode": "0707",

        "createdAt":
            FieldValue.serverTimestamp(),

      });

      /// GO TO MAIN SCREEN
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const MainScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      setState(() {
        error = e.message;
      });

    } catch (e) {

      setState(() {
        error = e.toString();
      });

    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFFBF9F8),

      appBar: AppBar(
        title: const Text("Create Account"),
      ),

      body: Center(

        child: SingleChildScrollView(

          child: Padding(

            padding:
                const EdgeInsets.all(24),

            child: Column(

              children: [

                const Text(
                  "Join Borezy",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                /// NAME
                TextField(
                  controller:
                      nameController,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Full Name",
                  ),
                ),

                const SizedBox(height: 16),

                /// EMAIL
                TextField(
                  controller:
                      emailController,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Email",
                  ),
                ),

                const SizedBox(height: 16),

                /// PASSWORD
                TextField(
                  controller:
                      passwordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Password",
                  ),
                ),

                const SizedBox(height: 20),

                /// ERROR
                if (error != null)
                  Text(
                    error!,
                    style:
                        const TextStyle(
                      color: Colors.red,
                    ),
                  ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed:
                        loading
                            ? null
                            : signup,

                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Create Account",
                          ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}