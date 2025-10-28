import 'package:flutter/material.dart';
import '../services/family_service.dart';

class FamilyProvider with ChangeNotifier {
  final FamilyService _service = FamilyService();

  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> get families => _families;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Load families from backend
  Future<void> loadFamilies({String? wardId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _families = await _service.fetchFamilies(wardId: wardId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new family (only user input)
  Future<void> addFamily(Map<String, dynamic> familyData) async {
    try {
      // Validate required fields before calling backend
      if (familyData["familyId"] == null ||
          familyData["wardId"] == null ||
          familyData["headName"] == null ||
          familyData["membersCount"] == null ||
          familyData["monthlyFee"] == null) {
        throw Exception("All fields are required!");
      }

      final newFamily = await _service.addFamily(familyData);
      _families.add(newFamily);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error adding family: $e");
      rethrow;
    }
  }

  /// Update existing family
  Future<void> updateFamily(String id, Map<String, dynamic> familyData) async {
    try {
      final updated = await _service.updateFamily(id, familyData);
      final index = _families.indexWhere((f) => f['familyId'] == id);
      if (index != -1) {
        _families[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error updating family: $e");
      rethrow;
    }
  }

  /// Delete a family
  Future<void> deleteFamily(String id) async {
    try {
      await _service.deleteFamily(id);
      _families.removeWhere((f) => f['familyId'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error deleting family: $e");
      rethrow;
    }
  }
}
