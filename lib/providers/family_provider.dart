import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../providers/auth_provider.dart' as auth_provider;

class FamilyProvider with ChangeNotifier {
  final FamilyService _service = FamilyService();

  // --- Dummy Data for Demonstration ---
  // Pre-populating with data to show different states on the Families screen.
  // This will be replaced by API calls.
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> get families => _families;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadFamilies({String? wardId, String? token}) async {
    try {
      _families = await _service.fetchFamilies(token, wardId: wardId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

    try {
      _families = await _service.fetchFamilies(wardId: wardId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to check if a user has an approved family
  bool hasApprovedFamily(String username) {
    // This logic assumes the family name is tied to the username.
    // A more robust implementation would use a dedicated 'ownerId' field.
    return _families.any(
      (f) => (f['name'] as String).toLowerCase().contains(username),
    );
  }

  Future<void> addFamily(Map<String, dynamic> familyData, {String? token}) async {
    try {
      // Create family immediately (backend handles maker-checker flow separately)
      final created = await _service.addFamily(familyData, token);
      _families.insert(0, {
        'id': created['familyId']?.toString() ?? created['id']?.toString() ?? '',
        'name': created['headName'] ?? familyData['name'],
        'flatNumber': created['address'] ?? familyData['flatNumber'],
        'members': created['membersCount'] ?? familyData['members'],
        'submittedBy': familyData['submittedBy'],
      });
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error adding family: $e");
      rethrow;
    }
  }

  void approveFamily(int index) {
    final approved = _pendingApproval.removeAt(index);
    _families.add(approved);
    notifyListeners();
  }

  void rejectFamily(String id, String reason) {
    final index = _pendingApproval.indexWhere((p) => p['id'] == id);
    if (index != -1) {
      _pendingApproval[index]['status'] = 'rejected';
      _pendingApproval[index]['rejectionReason'] = reason;
      notifyListeners();
    }
  }

  /// Allows a user to clear their rejected submission to try again.
  void clearRejectedSubmission(String username) {
    _pendingApproval.removeWhere(
      (p) => p['submittedBy'] == username && p['status'] == 'rejected',
    );
    notifyListeners();
  }

  Future<void> updateFamily(String id, Map<String, dynamic> familyData, {String? token}) async { 
    try {
      await _service.updateFamily(id, familyData, token);
      final index = _families.indexWhere((f) => f['id'] == id);
      if (index != -1) {
        _families[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error updating family: $e");
      rethrow;
    }
  }

  Future<void> deleteFamily(String id, {String? token}) async {
    try {
      await _service.deleteFamily(id, token);
      _families.removeWhere((f) => f['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error deleting family: $e");
      rethrow;
    }
  }
}
