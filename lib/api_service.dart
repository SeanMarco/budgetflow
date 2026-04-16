import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Change baseUrl to match your setup:
///   Android Emulator → http://10.0.2.2/budgetflow_api
///   Real device       → http://YOUR_LAN_IP/budgetflow_api
///   iOS Simulator     → http://localhost/budgetflow_api
///
/// FIXED: Removed the extra 'r' from the IP address
const String baseUrl = "http://localhost/budgetflow_api"; // ✅ FIXED

// ─── Shared headers ──────────────────────────────────────────────────────────
const Duration _timeout = Duration(seconds: 12);

// Helper to add common headers
Map<String, String> _getHeaders() {
  return {'Content-Type': 'application/x-www-form-urlencoded'};
}

// Helper to safely parse JSON response
Future<Map<String, dynamic>> _parseResponse(
  http.Response response,
  String context,
) async {
  print('[$context] Status: ${response.statusCode}');
  print('[$context] Body: ${response.body}');

  if (response.statusCode != 200) {
    return {
      "status": "error",
      "message": "HTTP ${response.statusCode}: ${response.reasonPhrase}",
    };
  }

  if (response.body.isEmpty) {
    return {"status": "error", "message": "Empty response from server"};
  }

  try {
    return json.decode(response.body);
  } catch (e) {
    print('[$context] JSON parse error: $e');
    return {
      "status": "error",
      "message": "Invalid JSON response: $e\nRaw: ${response.body}",
    };
  }
}

// ─── LOGIN ───────────────────────────────────────────────────────────────────
Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/login.php'),
          headers: _getHeaders(),
          body: {'email': email, 'password': password},
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'Login');
  } catch (e) {
    return {"status": "error", "message": "Login failed: $e"};
  }
}

// ─── REGISTER ────────────────────────────────────────────────────────────────
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
          headers: _getHeaders(),
          body: {
            'email': email,
            'password': password,
            'first_name': firstName,
            'last_name': lastName,
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'Register');
  } catch (e) {
    return {"status": "error", "message": "Registration failed: $e"};
  }
}

// ─── SESSION ─────────────────────────────────────────────────────────────────
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

// ─── ACCOUNTS ────────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchAccounts(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_accounts.php?user_id=$userId'))
        .timeout(_timeout);
    final body = await _parseResponse(res, 'FetchAccounts');
    if (body['status'] == 'success') {
      return (body['data'] as List).map((a) {
        return {
          'id': a['id'].toString(),
          'name': a['name'] as String,
          'type': a['type'] as String,
          'emoji': a['emoji'] as String,
          'balance': (a['balance'] as num).toDouble(),
          'color': _hexToColor(a['color'] as String? ?? '#0EA974'),
        };
      }).toList();
    }
    return [];
  } catch (e) {
    print('[API] fetchAccounts error: $e');
    return [];
  }
}

Future<Map<String, dynamic>> addAccountAPI({
  required int userId,
  required String name,
  required String type,
  required String emoji,
  required double balance,
  required String color,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/add_account.php'),
          headers: _getHeaders(),
          body: {
            'user_id': userId.toString(),
            'name': name,
            'type': type,
            'emoji': emoji,
            'balance': balance.toString(),
            'color': color,
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'AddAccount');
  } catch (e) {
    return {"status": "error", "message": "Add account failed: $e"};
  }
}

// ─── TRANSACTIONS ─────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchTransactions(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_transactions.php?user_id=$userId'))
        .timeout(_timeout);
    final body = await _parseResponse(res, 'FetchTransactions');
    if (body['status'] == 'success') {
      return (body['data'] as List).map((item) {
        return {
          'id': item['id'].toString(),
          'title': item['title'] as String,
          'amount': (item['amount'] as num).toDouble(),
          'isIncome': item['isIncome'] == true || item['isIncome'] == 1,
          'category': item['category'] as String,
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
    print('[API] fetchTransactions error: $e');
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
    print('[ADD TX] Starting: userId=$userId, title=$title, amount=$amount');

    final res = await http
        .post(
          Uri.parse('$baseUrl/add_transaction.php'),
          headers: _getHeaders(),
          body: {
            'user_id': userId.toString(),
            'title': title,
            'amount': amount.toString(),
            'is_income': isIncome ? "1" : "0",
            'category': category.isEmpty ? 'General' : category,
            'account_id': accountId,
            'note': note,
            'date': date,
          },
        )
        .timeout(_timeout);

    return await _parseResponse(res, 'AddTransaction');
  } catch (e) {
    print('[ADD TX] Error: $e');
    return {"status": "error", "message": "Add transaction failed: $e"};
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
          headers: _getHeaders(),
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
        .timeout(_timeout);
    return await _parseResponse(res, 'EditTransaction');
  } catch (e) {
    return {"status": "error", "message": "Edit transaction failed: $e"};
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
          headers: _getHeaders(),
          body: {'id': id.toString(), 'user_id': userId.toString()},
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'DeleteTransaction');
  } catch (e) {
    return {"status": "error", "message": "Delete transaction failed: $e"};
  }
}

// ─── BUDGETS ─────────────────────────────────────────────────────────────────
// ─── BUDGETS ─────────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchBudgets(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_budgets.php?user_id=$userId'))
        .timeout(_timeout);
    final body = await _parseResponse(res, 'FetchBudgets');
    if (body['status'] == 'success') {
      return (body['data'] as List).map((b) {
        return {
          'id': b['id'].toString(),
          'category': b['category'] as String,
          'limit': (b['budget_limit'] as num)
              .toDouble(), // Note: field name in DB
          'spent': (b['spent'] as num).toDouble(),
          'emoji': b['emoji'] as String? ?? '💰', // Add emoji
          'period': b['period'] as String? ?? 'Monthly', // Add period
        };
      }).toList();
    }
    return [];
  } catch (e) {
    print('[API] fetchBudgets error: $e');
    return [];
  }
}

// Add this new method for adding/updating budgets with emoji and period
Future<Map<String, dynamic>> addBudgetAPI({
  required int userId,
  required String category,
  required double limit,
  required String emoji,
  required String period,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/add_budget.php'), // New endpoint
          headers: _getHeaders(),
          body: {
            'user_id': userId.toString(),
            'category': category,
            'budget_limit': limit.toString(),
            'emoji': emoji,
            'period': period,
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'AddBudget');
  } catch (e) {
    return {"status": "error", "message": "Add budget failed: $e"};
  }
}

// Update existing budget
Future<Map<String, dynamic>> updateBudgetAPI({
  required int budgetId,
  required int userId,
  required String category,
  required double limit,
  required String emoji,
  required String period,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/update_budget.php'),
          headers: _getHeaders(),
          body: {
            'budget_id': budgetId.toString(),
            'user_id': userId.toString(),
            'category': category,
            'budget_limit': limit.toString(),
            'emoji': emoji,
            'period': period,
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'UpdateBudget');
  } catch (e) {
    return {"status": "error", "message": "Update budget failed: $e"};
  }
}

// Delete budget
Future<Map<String, dynamic>> deleteBudgetAPI({
  required int budgetId,
  required int userId,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/delete_budget.php'),
          headers: _getHeaders(),
          body: {
            'budget_id': budgetId.toString(),
            'user_id': userId.toString(),
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'DeleteBudget');
  } catch (e) {
    return {"status": "error", "message": "Delete budget failed: $e"};
  }
}

// Optional: Keep the old saveBudgetAPI for backward compatibility
Future<Map<String, dynamic>> saveBudgetAPI({
  required int userId,
  required String category,
  required double limit,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/save_budget.php'),
          headers: _getHeaders(),
          body: {
            'user_id': userId.toString(),
            'category': category,
            'limit': limit.toString(),
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'SaveBudget');
  } catch (e) {
    return {"status": "error", "message": "Save budget failed: $e"};
  }
}

// ─── SAVINGS GOALS ────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> fetchSavingsGoals(int userId) async {
  try {
    final res = await http
        .get(Uri.parse('$baseUrl/get_savings.php?user_id=$userId'))
        .timeout(_timeout);
    final body = await _parseResponse(res, 'FetchSavings');
    if (body['status'] == 'success') {
      return (body['data'] as List).map((g) {
        return {
          'id': g['id'].toString(),
          'title': g['title'] as String,
          'emoji': g['emoji'] as String? ?? '🎯',
          'target': (g['target'] as num).toDouble(),
          'saved': (g['saved'] as num).toDouble(),
        };
      }).toList();
    }
    return [];
  } catch (e) {
    print('[API] fetchSavingsGoals error: $e');
    return [];
  }
}

Future<Map<String, dynamic>> saveGoalAPI({
  required int userId,
  required String title,
  required String emoji,
  required double target,
  required double saved,
  int id = 0,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/save_goal.php'),
          headers: _getHeaders(),
          body: {
            'user_id': userId.toString(),
            'title': title,
            'emoji': emoji,
            'target': target.toString(),
            'saved': saved.toString(),
            'id': id.toString(),
          },
        )
        .timeout(_timeout);
    return await _parseResponse(res, 'SaveGoal');
  } catch (e) {
    return {"status": "error", "message": "Save goal failed: $e"};
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  return const Color(0xFF0EA974);
}

// Helper function to format date for API
String formatDateForAPI(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
}
