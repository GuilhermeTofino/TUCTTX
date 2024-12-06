import 'package:app_tenda/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Cadastrar extends StatefulWidget {
  const Cadastrar({super.key});

  @override
  State<Cadastrar> createState() => _CadastrarState();
}

class _CadastrarState extends State<Cadastrar> {
  final _formKey = GlobalKey<FormState>();

  bool _temAlergias = false;
  List<TextEditingController> _alergiaControllers = [];
  List<String> _alergias = [];

  bool _tirouSanto = false;

  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _idadeController = TextEditingController();
  final _numeroEmergenciaController = TextEditingController();
  final _frenteController = TextEditingController();
  final _juntoController = TextEditingController();

  final _dataNascimentoFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _numeroEmergenciaFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                        controller: _nomeController,
                      ),
                      CustomTextField(
                        icon: Icons.calendar_month,
                        label: "Data de Nascimento",
                        controller: _dataNascimentoController,
                        inputFormatters: [_dataNascimentoFormatter],
                        onChanged: (value) {
                          if (value.length == 10) {
                            try {
                              final formattedDate =
                                  DateFormat('dd/MM/yyyy').parse(value);
                              final age = calculateAge(formattedDate);
                              _idadeController.text = age.toString();
                            } catch (e) {
                              print("Invalid date format: $e");
                              _idadeController.text = "";
                            }
                          } else {
                            _idadeController.text = "";
                          }
                        },
                      ),
                      CustomTextField(
                        icon: Icons.calendar_today,
                        label: "Idade",
                        controller: _idadeController,
                        readOnly: true, // Make the age field read-only
                      ),
                      CustomTextField(
                        icon: Icons.phone,
                        label: "Número de Emergência com DDD",
                        controller: _numeroEmergenciaController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite um número de emergência';
                          }
                          return null;
                        },
                        inputFormatters: [_numeroEmergenciaFormatter],
                      ),
                      CheckboxListTile(
                        title: const Text('Já sabe os orixás de cabeça?'),
                        value: _tirouSanto,
                        onChanged: (value) {
                          setState(() {
                            _tirouSanto = value!;
                          });
                        },
                      ),
                      if (_tirouSanto) ...[
                        CustomTextField(
                          icon: Icons.person,
                          label: "Orixá de Frente",
                          controller: _frenteController,
                        ),
                        CustomTextField(
                          icon: Icons.person_add_alt_1_sharp,
                          label: "Orixá Juntó",
                          controller: _juntoController,
                        ),
                      ],
                      CheckboxListTile(
                        title: const Text('Possui alergias?'),
                        value: _temAlergias,
                        onChanged: (value) {
                          setState(() {
                            _temAlergias = value!;
                            if (!value) {
                              _alergiaControllers.clear();
                              _alergias.clear();
                            } else {
                              _addAlergiaField();
                            }
                          });
                        },
                      ),
                      if (_temAlergias)
                        ..._alergiaControllers.map((controller) {
                          int index = _alergiaControllers.indexOf(controller);
                          return Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  icon: Icons.medical_information,
                                  controller: controller,
                                  label: 'Alergia ${index + 1}',
                                  onChanged: (value) {
                                    if (_alergias.length > index) {
                                      _alergias[index] = value;
                                    } else {
                                      _alergias.add(value);
                                    }
                                  },
                                ),
                              ),
                              if (index == _alergiaControllers.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: kPrimaryColor),
                                  onPressed: _addAlergiaField,
                                ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              onPressed: _submitForm,
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

  int calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _addAlergiaField() {
    setState(() {
      _alergiaControllers.add(TextEditingController());
      if (_alergias.length < _alergiaControllers.length) {
        _alergias.add("");
      }
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        final db = FirebaseFirestore.instance;
        final usersCollection = db.collection('Filhos');
        final loginKey =
            '${_nomeController.text.split(' ')[0]}.${_nomeController.text.split(' ').last}';
        final userData = {
          'nome': _nomeController.text,
          'idade': _idadeController.text,
          'data_nascimento': _dataNascimentoController.text,
          'numero_emergencia': _numeroEmergenciaController.text,
          'tirou_santo': _tirouSanto ? "Sim" : "Não",
          'orixa_de_frente': _tirouSanto ? _frenteController.text : "Não Sabe",
          'Orixa_junto': _tirouSanto ? _juntoController.text : "Não Sabe",
          'login_key': loginKey,
          'mensalidade': List.filled(12, false),
          'alergias': _alergias,
        };

        await usersCollection.doc(_nomeController.text).set(userData);
        if (_formKey.currentState!.validate()) {
          const snackBar =
              SnackBar(content: Text('Usuário cadastrado com sucesso!'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pop(context);
        }
      } catch (e) {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorMessage = '* favor preencher todos os campos obrigatórios';
      });
    }
  }
}
