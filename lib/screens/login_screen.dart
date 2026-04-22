import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'booking_screen.dart';
import 'admin_screen.dart';
import 'branch_dashboard.dart';
import 'subuser_dashboard.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  String formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final month = parts[1].padLeft(2, '0');
      final day = parts[2].padLeft(2, '0');
      return '${parts[0]}-$month-$day';
    }
    return dateStr;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final connectivity = await Connectivity().checkConnectivity();
    final prefs = await SharedPreferences.getInstance();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final hiveBox = Hive.box('offline_cache');

    if (connectivity == ConnectivityResult.none) {
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      final savedUserData = hiveBox.get(email);

      if (savedEmail == email && savedPassword == password && savedUserData != null) {
        Provider.of<UserProvider>(context, listen: false).setUserData(savedUserData);
        final role = savedUserData['role'] ?? 'branch';
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminScreen()));
        } else if (role == 'subuser') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
        }
      } else {
        setState(() => _error = 'Offline: Invalid credentials or no cached user data.');
      }
      setState(() => _loading = false);
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final result = await auth.signInWithEmailAndPassword(email: email, password: password);
      final user = result.user;
      if (user == null) throw FirebaseAuthException(message: 'User not found', code: '');

      final token = await user.getIdToken();
      if (_rememberMe) {
        await prefs.setString('authToken', token ?? '');
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }

      final firestore = FirebaseFirestore.instance;

      final superAdmins = await firestore.collection('superadmins').where('email', isEqualTo: email).get();
      if (superAdmins.docs.isNotEmpty) {
        final data = superAdmins.docs.first.data();
        data['role'] = 'admin';
        Provider.of<UserProvider>(context, listen: false).setUserData(data);
        hiveBox.put(email, data);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminScreen()));
        return;
      }

      final branches = await firestore.collection('branches').where('emailId', isEqualTo: email).get();
      if (branches.docs.isNotEmpty) {
        final data = branches.docs.first.data();
        final now = DateTime.now();
        if (now.isBefore(DateTime.parse(formatDate(data['activeDate'])))) {
          setState(() => _error = 'Branch plan not active yet.');
          return;
        }
        if (now.isAfter(DateTime.parse(formatDate(data['deactiveDate'])))) {
          setState(() => _error = 'Branch plan expired.');
          return;
        }

        data['role'] = 'branch';
        Provider.of<UserProvider>(context, listen: false).setUserData(data);
        hiveBox.put(email, data);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
        return;
      }

      final subusers = await firestore.collection('subusers').where('email', isEqualTo: email).get();
      print('Subusers found: ${subusers.docs.length}');

      if (subusers.docs.isNotEmpty) {
        final data = subusers.docs.first.data();
        print('Subuser data: $data');

        if (data['isActive'] != true) {
          setState(() => _error = 'Subuser inactive.');
          print('Subuser inactive');
          return;
        }

        final branchCode = data['branchCode'];
        if (branchCode == null || branchCode.toString().isEmpty) {
          setState(() => _error = 'Subuser is missing a valid branch code.');
          print('Subuser missing branch code');
          return;
        }

        final branch = await firestore.collection('branches')
            .where('branchCode', isEqualTo: branchCode)
            .get();

        print('Associated branch docs: ${branch.docs.length}');
        if (branch.docs.isEmpty) {
          setState(() => _error = 'Associated branch not found.');
          print('Associated branch not found');
          return;
        }

        // Optional: You can check if the branch itself isActive (if you store that)
        // final branchData = branch.docs.first.data();
        // if (branchData['isActive'] != true) {
        //   setState(() => _error = 'Associated branch is inactive.');
        //   print('Associated branch is inactive');
        //   return;
        // }

        data['role'] = 'subuser';  // Normalize role casing
        Provider.of<UserProvider>(context, listen: false).setUserData(data);
        hiveBox.put(email, data);
        print('Navigating to MainScreen');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
        return;
      }



      setState(() => _error = 'No user found with the provided credentials.');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _emailController.text = prefs.getString('email') ?? '';
    _passwordController.text = prefs.getString('password') ?? '';
    setState(() {
      _rememberMe = prefs.containsKey('authToken');
    });
  }

 @override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFFBF9F8),


body: Center(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),

      child: Card(
        elevation: 10,
        color: const Color(0xFFF6F3F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 40,
            horizontal: 24,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// LOGO
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 36,
                  color: Color(0xFF735C00),
                ),
              ),

              const SizedBox(height: 18),

              /// TITLE
              const Text(
                "Welcome to Borezy",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF735C00),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Login to continue",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 28),

              /// EMAIL
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email Address",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// REMEMBER ME
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                  ),
                  const Text("Remember Me"),
                ],
              ),

              /// ERROR
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 22),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C1C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
),


);
}


}
