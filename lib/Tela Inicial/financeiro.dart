import 'package:app_tenda/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting

class Financeiro extends StatefulWidget {
  const Financeiro({super.key});

  @override
  State<Financeiro> createState() => _FinanceiroState();
}

class _FinanceiroState extends State<Financeiro> {
  // Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  double mensalidadeGoal = 4000.0;
  double mensalidadeCollected = 0.0;
  double kujibaGoal = 8000.0;
  double kujibaCollected = 0.0;

  TextEditingController mensalidadeController = TextEditingController();
  TextEditingController kujibaController = TextEditingController();

  String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Map<String, dynamic>? lastMonthData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      DocumentSnapshot financeiroSnapshot =
          await firestore.collection('financeiro').doc('data').get();

      if (financeiroSnapshot.exists) {
        Map<String, dynamic> data =
            financeiroSnapshot.data() as Map<String, dynamic>;

        mensalidadeCollected = (data['mensalidadeCollected'] ?? 0.0).toDouble();
        kujibaCollected = (data['kujibaCollected'] ?? 0.0).toDouble();

        List<dynamic> reports = data["monthlyReports"];

        if (reports.isNotEmpty) {
          for (var report in reports) {
            if (report['month'] == currentMonth) {
              mensalidadeCollected = report['mensalidadeCollected'].toDouble();

              kujibaCollected = report['kujibaCollected'].toDouble();
            } else {
              lastMonthData = report;
            }
          }
        }
      }

      mensalidadeController.text = mensalidadeCollected.toStringAsFixed(2);
      kujibaController.text = kujibaCollected.toStringAsFixed(2);

      setState(() {});
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _updateBackend(String title, double newValue) async {
    try {
      await firestore.collection('financeiro').doc('data').update({
        title == 'mensalidadeCollected'
            ? 'mensalidadeCollected'
            : 'kujibaCollected': newValue,
      });
    } catch (e) {
      print('Error updating Firestore: $e');
      // Handle error (e.g., show a snackbar)
    }
  }

  Future<void> _resetMensalidade() async {
    try {
      DocumentSnapshot doc =
          await firestore.collection('financeiro').doc('data').get();

      if (!doc.exists) {
        // Document doesn't exist, create it with initial data
        await firestore.collection('financeiro').doc('data').set({
          'mensalidadeCollected': 0.0,
          'kujibaCollected': kujibaCollected, // Keep kujiba as it is
          'monthlyReports': [], // Initialize as an empty array
        });

        // Re-fetch the document after creating it
        doc = await firestore.collection('financeiro').doc('data').get();
      }
      // Now doc.data() should not be null

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> monthlyReports = data['monthlyReports'] ?? [];

      monthlyReports.add({
        'month': currentMonth,
        'mensalidadeCollected': mensalidadeCollected,
        'kujibaCollected': kujibaCollected,
      });

      await firestore.collection('financeiro').doc('data').update({
        'mensalidadeCollected': 0.0,
        'monthlyReports': monthlyReports,
      });

      mensalidadeCollected = 0.0;
      mensalidadeController.text = '0.00';

      setState(() {});
    } catch (e) {
      print("Error resetting mensalidade: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error resetting mensalidade.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _resetMensalidade,
            icon: const Icon(Icons.refresh), // Example reset icon
            tooltip: 'Reset Monthly Value', // Add a tooltip
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProgressCard('Mensalidade', mensalidadeGoal,
                mensalidadeCollected, mensalidadeController),
            const SizedBox(height: 20),
            _buildProgressCard(
                'Kujiba', kujibaGoal, kujibaCollected, kujibaController),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String title, double goal, double collected,
      TextEditingController controller) {
    double percent =
        goal > 0 ? (collected / goal) * 100 : (collected > 0 ? 100 : 0);
    String formattedPercent = percent.toStringAsFixed(1);

    if (percent.isInfinite) {
      formattedPercent = collected > 0 ? '100.0' : '0.0';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    if (title == 'Mensalidade') {
                      mensalidadeCollected = double.tryParse(value) ?? 0.0;
                    } else if (title == 'Kujiba') {
                      kujibaCollected = double.tryParse(value) ?? 0.0;
                    }

                    setState(() {}); // Trigger rebuild to update progress bar

                    _updateBackend(
                        title == 'Mensalidade'
                            ? 'mensalidadeCollected'
                            : 'kujibaCollected',
                        double.tryParse(value) ?? 0.0);
                  },
                )),
              ],
            ),
            LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              minHeight: 10,
            ),
            const SizedBox(height: 10),
            Text(
                'R\$ ${collected.toStringAsFixed(2)} / R\$ ${goal.toStringAsFixed(2)}  ($formattedPercent%)',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
