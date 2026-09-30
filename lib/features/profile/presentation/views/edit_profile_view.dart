import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/di/service_locator.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/features/profile/domain/models/health_data_model.dart';
import 'package:app_tenda/features/profile/domain/profile_validation.dart';
import 'package:app_tenda/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';

/// "Editar Meu Cadastro": qualquer perfil (visitante, filho de santo ou admin)
/// edita os próprios dados pessoais. Papel, status e permissões não aparecem
/// aqui: só o admin muda, e as regras do Firestore travam de qualquer forma.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final EditProfileViewModel _viewModel = getIt<EditProfileViewModel>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _endereco = TextEditingController();
  final _orixaFrente = TextEditingController();
  final _orixaJunto = TextEditingController();
  final _tipoSanguineo = TextEditingController();
  final _alergias = TextEditingController();
  final _medicamentos = TextEditingController();
  final _condicoes = TextEditingController();
  DateTime? _dataNascimento;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _endereco, _orixaFrente, _orixaJunto,
      _tipoSanguineo, _alergias, _medicamentos, _condicoes,
    ]) {
      c.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }

  /// Preenche os campos UMA vez, quando o cadastro já carregou. Nunca antes:
  /// salvar o formulário vazio apagaria os dados do usuário.
  void _populate() {
    final user = _viewModel.user;
    if (_populated || user == null) return;
    _populated = true;
    _name.text = user.name;
    _phone.text = user.phone;
    _endereco.text = user.endereco ?? '';
    _orixaFrente.text = user.orixaFrente ?? '';
    _orixaJunto.text = user.orixaJunto ?? '';
    _dataNascimento = user.dataNascimento;
    final health = _viewModel.health;
    _tipoSanguineo.text = health.tipoSanguineo ?? '';
    _alergias.text = health.alergias ?? '';
    _medicamentos.text = health.medicamentos ?? '';
    _condicoes.text = health.condicoesMedicas ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dataNascimento = picked);
  }

  Future<void> _pickPhoto() async {
    final error = await _viewModel.pickAndUploadPhoto();
    if (error != null && mounted) _snack(error);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final error = await _viewModel.save(
      ProfileInput(
        name: _name.text,
        phone: _phone.text,
        dataNascimento: _dataNascimento,
        endereco: _endereco.text,
        orixaFrente: _orixaFrente.text,
        orixaJunto: _orixaJunto.text,
        health: HealthData(
          tipoSanguineo: _tipoSanguineo.text,
          alergias: _alergias.text,
          medicamentos: _medicamentos.text,
          condicoesMedicas: _condicoes.text,
        ),
      ),
    );
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }
    _snack('Cadastro atualizado com sucesso!');
    Navigator.pop(context);
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Editar Meu Cadastro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: tenant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_viewModel.loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _viewModel.load, child: const Text('Tentar de novo')),
                  ],
                ),
              ),
            );
          }
          _populate();
          return _buildForm(tenant);
        },
      ),
    );
  }

  Widget _buildForm(tenant) {
    final user = _viewModel.user!;
    final saving = _viewModel.isSaving;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: _buildPhoto(tenant)),
          const SizedBox(height: 24),

          _section('Dados pessoais'),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Nome'),
            validator: ProfileValidation.name,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _dec('Telefone'),
            validator: ProfileValidation.phone,
          ),
          const SizedBox(height: 12),
          // E-mail é o login (Firebase Auth): trocar só aqui deixaria os dois fora de
          // sincronia. Fica visível, mas somente leitura.
          TextFormField(
            initialValue: user.email,
            enabled: false,
            decoration: _dec('E-mail', helper: 'O e-mail é o seu login e não pode ser alterado aqui.'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: _dec('Data de nascimento'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dataNascimento == null
                          ? 'Toque para escolher'
                          : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
                    ),
                  ),
                  if (_dataNascimento != null)
                    GestureDetector(
                      onTap: () => setState(() => _dataNascimento = null),
                      child: const Icon(Icons.clear, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _endereco,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Endereço'),
          ),

          _section('Fundamento'),
          TextFormField(controller: _orixaFrente, decoration: _dec('Santo de cabeça (Orixá de frente)')),
          const SizedBox(height: 12),
          TextFormField(controller: _orixaJunto, decoration: _dec('Orixá junto')),
          // Entidades são coisa de membro: o visitante não vê este atalho.
          if (!user.isVisitor) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.groups_3_outlined),
              title: const Text('Minhas Entidades'),
              subtitle: const Text('Gerencie suas entidades em uma tela própria.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.myEntities),
            ),
          ],

          _section('Saúde'),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estes dados ficam protegidos: só você e a administração da casa conseguem ver.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(controller: _tipoSanguineo, decoration: _dec('Tipo sanguíneo')),
          const SizedBox(height: 12),
          TextFormField(controller: _alergias, maxLines: 2, decoration: _dec('Alergias')),
          const SizedBox(height: 12),
          TextFormField(controller: _medicamentos, maxLines: 2, decoration: _dec('Medicamentos')),
          const SizedBox(height: 12),
          TextFormField(controller: _condicoes, maxLines: 2, decoration: _dec('Condições médicas')),

          const SizedBox(height: 28),
          FilledButton(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: tenant.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Salvar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPhoto(tenant) {
    final local = _viewModel.localPhotoPath;
    final remote = _viewModel.user?.photoUrl;
    final ImageProvider? image = local != null
        ? FileImage(File(local))
        : (remote != null ? NetworkImage(remote) : null);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFFE9ECEF),
          backgroundImage: image,
          child: image == null ? const Icon(Icons.person, size: 52, color: Colors.grey) : null,
        ),
        if (_viewModel.isUploadingPhoto)
          const Positioned.fill(child: Center(child: CircularProgressIndicator()))
        else
          Material(
            color: tenant.primaryColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _pickPhoto,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    ),
  );

  InputDecoration _dec(String label, {String? helper}) => InputDecoration(
    labelText: label,
    helperText: helper,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
