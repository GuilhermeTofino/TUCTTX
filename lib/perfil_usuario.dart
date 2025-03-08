import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  String nomeUsuario = "";
  String numeroEmergencia = "";
  String orixaDeFrente = "";
  String orixaJunto = "";
  String idade = "";
  String dataNascimento = "";
  String login = "";
  bool isLoading = true;

  // Controllers for text fields
  late TextEditingController numeroEmergenciaController;
  late TextEditingController orixaDeFrenteController;
  late TextEditingController orixaJuntoController;
  late TextEditingController idadeController;
  late TextEditingController dataNascimentoController;
  late TextEditingController loginController;

  // Input formatters
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
  Map<String, bool> readOnlyFields = {
    "Número de Emergência": true,
    "Idade": true,
    "Data de Nascimento": true,
    "Orixá de Frente": true,
    "Orixá Juntó": true,
    "Login": true,
  };
  @override
  void initState() {
    super.initState();
    numeroEmergenciaController = TextEditingController();
    orixaDeFrenteController = TextEditingController();
    orixaJuntoController = TextEditingController();
    idadeController = TextEditingController();
    dataNascimentoController = TextEditingController();
    loginController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args != null && args is String) {
        nomeUsuario = args;
        await fetchUserData(nomeUsuario);
      }
    });
  }

  Future<void> fetchUserData(String username) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(username)
          .get();

      if (snapshot.exists) {
        setState(() {
          numeroEmergencia = snapshot.get('numero_emergencia');
          orixaDeFrente = snapshot.get('orixa_de_frente');
          orixaJunto = snapshot.get('Orixa_junto');
          idade = snapshot.get('idade');
          dataNascimento = snapshot.get('data_nascimento');
          login = snapshot.get('login_key');

          numeroEmergenciaController.text = numeroEmergencia;
          orixaDeFrenteController.text = orixaDeFrente;
          orixaJuntoController.text = orixaJunto;
          idadeController.text = idade;
          dataNascimentoController.text = dataNascimento;
          loginController.text = login;

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Usuário não encontrado no Firestore');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Erro ao buscar dados do usuário: $e');
    }
  }

  Future<void> updateUserData() async {
    try {
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(nomeUsuario)
          .update({
        'numero_emergencia': numeroEmergenciaController.text,
        'orixa_de_frente': orixaDeFrenteController.text,
        'Orixa_junto': orixaJuntoController.text,
        'idade': idadeController.text,
        'data_nascimento': dataNascimentoController.text,
        'login_key': loginController.text,
      });

      // Atualiza os dados locais após a atualização bem-sucedida
      numeroEmergencia = numeroEmergenciaController.text;
      orixaDeFrente = orixaDeFrenteController.text;
      orixaJunto = orixaJuntoController.text;
      idade = idadeController.text;
      dataNascimento = dataNascimentoController.text;
      login = loginController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar dados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildEditableTextField(Icons.phone, "Número de Emergência",
                      numeroEmergenciaController, _numeroEmergenciaFormatter),
                  _buildEditableTextField(
                      Icons.calendar_today, "Idade", idadeController),
                  _buildEditableTextField(
                      Icons.calendar_month,
                      "Data de Nascimento",
                      dataNascimentoController,
                      _dataNascimentoFormatter),
                  _buildEditableTextField(
                      Icons.person, "Orixá de Frente", orixaDeFrenteController),
                  _buildEditableTextField(Icons.person_add_alt_1_sharp,
                      "Orixá Juntó", orixaJuntoController),
                  _buildEditableTextField(
                      Icons.login, "Login", loginController),
                  ElevatedButton(
                    onPressed: updateUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: const BorderSide(color: kPrimaryColor),
                      ),
                    ),
                    child: Text('Salvar Alterações',
                        style: GoogleFonts.lato(
                            fontSize: 13, color: kPrimaryColor)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar Exclusão'),
                          content: const Text(
                              'Tem certeza de que deseja excluir sua conta? Esta ação não pode ser desfeita.'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('Usuarios')
                              .doc(nomeUsuario)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Conta excluída com sucesso!')),
                          );

                          // Retornar para a tela de login ou inicial após a exclusão
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        } catch (e) {
                          print("Erro ao excluir conta: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Erro ao excluir conta.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: Text(
                      'Excluir Conta',
                      style:
                          GoogleFonts.lato(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        DocumentSnapshot snapshot = await FirebaseFirestore
                            .instance
                            .collection('Usuarios')
                            .doc(nomeUsuario)
                            .get();
                        if (snapshot.exists) {
                          List<dynamic> mensalidade =
                              snapshot.get('mensalidade') ?? [];

                          Navigator.pushNamed(context, '/mensalidade',
                              arguments: mensalidade);
                        }
                      } catch (e) {
                        print("Error fetching mensalidade: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Erro ao acessar dados de mensalidade.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: const BorderSide(color: kPrimaryColor),
                      ),
                    ),
                    child: Text('Financeiro',
                        style: GoogleFonts.lato(
                            fontSize: 13, color: kPrimaryColor)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableTextField(
      IconData icon, String label, TextEditingController controller,
      [MaskTextInputFormatter? formatter]) {
    return CustomTextField(
      icon: icon,
      label: label,
      controller: controller,
      readOnly: readOnlyFields[label]!,
      inputFormatters: formatter != null ? [formatter] : null,
      onTap: () async {
        final bool? shouldEdit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Editar Campo'),
            content: const Text('Deseja editar este campo?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Editar'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        );

        if (shouldEdit == true) {
          setState(() {
            readOnlyFields[label] = false;
          });
        }
      },
    );
  }
}
