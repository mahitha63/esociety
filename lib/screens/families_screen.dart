import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/family_provider.dart';
import '../providers/auth_provider.dart';

class FamiliesScreen extends StatefulWidget {
  static const routeName = '/families';

  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  // Form key and controllers for the "Add Family" dialog
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _flatController = TextEditingController();
  final _membersController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _nameController.dispose();
    _flatController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username!;

    // Check the user's status
    final pendingSubmission = familyProvider.getPendingSubmissionForUser(
      username,
    );
    final hasApproved = familyProvider.hasApprovedFamily(username);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 214, 211, 211),
      appBar: AppBar(
        title: const Text("Families"),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromARGB(255, 214, 211, 211), // ✅ force full bg
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!authProvider.isAdmin &&
                pendingSubmission != null &&
                pendingSubmission['status'] != 'approved')
              _buildPendingStatusCard(pendingSubmission),
            Expanded(
              child: ListView.builder(
                itemCount: familyProvider.families.length,
                itemBuilder: (ctx, index) {
                  final family = familyProvider.families[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(family['name'] ?? 'No Name'),
                      subtitle: Text(
                        "Flat: ${family['flatNumber'] ?? 'N/A'} • Members: ${family['members'] ?? 0}",
                      ),
                      trailing: authProvider.isAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      _editFamily(
                                        context,
                                        family,
                                        familyProvider,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _deleteFamily(
                                        context,
                                        family['id'],
                                        familyProvider,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : null, // No trailing widget for non-admins
                    ),
                  );
                },
              ),
            ),
            // "Pending Approval" section is only visible to admins
            if (authProvider.isAdmin &&
                familyProvider.pendingApproval.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Pending Approval",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: familyProvider.pendingApproval.length,
                  itemBuilder: (ctx, index) {
                    final pending = familyProvider.pendingApproval[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        onTap: () => _showApprovalDetailsDialog(
                          context,
                          pending,
                          familyProvider,
                        ),
                        title: Text(pending['name'] ?? 'New Family'),
                        subtitle: const Text("Awaiting approval..."),
                        trailing: const Icon(Icons.visibility),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      // The "Add" button is only visible to admins
      floatingActionButton: _buildFloatingActionButton(
        context,
        authProvider,
        familyProvider,
        pendingSubmission,
        hasApproved,
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    AuthProvider authProvider,
    FamilyProvider familyProvider,
    Map<String, dynamic>? pendingSubmission,
    bool hasApproved,
  ) {
    // Show FAB for admin and for regular users.
    // This ensures users can always access the form.
    if (authProvider.isAdmin || !authProvider.isAdmin) {
      return FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 228, 228, 228),
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddFamilyDialog(context, familyProvider);
        },
      );
    }
    return null;
  }

  Widget _buildPendingStatusCard(Map<String, dynamic> submission) {
    if (submission['status'] == 'rejected') {
      return Card(
        color: Colors.red[50],
        margin: const EdgeInsets.all(16),
        child: ListTile(
          leading: Icon(Icons.cancel, color: Colors.red),
          title: Text(
            'Submission Rejected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          subtitle: Text(
            'Reason: ${submission['rejectionReason'] ?? 'No reason provided.'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss and try again',
            onPressed: () {
              Provider.of<FamilyProvider>(
                context,
                listen: false,
              ).clearRejectedSubmission(
                Provider.of<AuthProvider>(context, listen: false).username!,
              );
            },
          ),
        ),
      );
    }

    // Default 'pending' card
    return Card(
      color: Colors.orange[50],
      margin: const EdgeInsets.all(16),
      child: const ListTile(
        leading: Icon(Icons.hourglass_top, color: Colors.orange),
        title: Text(
          'Submission Pending',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Your family details are awaiting admin approval.'),
      ),
    );
  }

  // Show a dialog for the admin to view details before approval/rejection
  void _showApprovalDetailsDialog(
    BuildContext context,
    Map<String, dynamic> pending,
    FamilyProvider familyProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Family Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Family Name', pending['name'] ?? 'N/A'),
              _buildDetailRow('Flat Number', pending['flatNumber'] ?? 'N/A'),
              _buildDetailRow('Members', (pending['members'] ?? 0).toString()),
              _buildDetailRow('Submitted By', pending['submittedBy'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close this dialog first
              _showRejectionDialog(context, pending['id'], familyProvider);
            },
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // The provider uses index, so we need to find it.
              // A better approach would be for the provider to accept an ID.
              final index = familyProvider.pendingApproval.indexWhere(
                (p) => p['id'] == pending['id'],
              );
              if (index != -1) {
                familyProvider.approveFamily(index);
              }
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  // Helper widget to build detail rows in the dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Show a dialog for the admin to enter a rejection reason
  void _showRejectionDialog(
    BuildContext context,
    String id,
    FamilyProvider familyProvider,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Submission'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            hintText: 'e.g., Incomplete details',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                familyProvider.rejectFamily(id, reasonController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Edit Family Functionality
  void _editFamily(
    BuildContext context,
    Map<String, dynamic> family,
    FamilyProvider familyProvider,
  ) {
    // You can open a dialog or navigate to another screen to edit the family
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Family"),
        content: TextField(
          controller: TextEditingController(text: family['name']),
          decoration: const InputDecoration(labelText: 'Family Name'),
          onChanged: (value) {
            family['name'] = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update the family info in the provider
              familyProvider.updateFamily(family['id'], family);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete Family with Confirmation
  void _deleteFamily(
    BuildContext context,
    String familyId,
    FamilyProvider familyProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Family"),
        content: const Text("Are you sure you want to delete this family?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              familyProvider.deleteFamily(familyId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show a dialog with a form to add a new family
  void _showAddFamilyDialog(
    BuildContext context,
    FamilyProvider familyProvider,
  ) {
    // Clear controllers for new entry
    _nameController.clear();
    _flatController.clear();
    _membersController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Family'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Family Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _flatController,
                  decoration: const InputDecoration(labelText: 'Flat Number'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a flat number.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _membersController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Members',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter member count.';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitFamilyData(ctx, familyProvider),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submitFamilyData(
    BuildContext dialogContext,
    FamilyProvider familyProvider,
  ) {
    if (_formKey.currentState!.validate()) {
      final username = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).username;
      familyProvider.addFamily({
        'id': DateTime.now().toString(), // Use a unique ID in a real app
        'name': _nameController.text,
        'flatNumber': _flatController.text,
        'members': int.parse(_membersController.text),
        'submittedBy': username, // Track who submitted the request
      });
      Navigator.of(dialogContext).pop(); // Close the dialog
    }
  }
}
