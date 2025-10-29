import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    final username = authProvider.username ?? "User";

    return Scaffold(
      backgroundColor: const Color(0xFFD6D3D3),
      appBar: AppBar(
        title: const Text("Families"),
        backgroundColor: Colors.blue[800],
      ),
      body: familyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editFamilyDialog(
                                    context,
                                    family,
                                    familyProvider,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteFamilyDialog(
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
        onPressed: () => _showAddFamilyDialog(context, familyProvider),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Add Family Dialog
  void _showAddFamilyDialog(
    BuildContext context,
    FamilyProvider familyProvider,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _familyIdController,
                  decoration: const InputDecoration(labelText: 'Family ID'),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter Family ID' : null,
                ),
                TextFormField(
                  controller: _wardIdController,
                  decoration: const InputDecoration(labelText: 'Ward ID'),
                  validator: (v) => v!.isEmpty ? 'Please enter Ward ID' : null,
                ),
                TextFormField(
                  controller: _headNameController,
                  decoration: const InputDecoration(labelText: 'Head Name'),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter Head Name' : null,
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
                  validator: (v) =>
                      v!.isEmpty ? 'Enter number of members' : null,
                ),
                TextFormField(
                  controller: _monthlyFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fee (₹)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter monthly fee' : null,
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await familyProvider.addFamily({
                  "familyId": _familyIdController.text,
                  "wardId": _wardIdController.text,
                  "headName": _headNameController.text,
                  "address": _addressController.text,
                  "membersCount": int.parse(_membersCountController.text),
                  "monthlyFee": double.parse(_monthlyFeeController.text),
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Edit Family Dialog
  void _editFamilyDialog(
    BuildContext context,
    Map<String, dynamic> family,
    FamilyProvider provider,
  ) {
    final headController = TextEditingController(text: family['headName']);
    final addressController = TextEditingController(text: family['address']);
    final feeController = TextEditingController(
      text: family['monthlyFee'].toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Family'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: headController,
                decoration: const InputDecoration(labelText: 'Head Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: feeController,
                decoration: const InputDecoration(labelText: 'Monthly Fee (₹)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateFamily(family['familyId'], {
                "wardId": family['wardId'],
                "headName": headController.text,
                "address": addressController.text,
                "membersCount": family['membersCount'],
                "monthlyFee": double.tryParse(feeController.text) ?? 0,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Delete Family Dialog
  void _deleteFamilyDialog(
    BuildContext context,
    String id,
    FamilyProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text('Are you sure you want to delete this family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteFamily(id);
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
