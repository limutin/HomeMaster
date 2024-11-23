import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeownersTable extends StatelessWidget {
  const HomeownersTable({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('homeowners')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeowners = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Contact')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Actions')),
            ],
            rows: homeowners.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(Text(data['fullName'] ?? 'N/A')),
                  DataCell(Text(data['email'] ?? 'N/A')),
                  DataCell(Text(data['contact'] ?? 'N/A')),
                  DataCell(Text(data['address'] ?? 'N/A')),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(context, doc.id),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String homeownerId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('homeowners')
                    .doc(homeownerId)
                    .delete();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
