import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/formatar_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usuario_model.dart';
import '../blocs/usuario_bloc.dart';
import '../widgets/custom_text_field.dart';

class Cadastrar extends StatefulWidget {
  const Cadastrar({super.key});

  @override
  State<Cadastrar> createState() => _CadastrarState();
}

class _CadastrarState extends State<Cadastrar> {
  final UsuarioBloc _bloc = UsuarioBloc();
  final _formKey = GlobalKey<FormState>();

  bool _temAlergias = false;
  bool _tirouSanto = false;

  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _idadeController = TextEditingController();
  final _numeroEmergenciaController = TextEditingController();
  final _frenteController = TextEditingController();
  final _juntoController = TextEditingController();

  List<TextEditingController> _alergiaControllers = [];
  List<String> _alergias = [];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataNascimentoController.addListener(_calcularIdade);
  }

  @override
  void dispose() {
    _dataNascimentoController.removeListener(_calcularIdade);
    _dataNascimentoController.dispose();
    for (var controller in _alergiaControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calcularIdade() {
    if (_dataNascimentoController.text.isNotEmpty) {
      try {
        DateTime dataNascimento =
            DateFormat("dd/MM/yyyy").parse(_dataNascimentoController.text);
        DateTime hoje = DateTime.now();
        int idade = hoje.year - dataNascimento.year;
        if (hoje.month < dataNascimento.month ||
            (hoje.month == dataNascimento.month &&
                hoje.day < dataNascimento.day)) {
          idade--;
        }
        setState(() {
          _idadeController.text = idade.toString();
        });
      } catch (e) {
        // Ignorar erro de parsing de data
      }
    }
  }

  void _adicionarAlergia() {
    setState(() {
      _alergiaControllers.add(TextEditingController());
    });
  }

  void _removerAlergia(int index) {
    if (index >= 0 && index < _alergiaControllers.length) {
      setState(() {
        _alergiaControllers[index].dispose(); // Libera memória do controlador
        _alergiaControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                    controller: _nomeController,
                    label: "Nome Completo",
                    icon: Icons.people),
                CustomTextField(
                  controller: _dataNascimentoController,
                  label: "Data de Nascimento",
                  icon: Icons.calendar_month,
                  inputFormatters: [DataInputFormatter()],
                  hintText: "DD/MM/AAAA",
                ),
                CustomTextField(
                  controller: _idadeController,
                  label: "Idade",
                  readOnly: true,
                  icon: Icons.cake,
                ),
                CustomTextField(
                  controller: _numeroEmergenciaController,
                  label: "Número de Emergência",
                  icon: Icons.phone,
                ),

                // Checkbox para orixás
                CheckboxListTile(
                  title: const Text('Já sabe os orixás de cabeça?'),
                  value: _tirouSanto,
                  onChanged: (value) => setState(() => _tirouSanto = value!),
                ),

                if (_tirouSanto) ...[
                  CustomTextField(
                    controller: _frenteController,
                    label: "Orixá de Frente",
                    icon: Icons.person,
                  ),
                  CustomTextField(
                    controller: _juntoController,
                    label: "Orixá Juntó",
                    icon: Icons.person,
                  ),
                ],

                // Checkbox para alergias
                CheckboxListTile(
                  title: const Text('Tem alergias?'),
                  value: _temAlergias,
                  onChanged: (value) {
                    setState(() {
                      _temAlergias = value!;
                      if (!_temAlergias) {
                        _alergiaControllers.clear();
                        _alergias.clear();
                      } else {
                        _adicionarAlergia(); // Garante que tenha pelo menos um campo ao ativar
                      }
                    });
                  },
                ),

                if (_temAlergias) ...[
                  for (int i = 0; i < _alergiaControllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _alergiaControllers[i],
                            label: "Alergia ${i + 1}",
                            icon: Icons.medical_information,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removerAlergia(i),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _adicionarAlergia,
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(10, 10)),
                    ),
                  ),
                ],

                OutlinedButton(
                  onPressed: _submitForm,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryColor), // Borda fina
                    foregroundColor: kPrimaryColor, // Cor do texto
                    backgroundColor: Colors.white, // Fundo branco
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Cadastrar Usuário",
                      style: TextStyle(fontSize: 16)),
                ),

                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _alergias = _alergiaControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      String nomeCompleto = _nomeController.text.trim();
      List<String> nomes = nomeCompleto.split(' ');

      String loginUsuario = nomes.length > 1
          ? "${nomes.first.toLowerCase()}.${nomes.last.toLowerCase()}"
          : nomes.first.toLowerCase();

      // Se o usuário não preencher a data de nascimento, deixa vazia
      String dataNascimento = _dataNascimentoController.text.trim();
      int? idade = dataNascimento.isNotEmpty
          ? int.tryParse(_idadeController.text.trim())
          : null;

      // Se o número de emergência não for informado, deixa vazio
      String numeroEmergencia = _numeroEmergenciaController.text.trim();

      List<dynamic> mensalidade = List.generate(12, (index) => false);

      Usuario novoUsuario = Usuario(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: nomeCompleto,
        dataNascimento: dataNascimento.isNotEmpty ? dataNascimento : "",
        idade: idade ?? 0,
        numeroEmergencia: numeroEmergencia.isNotEmpty ? numeroEmergencia : "",
        tirouSanto: _tirouSanto,
        orixaFrente: _tirouSanto ? _frenteController.text.trim() : "Não Sabe",
        orixaJunto: _tirouSanto ? _juntoController.text.trim() : "Não Sabe",
        alergias: _temAlergias ? _alergias : [],
        loginUsuario: loginUsuario,
        funcao: "regular",
        mensalidade: mensalidade,
        leitura: false,
      );

      String? erro = await _bloc.cadastrarUsuario(novoUsuario);
      if (erro != null) {
        setState(() => _errorMessage = erro);
      } else {
        _mostrarDialogBoasVindas(loginUsuario);
      }
    }
  }

  void _mostrarDialogBoasVindas(String loginUsuario) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Column(
            children: [
              Image.asset(
                "images/logo_TUCTTX.png",
                height: 100, // Ajuste conforme necessário
              ),
              const SizedBox(height: 10),
              const Text("Bem-vindo Tender!", textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            "Seu login para acessar o aplicativo é:\n\n$loginUsuario",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o dialog
                Navigator.pop(context); // Fecha a tela de cadastro
              },
              child: const Text("OK", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}
