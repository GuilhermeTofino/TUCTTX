import 'package:app_tenda/entrar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tenda/widgets/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntidadeDetailScreen extends StatelessWidget {
  final String entidade;

  const EntidadeDetailScreen({super.key, required this.entidade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entidade, style: GoogleFonts.lato(color: kPrimaryColor)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entidades')
            .doc(entidade)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Nenhuma Entidade encontrada.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> membros = data['membros'] ?? [];

          membros.sort((a, b) {
            String mediumA = (a['medium'] ?? '').toString().toLowerCase();
            String mediumB = (b['medium'] ?? '').toString().toLowerCase();
            bool aIsSpecial = (mediumA == 'pai' || mediumA == 'mãe');
            bool bIsSpecial = (mediumB == 'pai' || mediumB == 'mãe');
            if (aIsSpecial && bIsSpecial) {
              if (mediumA == mediumB) return 0;
              if (mediumA == 'pai') return -1;
              if (mediumA == 'mãe') return 1;
            }
            if (aIsSpecial && !bIsSpecial) return -1;
            if (!aIsSpecial && bIsSpecial) return 1;
            return mediumA.compareTo(mediumB);
          });

          if (membros.isEmpty) {
            return const Center(child: Text('Nenhum membro encontrado.'));
          }

          return ListView.separated(
            itemCount: membros.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final member = membros[index] as Map<String, dynamic>;
              final nome = member['nome'] ?? '';
              final medium = member['medium'] ?? '';
              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  if (isAdmin) {
                    return true;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Solicite que um adm remova o item')),
                    );
                    return false;
                  }
                },
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('entidades')
                      .doc(entidade)
                      .update({
                    'membros': FieldValue.arrayRemove([member])
                  });
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  minTileHeight: 20,
                  title: Text(
                    nome,
                    style: GoogleFonts.lato(fontSize: 18),
                  ),
                  subtitle: Text(
                    medium,
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          final mainContext = context;
          TextEditingController entidadeController = TextEditingController();
          String? selectedUser;

          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Adicionar Entidade'),
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: entidadeController,
                          decoration: const InputDecoration(labelText: 'Entidade'),
                        ),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('Usuarios').get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Erro ao carregar usuários');
                            }
                            List<DropdownMenuItem<String>> items = [];
                            for (var doc in snapshot.data!.docs) {
                              String nomeUsuario = doc['nome'] ?? 'Sem Nome';
                              items.add(
                                DropdownMenuItem(
                                  value: nomeUsuario,
                                  child: Text(nomeUsuario),
                                ),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Médium'),
                              items: items,
                              value: selectedUser,
                              onChanged: (value) {
                                setState(() {
                                  selectedUser = value;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String newEntidade = entidadeController.text.trim();
                      if (newEntidade.isNotEmpty && selectedUser != null) {
                        String finalMedium = selectedUser!;
                        if (selectedUser == 'Branca Fernandes Verderame') {
                          finalMedium = 'Mãe';
                        } else if (selectedUser == 'Ricardo Brigagão Verderame') {
                          finalMedium = 'Pai';
                        }
                        await FirebaseFirestore.instance.collection('entidades').doc(entidade).set({
                          'membros': FieldValue.arrayUnion([
                            {'nome': newEntidade, 'medium': finalMedium}
                          ])
                        }, SetOptions(merge: true));
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(mainContext).showSnackBar(
                          const SnackBar(content: Text('Entidade adicionada com sucesso')),
                        );
                      }
                    },
                    child: const Text('Adicionar'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
