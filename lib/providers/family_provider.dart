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

  Future<void> addFamily(Map<String, dynamic> familyData) async {
    try {
      // Maker adds → goes to pending approval
      _pendingApproval.add(familyData);
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

  void rejectFamily(int index) {
    _pendingApproval.removeAt(index);
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
