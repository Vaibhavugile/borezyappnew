import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {

  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData =>
      _userData;

  String get branchCode =>
      _userData?['branchCode'] ?? "";

  String? get userName =>
      _userData?['name'];

  String? get role =>
      _userData?['role'];

  String? get userId =>
      _userData?['userId'];

  /// INITIAL RESTORE
  void setInitialUserData(
  Map<String, dynamic>? data,
) {

  debugPrint(
    "INITIAL USER DATA: $data",
  );

  _userData = data;
}

  void setUserData(
    Map<String, dynamic> data,
  ) {

    debugPrint(
      "SETTING USER DATA: $data",
    );

    _userData = data;

    notifyListeners();
  }

  void clearUserData() {

    _userData = null;

    notifyListeners();
  }
}