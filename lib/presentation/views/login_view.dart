import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/routes/app_routes.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/custom_logo_loader.dart';
import '../../core/services/biometric_service.dart'; // Importe seu novo serviço

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _viewModel = getIt<RegisterViewModel>();
  final _biometricService = BiometricService(); // Instância do serviço

  bool _obscurePassword = true;
  bool _canUseBiometrics = false; // Controle de visibilidade do botão

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  // Verifica se o hardware permite e se existem credenciais salvas
  Future<void> _checkBiometricAvailability() async {
    final tenant = AppConfig.instance.tenant.tenantSlug;
    final isHardwareAvailable = await _biometricService.canUseBiometrics();
    final credentials = await _biometricService.getSavedCredentials(tenant);

    setState(() {
      // Só mostra o botão se o hardware for compatível E houver e-mail salvo
      _canUseBiometrics = isHardwareAvailable && credentials['email'] != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenant = AppConfig.instance.tenant;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(tenant),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Bem-vindo de volta!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Acesse sua conta para ver seus fundamentos.",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      _buildInput(
                        "E-mail",
                        _emailController,
                        Icons.mail_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        "Senha",
                        _passwordController,
                        Icons.lock_outline,
                        isPassword: true,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _showResetPasswordSheet(context, tenant),
                          child: Text(
                            "Esqueceu a senha?",
                            style: TextStyle(color: tenant.primaryColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // AREA DE BOTÕES (Normal + Biometria)
                      Row(
                        children: [
                          Expanded(child: _buildLoginButton(tenant)),
                          if (_canUseBiometrics) ...[
                            const SizedBox(width: 12),
                            _buildBiometricButton(tenant),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Ainda não é membro?"),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                            ),
                            child: Text(
                              "Cadastre-se",
                              style: TextStyle(
                                color: tenant.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_viewModel.isLoading) _buildLoadingOverlay(tenant),
        ],
      ),
    );
  }

  // --- COMPONENTE: BOTÃO DE BIOMETRIA ---
  Widget _buildBiometricButton(tenant) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: tenant.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(
          Theme.of(context).platform == TargetPlatform.iOS
              ? Icons.face
              : Icons.fingerprint,
          color: tenant.primaryColor,
          size: 28,
        ),
        onPressed: _handleBiometricLogin,
      ),
    );
  }

  // --- LÓGICA: LOGIN BIOMÉTRICO ---
  void _handleBiometricLogin() async {
    final tenantSlug = AppConfig.instance.tenant.tenantSlug;

    // 1. Abre o diálogo do FaceID/Digital
    final authenticated = await _biometricService.authenticate();

    if (authenticated) {
      // 2. Busca as credenciais no cofre
      final credentials = await _biometricService.getSavedCredentials(
        tenantSlug,
      );
      final email = credentials['email'];
      final password = credentials['password'];

      if (email != null && password != null) {
        // 3. Preenche os campos (opcional, para feedback visual)
        _emailController.text = email;
        _passwordController.text = password;

        // 4. Dispara o login
        _performLogin(email, password);
      }
    }
  }

  // --- LÓGICA: LOGIN MANUAL (ATUALIZADA) ---
  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }
    _performLogin(email, password);
  }

  // Centraliza a chamada para a ViewModel
  void _performLogin(String email, String password) async {
    final tenantSlug = AppConfig.instance.tenant.tenantSlug;
    final success = await _viewModel.signIn(email, password);

    if (success && mounted) {
      // LOGIN DEU CERTO: Salva/Atualiza as credenciais no cofre para a próxima vez
      await _biometricService.saveCredentials(email, password, tenantSlug);

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.errorMessage ??
                "Erro ao entrar. Verifique suas credenciais.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- NOVO MÉTODO: RECUPERAÇÃO DE SENHA PREMIUM ---
  void _showResetPasswordSheet(BuildContext context, tenant) {
    // Pré-preenche com o que já foi digitado na tela de login
    final emailResetController = TextEditingController(
      text: _emailController.text,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Necessário para ver o arredondamento
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 32,
          right: 32,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "Recuperar Acesso",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Digite seu e-mail abaixo. Enviaremos um link para você definir uma nova senha.",
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 32),
            _buildInput(
              "Seu e-mail de cadastro",
              emailResetController,
              Icons.alternate_email,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tenant.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final email = emailResetController.text.trim();
                  if (email.isEmpty) return;

                  // 1. CAPTURA o messenger antes de fechar o pop-up
                  final messenger = ScaffoldMessenger.of(context);

                  // 2. Fecha o BottomSheet
                  Navigator.pop(context);

                  // 3. Chama a lógica da ViewModel
                  final success = await _viewModel.resetPassword(email);

                  // 4. USA o messenger capturado (sem depender do context deativado)
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "E-mail enviado! Confira sua caixa de entrada."
                            : "Erro: Verifique se o e-mail está correto.",
                      ),
                      backgroundColor: success
                          ? Colors.green[700]
                          : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: const Text(
                  "ENVIAR INSTRUÇÕES",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(tenant) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tenant.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(80)),
      ),
      child: Center(
        child: Hero(
          tag: 'logo',
          child: Image.asset(tenant.logoPath, height: 300),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        floatingLabelStyle: TextStyle(
          color: AppConfig.instance.tenant.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginButton(tenant) {
    return ElevatedButton(
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: tenant.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text(
        "ENTRAR",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(tenant) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CustomLogoLoader(size: 80, logoSize: 40),
          ),
        ),
      ),
    );
  }
}
