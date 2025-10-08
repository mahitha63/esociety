// TODO Implement this library.
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
                                // TODO: Open edit dialog
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                familyProvider.deleteFamily(family['id']);
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
          // Example: add dummy family
          familyProvider.addFamily({
            'id': DateTime.now().toString(),
            'name': 'New Family',
            'members': 4,
          });
        },
      ),
    );
  }
}
