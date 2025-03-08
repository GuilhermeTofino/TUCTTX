import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Mensalidade extends StatelessWidget {
  const Mensalidade({super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> mensalidades =
        ModalRoute.of(context)!.settings.arguments as List<dynamic>;

    final mesLabels = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];

    final now = DateTime.now();
    final currentMonth = now.month - 1;

    int pagas = 0;
    int vencidas = 0;
    int pendentes = 0;

    for (int i = 0; i < mensalidades.length; i++) {
      if (mensalidades[i]) {
        pagas++;
      } else if (i < currentMonth) {
        vencidas++;
      } else {
        pendentes++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensalidades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('✅ Pagas: $pagas'),
                Text('❌ Vencidas: $vencidas'),
                Text('⏳ Pendentes: $pendentes'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: mensalidades.length,
              itemBuilder: (context, index) {
                final bool isPaid = mensalidades[index];
                final String mesLabel = mesLabels[index];

                IconData icon;
                Color iconColor;

                if (index < currentMonth) {
                  icon = isPaid ? Icons.check_circle : Icons.cancel;
                  iconColor = isPaid ? Colors.green : Colors.red;
                } else {
                  icon = isPaid ? Icons.check_circle : Icons.hourglass_bottom;
                  iconColor = isPaid ? Colors.green : Colors.amber;
                }

                return ListTile(
                  title: Text(mesLabel),
                  trailing: Icon(icon, color: iconColor),
                  onTap: (!isPaid)
                      ? () async {
                          String pixKey = 'tucttx@gmail.com';
                          await Clipboard.setData(ClipboardData(text: pixKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chave Pix copiada!')),
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
