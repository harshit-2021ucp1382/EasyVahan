import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:easy_vahan/common/navigation.dart';
import 'package:easy_vahan/common/routing.dart';
import 'package:easy_vahan/models/user.dart';
import 'package:easy_vahan/providers/user_info.dart';
import 'package:easy_vahan/screens/onboarding/repo/auth_repo.dart';

class LoginAuthViewModel with ChangeNotifier {
  final AuthRepo myRepo;
  final UserProv userProvider;

  LoginAuthViewModel({required this.myRepo, required this.userProvider});

  String errorText = "";

  String _email = "";
  String _password = "";

  get email => _email;

  get password => _password;

  setEmail(String value) {
    _email = value;
  }

  setPassword(String value) {
    _password = value;
  }

  bool _loading = false;

  bool get loading => _loading;

  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  bool _passwordVisible = false;

  bool get passwordVisible => _passwordVisible;

  void toggleVisible() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  void clearValues() {
    _email = "";
    _password = "";
  }

  Future<void> postDetailsToFirestore(UserModel userModel) async {
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    await firebaseFirestore
        .collection("users")
        .doc(userModel.uid)
        .set(userModel.toJson());
  }

  Future<void> loginApi(BuildContext context) async {
    Map data = {
      'email': _email.trim(),
      'password': _password.trim(),
    };

    setLoading(true);

    try {
      var value = await myRepo.signInWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      userProvider.updateUserInfo(value!);

      setLoading(false);

      await Navigator.of(NavigationService.navigatorKey.currentContext!,
              rootNavigator: true)
          .pushAndRemoveUntil(
              Routes.testing(), (Route<dynamic> route) => false);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          errorText = "Your email address appears to be malformed";
          break;
        case "wrong-password":
          errorText = "Your password is wrong";
          break;
        case "user-not-found":
          errorText = "User with this email doesn't exist";
          break;
        case "user-disabled":
          errorText = "User with this email has been disabled";
          break;
        case "too-many-requests":
          errorText = "Too many requests";
          break;
        case "operation-not-allowed":
          errorText = "Signing in with Email and Password is not enabled";
          break;
        case "quota-exceeded":
          errorText = "Quota Exceeded. Please contact Team Zine.";
          break;
        case "timeout":
          errorText = "Timeout. Please check you internet and try again later";
          break;
        case "unverified-email":
          errorText = "Please verify your email and login";
          break;
        default:
          errorText = "An undefined Error happened";
          print(e.code);
      }
      setLoading(false);

      Fluttertoast.showToast(
          msg: errorText,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red);
    }
  }
}
