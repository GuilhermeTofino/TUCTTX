import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/di/service_locator.dart';
import '../viewmodels/home_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Injetamos a ViewModel no widget tree usando o GetIt para localizá-la
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => getIt<HomeViewModel>(),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          final tenant = AppConfig.instance.tenant;

          return Scaffold(
            appBar: AppBar(
              title: Text(tenant.appTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => viewModel.fetchUserData('user_123'),
                )
              ],
            ),
            body: Center(
              child: viewModel.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Bem-vindo ao ${tenant.tenantName}"),
                        const SizedBox(height: 20),
                        if (viewModel.user != null)
                          Text("Usuário: ${viewModel.user!.name}")
                        else
                          const Text("Nenhum dado carregado do Firestore."),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => viewModel.fetchUserData('user_123'),
                          child: const Text("Simular Busca no Firebase"),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
