import 'package:app_tenda/colors.dart';
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
          final alergias = data['alergias'] as List<dynamic>;

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

                // Seção para exibir as alergias
                if (alergias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Alergias:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        alergias.map((alergia) => Text('- $alergia')).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text('Alergias:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                      'Nenhuma alergia informada.'), // Texto para lista vazia
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mensalidades:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      iconSize: 15,
                      onPressed: () {
                        _mostrarDialogoConfirmacao(filhoData['nome']);
                      },
                      icon: const Icon(Icons.refresh, color: kPrimaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kPrimaryColor),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Número de colunas no grid
                    childAspectRatio: 2, // Proporção largura/altura dos itens
                  ),
                  itemCount: mensalidades.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Text(
                          mesLabels[index],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center, // Centraliza o texto
                        ),
                        Switch(
                          value: mensalidades[index],
                          onChanged: (value) {
                            _atualizarMensalidade(
                                filhoData['nome'], index, value);
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          inactiveTrackColor: Colors.red.shade200,
                        ),
                      ],
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

  void _mostrarDialogoConfirmacao(String nomeFilho) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmação"),
          content: Text(
              "Tem certeza que deseja resetar todas as mensalidades de $nomeFilho?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Não"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Sim"),
              onPressed: () {
                _zerarTodasMensalidades(nomeFilho);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _zerarTodasMensalidades(String nomeFilho) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Filhos')
          .doc(nomeFilho)
          .get();

      if (doc.exists) {
        List<dynamic> mensalidades = doc.get('mensalidade');

        List<bool> updatedMensalidades =
            List.generate(mensalidades.length, (index) => false);

        await FirebaseFirestore.instance
            .collection('Filhos')
            .doc(nomeFilho)
            .update({'mensalidade': updatedMensalidades});

        setState(() {});
      } else {
        print("Document not found");
      }
    } catch (e) {
      print('Error updating document: $e');
    }
  }

 Future<void> _atualizarMensalidade(String nomeFilho, int index, bool pago) async {
  double mensalidadeValor = 0.0; // Valor digitado pelo usuário

  if (pago) {
    TextEditingController valorController = TextEditingController();

    bool confirmado = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Valor da Mensalidade"),
          content: TextField(
            controller: valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Digite o valor pago"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancela
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (valorController.text.isNotEmpty) {
                  mensalidadeValor = double.tryParse(valorController.text) ?? 0.0;
                  if (mensalidadeValor > 0) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );

    if (!confirmado) return; // Se cancelar, não faz nada
  }

  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('Filhos')
        .doc(nomeFilho)
        .get();

    if (doc.exists) {
      List<dynamic> mensalidades = doc.get('mensalidade');
      double totalArrecadado = 0.0;

      // Buscar o total arrecadado do Firestore
      DocumentSnapshot financeiroSnapshot =
          await FirebaseFirestore.instance.collection("financeiro").doc("dados").get();
      if (financeiroSnapshot.exists) {
        totalArrecadado = financeiroSnapshot["totalArrecadado"] ?? 0.0;
      }

      // Atualizar o estado da mensalidade
      mensalidades[index] = pago;

      // Atualizar o total arrecadado
      totalArrecadado = pago ? totalArrecadado + mensalidadeValor : totalArrecadado - mensalidadeValor;

      // Atualizar Firestore - Mensalidade do Filho
      await FirebaseFirestore.instance.collection("Filhos").doc(nomeFilho).update({
        "mensalidade": mensalidades,
      });

      // Atualizar Firestore - Total Arrecadado
      await FirebaseFirestore.instance.collection("financeiro").doc("dados").update({
        "totalArrecadado": totalArrecadado,
      });

      // Atualizar UI
      setState(() {});

      // Exibir notificação de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mensalidade de ${mesLabels[index]} atualizada!")),
      );
    }
  } catch (error) {
    print('Erro ao atualizar mensalidade: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao atualizar mensalidade.')),
    );
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
