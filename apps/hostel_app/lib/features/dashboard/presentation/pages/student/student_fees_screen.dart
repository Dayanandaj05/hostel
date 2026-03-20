import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hostel_app/app/app_routes.dart';
import 'package:hostel_app/features/auth/presentation/controllers/auth_provider_controller.dart';

class StudentFeesScreen extends StatelessWidget {
  const StudentFeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderController.of(context);
    final uid = auth.user?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        foregroundColor: Colors.white,
        title: const Text('Fees & Payments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(AppRoutes.studentHome),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final establishment = (data['establishmentFee'] ?? 50000) as int;
          final deposit = (data['depositFee'] ?? 5000) as int;
          final paid = (data['feesPaid'] ?? 0) as int;
          final balance = (data['feesBalance'] ?? (establishment + deposit - paid)) as int;
          final total = establishment + deposit;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Section
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Total Fees', currencyFormat.format(total), Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('Paid', currencyFormat.format(paid), Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('Balance', currencyFormat.format(balance), Colors.orange)),
                  ],
                ),
                const SizedBox(height: 24),

                // Detailed Breakdown
                const Text('Fee Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                const SizedBox(height: 12),
                _buildBreakdownCard(establishment, deposit, paid, balance, total, currencyFormat),
                const SizedBox(height: 24),

                // Payment History
                const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2137))),
                const SizedBox(height: 12),
                _buildPaymentHistory(uid, currencyFormat),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => _showPayNowDialog(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('PAY NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(int est, int dep, int paid, int bal, int total, NumberFormat fmt) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow('Establishment Fees', fmt.format(est)),
            _buildDetailRow('Hostel Deposit', fmt.format(dep)),
            const Divider(height: 24),
            _buildDetailRow('Total Fees', fmt.format(total), isBold: true),
            _buildDetailRow('Amount Paid', '- ${fmt.format(paid)}', color: Colors.green),
            const Divider(height: 24),
            _buildDetailRow('Outstanding Balance', fmt.format(bal), color: Colors.orange, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(String uid, NumberFormat fmt) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fee_payments')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No payment records found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final amount = (data['amount'] ?? 0) as int;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_rounded, color: Colors.blue, size: 20),
                ),
                title: Text(data['description'] ?? 'Fee Payment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${DateFormat('dd MMM yyyy').format(date)} • Ref: ${data['receiptNumber'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                trailing: Text(fmt.format(amount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  void _showPayNowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Online Payment'),
        content: const Text('Online payment integration coming soon. Please visit the hostel office for payments.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
