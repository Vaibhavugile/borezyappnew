import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  String? get branchCode => _userData?['branchCode']; // Access the branchCode from user data
    String? get userName => _userData?['name'];
  String? get role => _userData?['role'];
  String? get userId => _userData?['uid'];


  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }
}

