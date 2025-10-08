import 'dart:convert';
import 'package:http/http.dart' as http;

class FamilyService {
  static const String baseUrl = "https://your-backend-api.com/api/families";

  Future<List<Map<String, dynamic>>> fetchFamilies() async {
    // Example mock response
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Failed to load families");
    }
  }

  Future<Map<String, dynamic>> addFamily(
    Map<String, dynamic> familyData,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(familyData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to add family");
    }
  }

  Future<Map<String, dynamic>> updateFamily(
    String id,
    Map<String, dynamic> familyData,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(familyData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to update family");
    }
  }

  Future<void> deleteFamily(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200) {
      throw Exception("Failed to delete family");
    }
  }
}
