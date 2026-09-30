import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_tenda/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';
import 'package:app_tenda/core/di/service_locator.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _enderecoController;
  late TextEditingController _orixaFrenteController;
  late TextEditingController _orixaJuntoController;
  late TextEditingController _tipoSanguineoController;
  late TextEditingController _alergiasController;
  late TextEditingController _medicamentosController;
  late TextEditingController _condicoesMedicasController;
  late EditProfileViewModel _viewModel;
  DateTime? _selectedDataNascimento;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<EditProfileViewModel>();
    _nameController = TextEditingController(text: _viewModel.currentUser?.name);
    _phoneController =
        TextEditingController(text: _viewModel.currentUser?.phone);
    _enderecoController =
        TextEditingController(text: _viewModel.currentUser?.endereco);
    _orixaFrenteController =
        TextEditingController(text: _viewModel.currentUser?.orixaFrente);
    _orixaJuntoController =
        TextEditingController(text: _viewModel.currentUser?.orixaJunto);
    _tipoSanguineoController =
        TextEditingController(text: _viewModel.currentUser?.tipoSanguineo);
    _alergiasController =
        TextEditingController(text: _viewModel.currentUser?.alergias);
    _medicamentosController =
        TextEditingController(text: _viewModel.currentUser?.medicamentos);
    _condicoesMedicasController =
        TextEditingController(text: _viewModel.currentUser?.condicoesMedicas);
    _selectedDataNascimento = _viewModel.currentUser?.dataNascimento;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _enderecoController.dispose();
    _orixaFrenteController.dispose();
    _orixaJuntoController.dispose();
    _tipoSanguineoController.dispose();
    _alergiasController.dispose();
    _medicamentosController.dispose();
    _condicoesMedicasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Meu Cadastro'),
        ),
        body: Consumer<EditProfileViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto de Perfil
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: viewModel.pickProfilePhoto,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                viewModel.currentUser?.photoUrl != null
                                    ? NetworkImage(viewModel.currentUser!.photoUrl!)
                                    : null,
                            child: viewModel.currentUser?.photoUrl == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              onPressed: viewModel.pickProfilePhoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nome
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Telefone
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // E-mail (somente leitura)
                  TextFormField(
                    initialValue: viewModel.currentUser?.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data de Nascimento
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDataNascimento ?? DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDataNascimento = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de Nascimento',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDataNascimento != null
                            ? '${_selectedDataNascimento!.day}/${_selectedDataNascimento!.month}/${_selectedDataNascimento!.year}'
                            : 'Selecione uma data',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Endereço
                  TextField(
                    controller: _enderecoController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Santo de Cabeça (Orixá Frente)
                  TextField(
                    controller: _orixaFrenteController,
                    decoration: const InputDecoration(
                      labelText: 'Santo de Cabeça (Orixá Frente)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Orixá Junto
                  TextField(
                    controller: _orixaJuntoController,
                    decoration: const InputDecoration(
                      labelText: 'Orixá Junto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tipo Sanguíneo
                  TextField(
                    controller: _tipoSanguineoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Sanguíneo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alergias
                  TextField(
                    controller: _alergiasController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alergias',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medicamentos
                  TextField(
                    controller: _medicamentosController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Medicamentos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Condições Médicas
                  TextField(
                    controller: _condicoesMedicasController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Condições Médicas',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await viewModel.updateProfile(
                            name: _nameController.text,
                            phone: _phoneController.text,
                            endereco: _enderecoController.text.isEmpty
                                ? null
                                : _enderecoController.text,
                            orixaFrente: _orixaFrenteController.text.isEmpty
                                ? null
                                : _orixaFrenteController.text,
                            orixaJunto: _orixaJuntoController.text.isEmpty
                                ? null
                                : _orixaJuntoController.text,
                            tipoSanguineo: _tipoSanguineoController.text.isEmpty
                                ? null
                                : _tipoSanguineoController.text,
                            alergias: _alergiasController.text.isEmpty
                                ? null
                                : _alergiasController.text,
                            medicamentos: _medicamentosController.text.isEmpty
                                ? null
                                : _medicamentosController.text,
                            condicoesMedicas:
                                _condicoesMedicasController.text.isEmpty
                                    ? null
                                    : _condicoesMedicasController.text,
                            dataNascimento: _selectedDataNascimento,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso!'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
