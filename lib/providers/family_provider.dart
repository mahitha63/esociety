import 'package:flutter/material.dart';
import '../services/family_service.dart';

class FamilyProvider with ChangeNotifier {
  final FamilyService _service = FamilyService();

  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> get families => _families;

  List<Map<String, dynamic>> _pendingApproval = [];
  List<Map<String, dynamic>> get pendingApproval => _pendingApproval;

  Future<void> loadFamilies() async {
    try {
      _families = await _service.fetchFamilies();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Helper to check if a user has a pending submission
  Map<String, dynamic>? getPendingSubmissionForUser(String username) {
    try {
      // Find any submission (pending or rejected) that isn't approved yet.
      return _pendingApproval.firstWhere(
        (p) => p['submittedBy'] == username,
      );
    } catch (e) {
      return null; // No pending submission found
    }
  }

  // Helper to check if a user has an approved family
  bool hasApprovedFamily(String username) {
    // This logic assumes the family name is tied to the username.
    // A more robust implementation would use a dedicated 'ownerId' field.
    return _families
        .any((f) => (f['name'] as String).toLowerCase().contains(username));
  }

  Future<void> addFamily(Map<String, dynamic> familyData) async {
    try {
      // Maker adds → goes to pending approval
      // Add a 'status' field to track the state.
      _pendingApproval.add({...familyData, 'status': 'pending'});
      notifyListeners();
    } catch (e) {
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

  Future<void> updateFamily(String id, Map<String, dynamic> familyData) async {
    try {
      await _service.updateFamily(id, familyData);
      final index = _families.indexWhere((f) => f['id'] == id);
      if (index != -1) {
        _families[index] = familyData;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFamily(String id) async {
    try {
      await _service.deleteFamily(id);
      _families.removeWhere((f) => f['id'] == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
