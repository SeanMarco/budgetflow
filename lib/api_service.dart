import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// IMPORTANT – change baseUrl for your device:
///   Android Emulator → http://10.0.2.2/budgetflow_api
///   Real Phone       → http://YOUR_PC_IP/budgetflow_api
///   iOS Simulator    → http://localhost/budgetflow_api
const String baseUrl = "http://localhost/budgetflow_api";

// ─────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// SESSION
// ─────────────────────────────────────────────
Future<void> saveSession(Map<String, dynamic> userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', userData['token'] ?? '');
  await prefs.setString('first_name', userData['first_name'] ?? '');
  await prefs.setString('last_name', userData['last_name'] ?? '');
  await prefs.setInt('user_id', userData['id'] ?? 0);
}

Future<String?> getSavedToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return (token != null && token.isNotEmpty) ? token : null;
}

Future<String> getSavedUsername() async {
  final prefs = await SharedPreferences.getInstance();
  final first = prefs.getString('first_name') ?? '';
  final last = prefs.getString('last_name') ?? '';
  return '$first $last'.trim();
}

Future<int> getSavedUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('user_id') ?? 0;
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('first_name');
  await prefs.remove('last_name');
  await prefs.remove('user_id');
}

// ─────────────────────────────────────────────
// ACCOUNTS
// ─────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchAccounts(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_accounts.php?user_id=$userId'))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    if (body['status'] == 'success') {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    return [];
  } catch (e) {
    return [];
  }
}

// ─────────────────────────────────────────────
// TRANSACTIONS
// ─────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchTransactions(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_transactions.php?user_id=$userId'))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    if (body['status'] == 'success') {
      return (body['data'] as List).map((item) {
        return {
          'id': item['id'].toString(),
          'title': item['title'],
          'amount': (item['amount'] as num).toDouble(),
          'isIncome': item['isIncome'] == true || item['isIncome'] == 1,
          'category': item['category'],
          'accountId': item['accountId'].toString(),
          'accountName': item['accountName'] ?? '',
          'accountEmoji': item['accountEmoji'] ?? '',
          'note': item['note'] ?? '',
          'date': DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
        };
      }).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
}

Future<Map<String, dynamic>> addTransactionAPI({
  required int userId,
  required String title,
  required double amount,
  required bool isIncome,
  required String category,
  required String accountId,
  required String note,
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
            'note': note,
            'date': date,
          },
        )
        .timeout(const Duration(seconds: 10));
    return json.decode(res.body);
  } catch (e) {
    return {"status": "error", "message": "Add transaction failed"};
  }
}

Future<Map<String, dynamic>> editTransactionAPI({
  required int id,
  required int userId,
  required String title,
  required double amount,
  required bool isIncome,
  required String category,
  required String accountId,
  required String note,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/edit_transaction.php'),
          body: {
            'id': id.toString(),
            'user_id': userId.toString(),
            'title': title,
            'amount': amount.toString(),
            'is_income': isIncome ? "1" : "0",
            'category': category,
            'account_id': accountId,
            'note': note,
          },
        )
        .timeout(const Duration(seconds: 10));
    return json.decode(res.body);
  } catch (e) {
    return {"status": "error", "message": "Edit transaction failed"};
  }
}

Future<Map<String, dynamic>> deleteTransactionAPI({
  required int id,
  required int userId,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/delete_transaction.php'),
          body: {'id': id.toString(), 'user_id': userId.toString()},
        )
        .timeout(const Duration(seconds: 10));
    return json.decode(res.body);
  } catch (e) {
    return {"status": "error", "message": "Delete transaction failed"};
  }
}
