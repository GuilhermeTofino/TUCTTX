import 'package:app_tenda/presentation/widgets/custom_logo_loader.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final PageController _pageController = PageController();
  final RegisterViewModel _viewModel = getIt<RegisterViewModel>();
  int _currentStep = 0;

  // Controllers Quadrante 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estados Quadrante 2
  bool? _jaTirouSanto;
  bool? _jogoComTata;
  final _frenteController = TextEditingController();
  final _juntoController = TextEditingController();

  // Controllers Quadrante 3
  final _alergiasController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _condicoesController = TextEditingController();
  String? _selectedTipoSanguineo;

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50], // Fundo leve para destacar o card
          body: Stack(
            children: [
              // Header Background
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tenant.primaryColor,
                      tenant.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(tenant),
                    _buildCustomStepper(tenant),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) =>
                              setState(() => _currentStep = i),
                          children: [
                            _buildStep1(tenant),
                            _buildStep2(tenant),
                            _buildStep3(tenant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_viewModel.isLoading) _buildLoadingOverlay(tenant),
            ],
          ),
        );
      },
    );
  }

  // --- COMPONENTES PREMIUM ---

  Widget _buildTopBar(tenant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => _currentStep > 0
                ? _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  )
                : Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _getStepTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // Equilíbrio visual
        ],
      ),
    );
  }

  Widget _buildCustomStepper(tenant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isActive ? tenant.primaryColor : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep
                          ? Colors.white
                          : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- QUADRANTES REESTILIZADOS ---

  Widget _buildStep1(tenant) {
    return _buildPageContent(
      title: "Vamos começar!",
      subtitle: "Preencha seus dados básicos para criar sua conta no terreiro.",
      children: [
        _buildPremiumInput(
          "Nome Completo",
          _nameController,
          Icons.person_outline,
        ),
        _buildPremiumInput(
          "E-mail",
          _emailController,
          Icons.mail_outline,
          type: TextInputType.emailAddress,
        ),
        _buildPremiumInput(
          "Telefone",
          _phoneController,
          Icons.phone_android_outlined,
          type: TextInputType.phone,
        ),
        _buildPremiumInput(
          "Contato Emergência",
          _emergencyController,
          Icons.contact_emergency_outlined,
        ),
        _buildPremiumInput(
          "Senha",
          _passwordController,
          Icons.lock_open_outlined,
          isObscure: true,
        ),
        const SizedBox(height: 20),
        _buildActionButton("PRÓXIMO PASSO", () => _nextPage()),
      ],
    );
  }

  Widget _buildStep2(tenant) {
    bool canGoNext =
        _jaTirouSanto == false ||
        (_jaTirouSanto == true && _jogoComTata == true);
    return _buildPageContent(
      title: "Fundamentos",
      subtitle: "Informações sobre sua caminhada espiritual dentro da casa.",
      children: [
        _buildPremiumQuestion(
          "Você já tirou o seu santo?",
          _jaTirouSanto,
          (val) => setState(() {
            _jaTirouSanto = val;
            if (!val) _jogoComTata = null;
          }),
          tenant,
        ),
        if (_jaTirouSanto == true) ...[
          const SizedBox(height: 16),
          _buildPremiumQuestion(
            "O jogo foi com o Tata Kangambadiama?",
            _jogoComTata,
            (val) => setState(() => _jogoComTata = val),
            tenant,
          ),
        ],
        const SizedBox(height: 16),
        _buildPremiumInput(
          "Orixá de Frente",
          _frenteController,
          Icons.shield_outlined,
          enabled: _jogoComTata == true,
        ),
        _buildPremiumInput(
          "Orixá Juntó",
          _juntoController,
          Icons.shield_outlined,
          enabled: _jogoComTata == true,
        ),
        if (_jaTirouSanto == true && _jogoComTata == false)
          _buildPremiumWarning(
            "Fale com o Pai Ricardo para marcar um jogo de búzios.",
          ),
        const SizedBox(height: 20),
        _buildActionButton("CONTINUAR", canGoNext ? _nextPage : null),
      ],
    );
  }

  Widget _buildStep3(tenant) {
    return _buildPageContent(
      title: "Saúde e Zelo",
      subtitle:
          "Esses dados são sigilosos e servem para sua segurança durante os trabalhos.",
      children: [
        _buildPremiumDropdown(
          "Tipo Sanguíneo",
          _selectedTipoSanguineo,
          (val) => setState(() => _selectedTipoSanguineo = val),
        ),
        _buildPremiumInput(
          "Alergias (Ervas, alimentos...)",
          _alergiasController,
          Icons.warning_amber_rounded,
          maxLines: 2,
        ),
        _buildPremiumInput(
          "Medicamentos e Horários",
          _medicamentosController,
          Icons.medical_services_outlined,
          maxLines: 2,
        ),
        _buildPremiumInput(
          "Condições Médicas",
          _condicoesController,
          Icons.favorite_border_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _buildActionButton("FINALIZAR CADASTRO", _handleFinalize, isLast: true),
      ],
    );
  }

  // --- AUXILIARES DE ESTILO PREMIUM ---

  Widget _buildPageContent({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPremiumInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    bool isObscure = false,
    int maxLines = 1,
    TextInputType? type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          floatingLabelStyle: TextStyle(
            color: AppConfig.instance.tenant.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumQuestion(
    String title,
    bool? value,
    Function(bool) onChanged,
    tenant,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildChoiceChip(
              "Sim",
              value == true,
              () => onChanged(true),
              tenant,
            ),
            const SizedBox(width: 12),
            _buildChoiceChip(
              "Não",
              value == false,
              () => onChanged(false),
              tenant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool selected,
    VoidCallback onSelected,
    tenant,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? tenant.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback? onPressed, {
    bool isLast = false,
  }) {
    final tenant = AppConfig.instance.tenant;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLast ? Colors.green[700] : tenant.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDropdown(
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.bloodtype_outlined),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          "A+",
          "A-",
          "B+",
          "B-",
          "AB+",
          "AB-",
          "O+",
          "O-",
        ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPremiumWarning(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: Colors.brown[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(tenant) {
    return Container(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.2), // Fundo escurecido suave
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CustomLogoLoader(size: 90, logoSize: 45),
            ),
          ),
        ),
      ),
    );
  }

  // --- LÓGICA ---

  String _getStepTitle() {
    if (_currentStep == 0) return "Cadastro Inicial";
    if (_currentStep == 1) return "Sua Fé";
    return "Sua Saúde";
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleFinalize() async {
    final success = await _viewModel.registerUser(
      data: {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'emergencyContact': _emergencyController.text,
        'password': _passwordController.text,
        'jaTirouSanto': _jaTirouSanto ?? false,
        'jogoComTata': _jogoComTata ?? false,
        'orixaFrente': _frenteController.text,
        'orixaJunto': _juntoController.text,
        'alergias': _alergiasController.text,
        'medicamentos': _medicamentosController.text,
        'condicoesMedicas': _condicoesController.text,
        'tipoSanguineo': _selectedTipoSanguineo,
      },
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }
}
