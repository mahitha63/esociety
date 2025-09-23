import 'package:flutter/material.dart';

// A simple data model for a transaction with dummy data
class _Transaction {
  final String title;
  final String date;
  final String amount;
  final bool isDebit;

  const _Transaction({
    required this.title,
    required this.date,
    required this.amount,
    this.isDebit = true,
  });
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // Dummy data for the transaction list
  // This will be replaced with data from your mock API in a future step.
  final List<_Transaction> _transactions = const [
    _Transaction(
      title: 'Monthly Maintenance',
      date: '01 Nov 2023',
      amount: '\$150.00',
    ),
    _Transaction(
      title: 'Gym Access Fee',
      date: '25 Oct 2023',
      amount: '\$25.00',
    ),
    _Transaction(
      title: 'Late Fee Payment',
      date: '15 Oct 2023',
      amount: '\$10.00',
    ),
    _Transaction(
      title: 'Clubhouse Booking',
      date: '05 Oct 2023',
      amount: '\$50.00',
    ),
    _Transaction(
      title: 'Previous Dues Credit',
      date: '02 Oct 2023',
      amount: '\$30.00',
      isDebit: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _transactions.length, // Use the state's list
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: ListTile(
            leading: Icon(
              transaction.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction.isDebit ? Colors.red : Colors.green,
            ),
            title: Text(transaction.title),
            subtitle: Text(transaction.date),
            trailing: Text(
              '${transaction.isDebit ? '-' : '+'}${transaction.amount}',
              style: TextStyle(
                color: transaction.isDebit ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
