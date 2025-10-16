import 'package:flutter_test/flutter_test.dart';
import 'package:esociety/providers/family_provider.dart';

void main() {
  // Group of tests for the FamilyProvider
  group('FamilyProvider Unit Tests', () {
    late FamilyProvider familyProvider;

    // This function runs before each test, ensuring a clean state.
    setUp(() {
      familyProvider = FamilyProvider();
    });

    test('Initial dummy data is loaded correctly', () {
      expect(
        familyProvider.families.length,
        4,
        reason: "Should start with 4 approved families",
      );
      expect(
        familyProvider.pendingApproval.length,
        2,
        reason: "Should start with 2 pending/rejected families",
      );
    });

    test(
      'addFamily should add a new family to the pending approval list',
      () async {
        final newFamilyData = {
          'id': 'fam_test_001',
          'name': 'TestFamily',
          'flatNumber': 'T-101',
          'members': 3,
          'submittedBy': 'tester',
        };

        await familyProvider.addFamily(newFamilyData);

        // Verify the pending list has grown
        expect(familyProvider.pendingApproval.length, 3);

        // Verify the newly added family is in the list and has a 'pending' status
        final addedFamily = familyProvider.pendingApproval.last;
        expect(addedFamily['name'], 'TestFamily');
        expect(addedFamily['status'], 'pending');
      },
    );

    test('approveFamily should move a family from pending to approved', () {
      // The first family in the dummy data is 'Gupta', which is pending.
      final familyToApprove = familyProvider.pendingApproval[0];
      final initialApprovedCount = familyProvider.families.length;

      // The provider's method uses an index.
      familyProvider.approveFamily(0);

      // Check that the approved list has grown and the pending list has shrunk.
      expect(familyProvider.families.length, initialApprovedCount + 1);
      expect(familyProvider.pendingApproval.length, 1);

      // Verify the correct family was moved.
      expect(familyProvider.families.last['name'], familyToApprove['name']);
      expect(
        familyProvider.pendingApproval.any(
          (p) => p['id'] == familyToApprove['id'],
        ),
        isFalse,
      );
    });

    test('rejectFamily should update a pending submission with a reason', () {
      // The first family in the dummy data is 'Gupta', which is pending.
      const familyToRejectId = 'fam_pending_001';
      const reason = 'Incomplete information';

      familyProvider.rejectFamily(familyToRejectId, reason);

      // Find the family in the pending list.
      final rejectedFamily = familyProvider.pendingApproval.firstWhere(
        (p) => p['id'] == familyToRejectId,
      );

      // Verify its status and reason have been updated.
      expect(rejectedFamily['status'], 'rejected');
      expect(rejectedFamily['rejectionReason'], reason);
    });
  });
}
