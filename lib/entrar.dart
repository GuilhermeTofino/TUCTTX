import 'package:app_tenda/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Variável global para indicar se o usuário é administrador
bool isAdmin = false;

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController(); // Nome mais descritivo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'images/logo_TUCTTX.png',
                fit: BoxFit.fitHeight,
                height: 380,
              ),
              CustomTextField(
                  icon: Icons.login,
                  label: "Nome de Usuário",
                  controller: _usuarioController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite seu nome de usuário';
                    }
                    return null;
                  }),
              const SizedBox(height: 24.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                onPressed: _tentarLogin, // Função separada para o login
                child:
                    const Text('Entrar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função para realizar o login
  Future<void> _tentarLogin() async {
    if (_formKey.currentState!.validate()) {
      final usuario = _usuarioController.text;
      try {
        // Busca por usuário na coleção "Filhos"
        final filhosSnapshot = await FirebaseFirestore.instance
            .collection('Filhos')
            .where('login_key', isEqualTo: usuario)
            .get();

        if (filhosSnapshot.docs.isNotEmpty) {
          isAdmin = false;
          String nomeUsuario =
              filhosSnapshot.docs[0].get('nome'); 
          _redirecionarParaTelaPrincipal(nomeUsuario); 
          return;
        }

        // Se não encontrar em "Filhos", busca na coleção "Adm"
        final admSnapshot = await FirebaseFirestore.instance
            .collection('Adm')
            .where('login_key', isEqualTo: usuario)
            .get();

        if (admSnapshot.docs.isNotEmpty) {
          isAdmin = true;
          String nomeUsuario = admSnapshot.docs[0].get('nome'); 
          _redirecionarParaTelaPrincipal(nomeUsuario); 
          return;
        }

        // Se não encontrar em nenhuma coleção, exibe alerta
        _mostrarAlertaUsuarioNaoEncontrado();
      } catch (e) {
        print('Erro durante o login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao fazer login.')),
        );
      }
    }
  }

  // Função para redirecionar para a tela principal
  void _redirecionarParaTelaPrincipal(String nomeUsuario) {
    Navigator.pushReplacementNamed(context, '/tela_principal',
        arguments: nomeUsuario);
  }

  // Função para exibir o alerta de usuário não encontrado
  void _mostrarAlertaUsuarioNaoEncontrado() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuário não encontrado'),
        content: const Text('Deseja criar uma nova conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cadastrar');
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    super.dispose();
  }
}
