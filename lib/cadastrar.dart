import 'package:app_tenda/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Cadastrar extends StatefulWidget {
  const Cadastrar({super.key});

  @override
  State<Cadastrar> createState() => _CadastrarState();
}

class _CadastrarState extends State<Cadastrar> {
  // Chave global para o formulário
  final _formKey = GlobalKey<FormState>();

  // Variável para controlar o estado da checkbox "Tirou Santo"
  bool _tirouSanto = false;

  // Controllers para os campos de texto
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _idadeController = TextEditingController();
  final _numeroEmergenciaController = TextEditingController();
  final _frenteController = TextEditingController();
  final _juntoController = TextEditingController();

  // Formatador para o campo de data de nascimento
  final _dataNascimentoFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Formatador para o campo de numero de emergencia

  final _numeroEmergenciaFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Variável para exibir mensagens de erro
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulário ocupando o espaço disponível
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CustomTextField(
                          icon: Icons.person,
                          label: "Nome",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite seu nome completo';
                            }
                            return null;
                          },
                          controller: _nomeController),
                      CustomTextField(
                          icon: Icons.calendar_month,
                          label: "Data de Nascimento",
                          controller: _dataNascimentoController,
                          inputFormatters: [_dataNascimentoFormatter]),
                      CustomTextField(
                          icon: Icons.calendar_today,
                          label: "Idade",
                          controller: _idadeController),
                      CustomTextField(
                          icon: Icons.phone,
                          label: "Número de emêrgencia",
                          controller: _numeroEmergenciaController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite um número de emergência';
                            }
                            return null;
                          },
                          inputFormatters: [_numeroEmergenciaFormatter]),
                      // Checkbox "Tirou Santo"
                      CheckboxListTile(
                        title: const Text('Já sabe os orixás de cabeça?'),
                        value: _tirouSanto,
                        onChanged: (value) {
                          setState(() {
                            _tirouSanto = value!;
                          });
                        },
                      ),
                      // Campos condicionais para Mãe e Pai
                      if (_tirouSanto) ...[
                        CustomTextField(
                            icon: Icons.person,
                            label: "Orixá de Frente",
                            controller: _frenteController),
                        CustomTextField(
                            icon: Icons.person_add_alt_1_sharp,
                            label: "Orixá Juntó",
                            controller: _juntoController),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Exibição de mensagens de erro
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            // Botão de Enviar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              onPressed: _submitForm, // Chama a função para enviar o formulário
              child: const Text(
                'Enviar Meus Dados',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para enviar os dados do formulário
  Future<void> _submitForm() async {
    // Limpa mensagens de erro anteriores
    setState(() {
      _errorMessage = null;
    });

    // Valida o formulário
    if (_formKey.currentState!.validate()) {
      // Monta a string com os dados do formulário
      StringBuffer output = StringBuffer();
      output.writeln('Nome: ${_nomeController.text}');
      output.writeln(
          'Idade: ${_idadeController.text}     Data de Nascimento: ${_dataNascimentoController.text}');
      output.writeln('Tirou Santo: ${_tirouSanto ? 'Sim' : 'Não'}');

      if (_tirouSanto) {
        output.writeln('Mãe: ${_frenteController.text}');
        output.writeln('Pai: ${_juntoController.text}');
      }

      print(output.toString()); // Imprime os dados no console

      try {
        // Salva os dados no Firestore
        final db = FirebaseFirestore.instance;
        final usersCollection = db.collection('Filhos');
        final loginKey =
            '${_nomeController.text.split(' ')[0]}.${_nomeController.text.split(' ').last}'; // Cria a chave de login
        final userData = {
          'nome': _nomeController.text,
          'idade': _idadeController.text,
          'data_nascimento': _dataNascimentoController.text,
          'numero_emergencia': _numeroEmergenciaController.text,
          'tirou_santo': _tirouSanto ? 'Sim' : 'Não',
          'orixa_de_frente': _tirouSanto ? _frenteController.text : "Não Sabe",
          'Orixa_junto': _tirouSanto ? _juntoController.text : "Não Sabe",
          'login_key': loginKey,
          'mensalidade': List.filled(12, false),
        };

        await usersCollection.doc(_nomeController.text).set(userData);

        // Exibe mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );

        // Volta para a tela anterior
        Navigator.pop(context);
      } catch (e) {
        // Trata erros ao salvar no Firestore
        print('Erro ao salvar no Firestore: $e');
        setState(() {
          _errorMessage = 'Erro ao cadastrar usuário.';
        });
      }
    } else {
      // Exibe mensagem de erro se a validação falhar
      setState(() {
        _errorMessage = '* favor preencher todos os campos obrigatórios';
      });
    }
  }
}
