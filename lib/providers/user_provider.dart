import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {

  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData =>
      _userData;

  /// =====================================
  /// BASIC GETTERS
  /// =====================================

  String get branchCode =>
      _userData?['branchCode'] ?? "";

  String get userName =>
      _userData?['name'] ??
      _userData?['userName'] ??
      "Guest User";

  String get role =>
      _userData?['role'] ?? "";

  String get userId =>
      _userData?['userId'] ?? "";

  String get email =>
      _userData?['email'] ?? "";

  /// =====================================
  /// GUEST MODE
  /// =====================================

  bool get isGuest =>
      _userData?['isGuest'] == true;

  bool get isCustomer =>
      role == "customer";

  bool get isStaff =>
      role == "admin" ||
      role == "branch" ||
      role == "subuser";

  /// =====================================
  /// INITIAL RESTORE
  /// =====================================

  void setInitialUserData(
    Map<String, dynamic>? data,
  ) {

    debugPrint(
      "INITIAL USER DATA: $data",
    );

    _userData = data;
  }

  /// =====================================
  /// SET USER DATA
  /// =====================================

  void setUserData(
    Map<String, dynamic> data,
  ) {

    debugPrint(
      "SETTING USER DATA: $data",
    );

    _userData = data;

    notifyListeners();
  }

  /// =====================================
  /// CLEAR USER
  /// =====================================

  void clearUserData() {

    _userData = null;

    notifyListeners();
  }
}