import 'package:flutter/material.dart';
import '../services/family_service.dart';

class FamilyProvider with ChangeNotifier {
  final FamilyService _service = FamilyService();

  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> get families => _families;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load all families (optionally filter by ward)
  Future<void> loadFamilies({String? wardId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _families = await _service.fetchFamilies(wardId: wardId);
    } catch (e) {
      debugPrint("❌ Error loading families: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new family
  Future<void> addFamily(Map<String, dynamic> familyData) async {
    try {
      final created = await _service.addFamily(familyData);
      _families.insert(0, created);
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

  /// Delete family
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

  /// Utility: check if a user has an approved family
  bool hasApprovedFamily(String username) {
    return _families.any(
      (f) => (f['headName'] as String).toLowerCase().contains(
        username.toLowerCase(),
      ),
    );
  }
}
