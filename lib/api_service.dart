import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://localhost/budgetflow_api";

Future<Map<String, dynamic>> register(
  String email,
  String password, {
  String? name,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/register.php'),
    body: {'email': email, 'password': password, 'name': name ?? ''},
  );

  try {
    return json.decode(response.body);
  } catch (e) {
    print("JSON parse error: ${response.body}");
    return {"status": "error", "message": "Invalid API response"};
  }
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login.php'),
    body: {'email': email, 'password': password},
  );

  try {
    return json.decode(response.body);
  } catch (e) {
    print("JSON parse error: ${response.body}");
    return {"status": "error", "message": "Invalid API response"};
  }
}
