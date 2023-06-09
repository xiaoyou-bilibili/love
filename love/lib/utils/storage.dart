import 'dart:ui';

import 'package:love/utils/http.dart';
import 'package:love/utils/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  // 共享存储
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static const String _keySex = "sex";
  static const String _keySecret = "secret";
  static int _sex = 0;
  static String _secret = "";
  static AppSetting _appSetting = AppSetting(manAvatar: '', womanAvatar: '');

  // 获取应用设置
  static AppSetting getAppSetting() {
    return _appSetting;
  }

  // 设置应用
  static void setAppSetting(AppSetting setting) {
    _appSetting = setting;
    _appSetting.womanAvatar = "$host${_appSetting.womanAvatar}";
    _appSetting.manAvatar = "$host${_appSetting.manAvatar}";
  }

  // 同步获取性别
  static int getSexSync() {
    return _sex;
  }

  // 获取密钥
  static String getSecretSync() {
    return _secret;
  }

  // 获取性别
  static Future<int> getSexAndSecret() async {
    final SharedPreferences prefs = await _prefs;
    _sex = prefs.getInt(_keySex) ?? 0;
    _secret = prefs.getString(_keySecret) ?? "";
    return _sex;
  }

  // 设置性别
  static Future<void> setSex(int value) async {
    final SharedPreferences prefs = await _prefs;
    _sex = value;
    prefs.setInt(_keySex, value);
  }

  // 设置密钥
  static Future<void> setSecret(String value) async {
    final SharedPreferences prefs = await _prefs;
    _secret = value;
    prefs.setString(_keySecret, value);
  }

  // 设置主题
  // 获取主题颜色
  static Color getPrimaryColor() {
    return const Color.fromRGBO(252, 139, 171, 10);
  }

  // 获取次要颜色
  static Color getSecondaryColor() {
    return const Color.fromRGBO(117, 117, 117, 10);
  }
}
