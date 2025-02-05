import 'package:app_tenda/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Variável global para indicar se o usuário é administrador
bool isAdmin = false;
bool isBazar = false;

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
  if (!_formKey.currentState!.validate()) return;

  final usuario = _usuarioController.text.trim();
  try {
    final resultado = await _buscarUsuario(usuario);

    if (resultado != null) {
      isAdmin = resultado['tipo'] == 'Adm';
      isBazar = resultado['tipo'] == 'Bazar';
      _redirecionarParaTelaPrincipal(resultado['nome'] ?? "");
    } else {
      _mostrarAlertaUsuarioNaoEncontrado();
    }
  } catch (e) {
    print('Erro durante o login: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao fazer login.')),
    );
  }
}
Future<Map<String, String>?> _buscarUsuario(String login) async {
  final List<String> colecoes = ['Filhos', 'Adm', 'Bazar'];

  for (String colecao in colecoes) {
    final snapshot = await FirebaseFirestore.instance
        .collection(colecao)
        .where('login_key', isEqualTo: login)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return {
        'nome': snapshot.docs.first.get('nome'),
        'tipo': colecao, // Define o tipo de usuário
      };
    }
  }
  return null; // Retorna nulo se não encontrar o usuário em nenhuma coleção
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
