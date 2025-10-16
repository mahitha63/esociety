import 'package:flutter/material.dart';
import '../services/family_service.dart';

class FamilyProvider with ChangeNotifier {
  final FamilyService _service = FamilyService();

  // --- Dummy Data for Demonstration ---
  // Pre-populating with data to show different states on the Families screen.
  // This will be replaced by API calls.
  List<Map<String, dynamic>> _families = [
    {
      'id': 'fam_001',
      'name': 'R Sharma',
      'flatNumber': 'A-101',
      'members': 4,
      'submittedBy': 'sharma',
    },
    {
      'id': 'fam_002',
      'name': 'Singh',
      'flatNumber': 'A-102',
      'members': 3,
      'submittedBy': 'singh',
    },
    {
      'id': 'fam_003',
      'name': 'Patel',
      'flatNumber': 'B-204',
      'members': 2,
      'submittedBy': 'patel',
    },
    {
      'id': 'fam_004',
      'name': 'Khan',
      'flatNumber': 'C-301',
      'members': 5,
      'submittedBy': 'khan',
    },
  ];
  List<Map<String, dynamic>> get families => _families;

  final List<Map<String, dynamic>> _pendingApproval = [
    {
      'id': 'fam_pending_001',
      'name': 'Gupta',
      'flatNumber': 'D-405',
      'members': 5,
      'submittedBy': 'gupta',
      'status': 'pending', // This family is awaiting admin approval.
    },
    {
      'id': 'fam_rejected_001',
      'name': 'Sharma', // A second submission from the same user
      'flatNumber': 'A-101',
      'members': 2, // e.g., they tried to submit with incorrect data
      'submittedBy': 'sharma',
      'status': 'rejected', // This request was rejected by the admin.
      'rejectionReason': 'Duplicate submission. Family already exists.',
    },
  ];
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
      return _pendingApproval.firstWhere((p) => p['submittedBy'] == username);
    } catch (e) {
      return null; // No pending submission found
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
