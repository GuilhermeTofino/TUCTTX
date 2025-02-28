import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Filhos extends StatefulWidget {
  const Filhos({super.key});

  @override
  State<Filhos> createState() => _FilhosState();
}

class _FilhosState extends State<Filhos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Filhos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Usuarios')
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo deu errado'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sem filhos cadastrados.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              return Dismissible(
                key: Key(document.id), // Use document ID as the key
                direction: DismissDirection.endToStart, // Swipe left-to-right
                onDismissed: (direction) async {
                  try {
                    // Delete the document from Firestore
                    await FirebaseFirestore.instance
                        .collection('Usuarios')
                        .doc(document.id)
                        .delete();
                        
                    // Show a snackbar confirming the deletion (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Filho ${document.get('nome')} excluído.')),
                    );


                  } catch (e) {
                    // Handle any errors that occur during deletion
                    print('Error deleting document: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao excluir filho.')),
                    );
                  }

                 
                },
                background: Container( // Background color when swiping
                  alignment: AlignmentDirectional.centerEnd,
                  color: Colors.red,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                ),
                child: ListTile(
                  title: Text(document.get('nome')),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/detalhesFilho',
                        arguments: document.data());
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
