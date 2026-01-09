import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(id: '', name: '', email: '', password: '', token: '');

  User get user => _user;

  void setUser(String user) {
    _user = User.fromJson(user);
    notifyListeners();
  }

  void setUserFromModel(User user) {
    _user = user;
    notifyListeners();
  }

  // Thêm method để reset user về empty state
  void clearUser() {
    _user = User(id: '', name: '', email: '', password: '', token: '');
    notifyListeners();
  }
}
