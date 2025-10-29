import 'dart:convert';
import 'package:http/http.dart' as http;

class FamilyService {
  // ✅ For Android emulator to talk to your Spring Boot on localhost:8088
  static const String baseUrl = "http://10.0.2.2:8088/api/families";

  /// Fetch all families (optionally by ward)
  Future<List<Map<String, dynamic>>> fetchFamilies({String? wardId}) async {
    final url = wardId != null
        ? Uri.parse("$baseUrl/ward/$wardId")
        : Uri.parse(
            baseUrl,
          ); // (Your backend currently has /families/{id} and /families/ward/{id})

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Expected backend response: { success, message, data: [...] }
      if (data['success'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception("Unexpected response format from backend");
      }
    } else {
      throw Exception(
        "Failed to fetch families: ${response.statusCode} - ${response.body}",
      );
    }
  }

  /// Add new family (real backend integration)
  Future<Map<String, dynamic>> addFamily(
    Map<String, dynamic> familyData,
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
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      } else {
        throw Exception("Backend error: ${data['message']}");
      }
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
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      throw Exception(
        "Failed to update family: ${response.statusCode} - ${response.body}",
      );
    }
  }

  /// Delete a family
  Future<void> deleteFamily(String id) async {
    final url = Uri.parse("$baseUrl/$id");
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete family: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
