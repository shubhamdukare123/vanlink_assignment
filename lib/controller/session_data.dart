
import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  static bool? isLogin;
  static String? email;
  static String? name;
  static String? role;
  static Future<void> storeSessionData(
      {required bool loginData,
      required String email,
      required String name,
      required String role,
      }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    //SET DATA
    sharedPreferences.setBool("loginSession", loginData);
    sharedPreferences.setString("emailId", email);
    sharedPreferences.setString("name", name);
    sharedPreferences.setString("role", role);

    getSessionData();
  }

  static Future<void> getSessionData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    isLogin = sharedPreferences.getBool("loginSession");
    email = sharedPreferences.getString("emailId");
    name = sharedPreferences.getString("name");
    role = sharedPreferences.getString("role");
  }
}
