import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Variáveis globais para permissões
bool isAdmin = false;
bool isBazar = false;

class Entrar extends StatefulWidget {
  const Entrar({super.key});

  @override
  State<Entrar> createState() => _EntrarState();
}

class _EntrarState extends State<Entrar> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  String? _ultimoUsuario;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _carregarUltimoUsuario();
  }

  // Carrega o último usuário salvo no SharedPreferences
  Future<void> _carregarUltimoUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ultimoUsuario = prefs.getString('ultimo_usuario');
    });
  }

  // Salva o último usuário logado
  Future<void> _salvarUltimoUsuario(String usuario) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_usuario', usuario);
  }

  // Verifica se o dispositivo suporta biometria
  Future<void> _checkBiometricAvailability() async {
    try {
      bool canAuthenticate =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = canAuthenticate;
      });
    } on PlatformException catch (e) {
      print("Erro ao verificar biometria: $e");
    }
  }

  // Autenticação via biometria (Face ID ou digital)
  Future<void> _authenticateBiometrically() async {
    if (_ultimoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Nenhum usuário salvo para login biométrico, faça login manulmente')),
      );
      return;
    }

    try {
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Use sua biometria para fazer login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        _validarUsuarioBiometria();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticação falhou')),
        );
      }
    } on PlatformException catch (e) {
      print("Erro na autenticação: $e");
    }
  }

  Future<void> _salvarTokenFCM(String usuarioId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(usuarioId)
            .update({'fcm_token': token});

        print("Token FCM salvo com sucesso: $token");
      }
    } catch (e) {
      print("Erro ao salvar o token FCM: $e");
    }
  }

  // Valida o usuário salvo no banco de dados ao usar biometria
  Future<void> _validarUsuarioBiometria() async {
    if (_ultimoUsuario == null) return;

    final resultado = await _buscarUsuario(_ultimoUsuario!);
    if (resultado != null) {
      _definirPermissoesUsuario(resultado);
      await _salvarTokenFCM(resultado['id']); // Atualiza o token FCM
      _redirecionarParaTelaPrincipal(resultado['nome'] ?? "");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não encontrado')),
      );
    }
  }

  // Realiza o login manualmente
  Future<void> _tentarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = _usuarioController.text.trim();
    try {
      final resultado = await _buscarUsuario(usuario);

      if (resultado != null) {
        _definirPermissoesUsuario(resultado);
        await _salvarUltimoUsuario(usuario);
        await _salvarTokenFCM(resultado['id']); // Atualiza o token FCM
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

  // Busca usuário no Firestore
  Future<Map<String, dynamic>?> _buscarUsuario(String login) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .where('login_key', isEqualTo: login)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final userData = doc.data();
      return {
        'id': doc.id, // Adicionamos o ID do usuário
        'nome': userData['nome'],
        'funcao': userData['funcao'],
      };
    }
    return null;
  }

  void _definirPermissoesUsuario(Map<String, dynamic> resultado) {
    String funcao = resultado['funcao'] ?? 'regular';
    isAdmin = funcao == 'administrador';
    isBazar = funcao == 'bazar';
  }

  // Redireciona para a tela principal
  void _redirecionarParaTelaPrincipal(String nomeUsuario) {
    Navigator.pushReplacementNamed(context, '/tela_principal',
        arguments: nomeUsuario);
  }

  // Alerta caso o usuário não seja encontrado
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
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
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                onPressed: _tentarLogin,
                child:
                    const Text('Entrar', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/cadastrar'),
                child: const Text('Cadastrar',
                    style: TextStyle(color: kPrimaryColor)),
              ),
              const SizedBox(height: 20),
              Visibility(
                visible: _ultimoUsuario != null && _isBiometricAvailable,
                child: ElevatedButton.icon(
                  onPressed: _authenticateBiometrically,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Entrar com Biometria / Face ID"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
