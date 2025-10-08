import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';

class FamiliesScreen extends StatelessWidget {
  static const routeName = '/families';

  const FamiliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);

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
          children: [
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
                      title: Text(family['name'] ?? 'Unknown Family'),
                      subtitle: Text("Members: ${family['members'] ?? 0}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Open edit dialog or navigate to another screen
                                _editFamily(context, family, familyProvider);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                      ),
                    ),
                  );
                },
              ),
            ),
            if (familyProvider.pendingApproval.isNotEmpty) ...[
              const Divider(),
              const Text(
                "Pending Approval",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: familyProvider.pendingApproval.length,
                  itemBuilder: (ctx, index) {
                    final pending = familyProvider.pendingApproval[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(pending['name'] ?? 'New Family'),
                        subtitle: const Text("Awaiting approval..."),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                familyProvider.approveFamily(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                familyProvider.rejectFamily(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 228, 228, 228),
        child: const Icon(Icons.add),
        onPressed: () {
          _addFamily(context, familyProvider);
        },
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

  // Add Family (Dummy Data for Example)
  void _addFamily(BuildContext context, FamilyProvider familyProvider) {
    familyProvider.addFamily({
      'id': DateTime.now().toString(),
      'name': 'New Family',
      'members': 4,
    });
  }
}
