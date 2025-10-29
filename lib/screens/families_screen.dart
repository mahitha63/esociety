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
  final _formKey = GlobalKey<FormState>();

  // Controllers for all 6 fields
  final _familyIdController = TextEditingController();
  final _wardIdController = TextEditingController();
  final _headNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _membersCountController = TextEditingController();
  final _monthlyFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<FamilyProvider>(context, listen: false).loadFamilies(),
    );
  }

  @override
  void dispose() {
    _familyIdController.dispose();
    _wardIdController.dispose();
    _headNameController.dispose();
    _addressController.dispose();
    _membersCountController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username!;

    // Load families on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (familyProvider.families.isEmpty) {
        familyProvider.loadFamilies(token: authProvider.token);
      }
    });

    // Check the user's status
    final pendingSubmission = familyProvider.getPendingSubmissionForUser(
      username,
    );
    final hasApproved = familyProvider.hasApprovedFamily(username);

    return Scaffold(
      backgroundColor: const Color(0xFFD6D3D3),
      appBar: AppBar(
        title: const Text("Families"),
        backgroundColor: Colors.blue[800],
      ),
      body: RefreshIndicator(
        onRefresh: familyProvider.loadFamilies,
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
                title: Text(family['headName'] ?? 'No Head Name'),
                subtitle: Text(
                  "Family ID: ${family['familyId'] ?? 'N/A'} • Ward: ${family['wardId'] ?? 'N/A'}\n"
                  "Address: ${family['address'] ?? 'N/A'} • Members: ${family['membersCount'] ?? 0}\n"
                  "Monthly Fee: ₹${family['monthlyFee'] ?? 0}",
                ),
                trailing: authProvider.isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _editFamily(context, family, familyProvider),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFamily(
                              context,
                              family['familyId'],
                              familyProvider,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () =>
            _showAddFamilyDialog(context, familyProvider, username),
      ),
    );
  }

  void _showAddFamilyDialog(
    BuildContext context,
    FamilyProvider provider,
    String username,
  ) {
    _familyIdController.clear();
    _wardIdController.clear();
    _headNameController.clear();
    _addressController.clear();
    _membersCountController.clear();
    _monthlyFeeController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Family'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _familyIdController,
                  decoration: const InputDecoration(labelText: 'Family ID'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter Family ID' : null,
                ),
                TextFormField(
                  controller: _wardIdController,
                  decoration: const InputDecoration(labelText: 'Ward ID'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter Ward ID' : null,
                ),
                TextFormField(
                  controller: _headNameController,
                  decoration: const InputDecoration(labelText: 'Head Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter Head Name' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: _membersCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Members',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter member count'
                      : null,
                ),
                TextFormField(
                  controller: _monthlyFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fee (₹)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter monthly fee'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                provider.addFamily({
                  'familyId': _familyIdController.text,
                  'wardId': _wardIdController.text,
                  'headName': _headNameController.text,
                  'address': _addressController.text,
                  'membersCount': int.parse(_membersCountController.text),
                  'monthlyFee': double.parse(_monthlyFeeController.text),
                  'submittedBy': username,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editFamily(
    BuildContext context,
    Map<String, dynamic> family,
    FamilyProvider provider,
  ) {
    final headNameController = TextEditingController(text: family['headName']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Family Head"),
        content: TextField(
          controller: headNameController,
          decoration: const InputDecoration(labelText: 'Head Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update the family info in the provider
              familyProvider.updateFamily(
                family['id'],
                family,
                token: Provider.of<AuthProvider>(context, listen: false).token,
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteFamily(BuildContext context, String id, FamilyProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Family"),
        content: const Text("Are you sure you want to delete this family?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              familyProvider.deleteFamily(
                familyId,
                token: Provider.of<AuthProvider>(context, listen: false).token,
              );
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
      }, token: Provider.of<AuthProvider>(context, listen: false).token);
      Navigator.of(dialogContext).pop(); // Close the dialog
    }
  }
}
