import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// IMPORTANT:
/// Use correct base URL depending on device
///
/// Android Emulator → http://10.0.2.2/budgetflow_api
/// Real Phone       → http://YOUR_PC_IP/budgetflow_api
/// iOS Simulator    → http://localhost/budgetflow_api

const String baseUrl = "http://localhost/budgetflow_api";

/// ─────────────────────────────────────────────
/// LOGIN
/// ─────────────────────────────────────────────
Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/login.php'),
          body: {'email': email, 'password': password},
        )
        .timeout(const Duration(seconds: 10));

    return json.decode(res.body);
  } catch (e) {
    return {
      "status": "error",
      "message": "Login failed: check server or network",
    };
  }
}

/// ─────────────────────────────────────────────
/// REGISTER
/// ─────────────────────────────────────────────
Future<Map<String, dynamic>> register(
  String email,
  String password,
  String firstName,
  String lastName,
) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/register.php'),
          body: {
            'email': email,
            'password': password,
            'first_name': firstName,
            'last_name': lastName,
          },
        )
        .timeout(const Duration(seconds: 10));

    return json.decode(res.body);
  } catch (e) {
    return {
      "status": "error",
      "message": "Registration failed: check server or network",
    };
  }
}

/// ─────────────────────────────────────────────
/// SAVE SESSION
/// ─────────────────────────────────────────────
Future<void> saveSession(Map<String, dynamic> userData) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('token', userData['token'] ?? '');
  await prefs.setString('first_name', userData['first_name'] ?? '');
  await prefs.setString('last_name', userData['last_name'] ?? '');
  await prefs.setInt('user_id', userData['id'] ?? 0);
}

/// ─────────────────────────────────────────────
/// GET TOKEN
/// ─────────────────────────────────────────────
Future<String?> getSavedToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return (token != null && token.isNotEmpty) ? token : null;
}

/// ─────────────────────────────────────────────
/// GET USERNAME
/// ─────────────────────────────────────────────
Future<String> getSavedUsername() async {
  final prefs = await SharedPreferences.getInstance();
  final first = prefs.getString('first_name') ?? '';
  final last = prefs.getString('last_name') ?? '';
  return '$first $last'.trim();
}

/// ─────────────────────────────────────────────
/// CLEAR SESSION (LOGOUT FIX)
/// ─────────────────────────────────────────────
Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('first_name');
  await prefs.remove('last_name');
  await prefs.remove('user_id');
}

/// ─────────────────────────────────────────────
/// 🔥 NEW: SAVE TRANSACTION TO DATABASE
/// (THIS FIXES YOUR "NOT REFLECTING IN DB")
/// ─────────────────────────────────────────────
Future<Map<String, dynamic>> addTransactionAPI({
  required int userId,
  required String title,
  required double amount,
  required bool isIncome,
  required String category,
  required String accountId,
  required String date,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/add_transaction.php'),
          body: {
            'user_id': userId.toString(),
            'title': title,
            'amount': amount.toString(),
            'is_income': isIncome ? "1" : "0",
            'category': category,
            'account_id': accountId,
            'date': date,
          },
        )
        .timeout(const Duration(seconds: 10));

    return json.decode(res.body);
  } catch (e) {
    return {
      "status": "error",
      "message": "Transaction failed: check API connection",
    };
  }
}
