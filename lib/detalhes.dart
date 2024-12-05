import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetalhesFilho extends StatefulWidget {
  const DetalhesFilho({super.key});

  @override
  State<DetalhesFilho> createState() => _DetalhesFilhoState();
}

class _DetalhesFilhoState extends State<DetalhesFilho> {
  // Labels para os meses das mensalidades
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
    "Dezembro"
  ];

  // Define a lista de chaves na ordem desejada para exibição
  final _orderedKeys = [
    'nome',
    'login_key',
    'data_nascimento',
    'idade',
    'numero_emergencia',
    'tirou_santo',
    'orixa_de_frente',
    'Orixa_junto',
  ];

  @override
  Widget build(BuildContext context) {
    final filhoData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (filhoData == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Dados do filho não encontrados.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Filho')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Filhos')
            .doc(filhoData['nome'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo deu errado'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Filho não encontrado.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final mensalidades = data['mensalidade'] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._orderedKeys.map((key) {
                  if (data.containsKey(key) && key != 'mensalidade') {
                    return _buildDetailRow(key, data[key]);
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                const SizedBox(height: 16),
                const Text('Mensalidades:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mensalidades.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(mesLabels[index]),
                      trailing: Switch(
                        value: mensalidades[index],
                        onChanged: (value) {
                          _atualizarMensalidade(
                              filhoData['nome'], index, value);
                        },
                        activeColor: Colors.green, // Cor quando ativo (ligado)
                        inactiveThumbColor: Colors
                            .red, // Cor do círculo quando inativo (desligado)
                        inactiveTrackColor:
                            Colors.red.shade200, // Cor da faixa quando inativo
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _atualizarMensalidade(
      String nomeFilho, int index, bool value) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Filhos')
          .doc(nomeFilho)
          .get();

      if (doc.exists) {
        List<dynamic> mensalidades = doc.get('mensalidade');
        if (index >= 0 && index < mensalidades.length) {
          List<bool> updatedMensalidades =
              mensalidades.map<bool>((dynamic e) => e as bool).toList();

          updatedMensalidades[index] = value;

          await FirebaseFirestore.instance
              .collection('Filhos')
              .doc(nomeFilho)
              .update({
            'mensalidade': updatedMensalidades,
          });
          print('Mensalidade atualizada com sucesso!');

          setState(() {});
        } else {
          print("Invalid index or the field 'mensalidade' is not a list");
        }
      } else {
        print("Document not found");
      }
    } catch (error) {
      print('Erro ao atualizar mensalidade: $error');
    }
  }

  Widget _buildDetailRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('${_formatarLabel(key)}:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(value.toString())),
        ],
      ),
    );
  }

  String _formatarLabel(String key) {
    switch (key) {
      case 'numero_emergencia':
        return 'Número de Emergência';
      case 'orixa_de_frente':
        return 'Orixá de Frente';
      case 'Orixa_junto':
        return 'Orixá Juntó';
      case 'idade':
        return 'Idade';
      case 'data_nascimento':
        return 'Data de Nascimento';
      case 'login_key':
        return 'Nome Login';
      case 'nome':
        return 'Nome Completo';
      case 'tirou_santo':
        return 'Tirou Santo?';
      default:
        return key;
    }
  }
}
