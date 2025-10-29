import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/config.dart';

class FamilyService {
  static String get baseUrl => "${Config.baseUrl}/families";

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'X-USER': (token ?? '').isEmpty
            ? 'guest'
            : (token ?? '').replaceFirst('session-', ''),
        'X-ROLES': 'ADMIN',
      };

  Future<List<Map<String, dynamic>>> fetchFamilies(String? token,
      {String? wardId}) async {
    final uri = wardId == null
        ? Uri.parse(baseUrl)
        : Uri.parse("$baseUrl/ward/$wardId");
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      final api = json.decode(response.body);
      if (api is Map && api.containsKey('data')) {
        return List<Map<String, dynamic>>.from(api['data']);
      }
      // Some endpoints may return raw lists
      return List<Map<String, dynamic>>.from(api);
    } else {
      throw Exception(
        "Failed to fetch families: ${response.statusCode} - ${response.body}",
      );
    }
  }

  /// Add new family (real backend integration)
  Future<Map<String, dynamic>> addFamily(
    Map<String, dynamic> familyData,
    String? token,
  ) async {
    final url = Uri.parse(baseUrl);

    // ✅ Ensure data matches your Spring Boot DTO
    final payload = {
      "familyId": familyData["familyId"],
      "wardId": familyData["wardId"],
      "headName": familyData["headName"],
      "address": familyData["address"] ?? "",
      "membersCount": familyData["membersCount"],
      "monthlyFee": familyData["monthlyFee"],
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: _headers(token),
      body: json.encode({
        'wardId': familyData['wardId'] ?? familyData['flatNumber'] ?? 'A-101',
        'headName': familyData['name'],
        'address': familyData['flatNumber'],
        'membersCount': familyData['members'],
        'monthlyFee': 500.0,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final api = json.decode(response.body);
      return api is Map && api.containsKey('data') ? api['data'] : api;
    } else {
      throw Exception(
        "Failed to add family: ${response.statusCode} - ${response.body}",
      );
    }
  }

  /// Update an existing family
  Future<Map<String, dynamic>> updateFamily(
    String id,
    Map<String, dynamic> familyData,
    String? token,
  ) async {
    final url = Uri.parse("$baseUrl/$id");

    final payload = {
      "wardId": familyData["wardId"],
      "headName": familyData["headName"],
      "address": familyData["address"],
      "membersCount": familyData["membersCount"],
      "monthlyFee": familyData["monthlyFee"],
    };

    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: _headers(token),
      body: json.encode({
        'headName': familyData['name'],
        'address': familyData['flatNumber'],
        'membersCount': familyData['members'],
      }),
    );

    if (response.statusCode == 200) {
      final api = json.decode(response.body);
      return api is Map && api.containsKey('data') ? api['data'] : api;
    } else {
      throw Exception(
        "Failed to update family: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<void> deleteFamily(String id, String? token) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete family: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
