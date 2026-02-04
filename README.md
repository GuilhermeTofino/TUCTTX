# TUCTTX - App Tenda v2.0

O **App Tenda (TUCTTX)** é uma solução mobile completa para gestão e engajamento de membros de terreiros de Umbanda/Candomblé. Desenvolvido em **Flutter**, o aplicativo oferece uma experiência moderna, fluida e segura para consulentes e membros da administração.

Esta é a **versão 2.0** do projeto, reescrita com arquitetura **MVVM** e princípios de **Clean Architecture** para maior escalabilidade e manutenibilidade.

## 🚀 Funcionalidades Principais

### 👤 Membros
- **Autenticação Segura**: Login por e-mail/senha e suporte a **Biometria (FaceID/TouchID)**.
- **Carteirinha Digital**: Cartão de identidade virtual com informações do membro (Orixás de frente/juntó, tipo sanguíneo) e efeitos visuais premium (Glassmorphism).
- **Mural de Avisos**: Visualização de comunicados importantes da casa com destaque para urgentes.
- **Calendário de Giras**: Cronograma interativo com confirmação de presença (Vou/Não vou).
- **Central de Estudos**: Acesso a materiais doutrinários, PDFs (Apostilas, Rumbê) e dúvidas frequentes.
- **Perfil**: Gestão de foto de perfil e dados pessoais.

### 🛡️ Administração
- **Gestão de Membros**: Visualização e edição de dados dos filhos da casa.
- **Controle de Amaci**: Definição de datas de obrigações (último e próximo amaci).
- **Gestão de Avisos**: Criação, edição e exclusão de comunicados com notificações push.
- **Gestão de Estudos**: Upload de PDFs e organização de materiais didáticos.
- **Gestão Financeira**: Painel (Hub) financeiro integrado.
- **Gestão de Menus**: Configuração dinâmica dos atalhos da tela inicial.

## 🛠️ Tecnologias Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.4)
- **Linguagem**: Dart
- **Backend (BaaS)**: Firebase
  - **Auth**: Autenticação de usuários.
  - **Firestore**: Banco de dados NoSQL em tempo real.
  - **Storage**: Armazenamento de arquivos (fotos, PDFs).
  - **Messaging**: Notificações Push via FCM.
- **Gerenciamento de Estado**: `Provider` + `ChangeNotifier`.
- **Injeção de Dependência**: `get_it`.
- **Arquitetura**: MVVM (Model-View-ViewModel) + Clean Architecture.
- **Outros**:
  - `local_auth`: Biometria.
  - `google_generative_ai`: Integrações com IA (Gemini).
  - `file_picker` & `url_launcher`: Manipulação de arquivos.

## 📂 Arquitetura do Projeto

O projeto segue uma estrutura modular baseada em *features* dentro da camada de apresentação, facilitando a navegação e manutenção.

```
lib/
├── core/                # Configurações globais, DI, rotas e serviços base
├── data/                # Implementações de repositórios e datasources
├── domain/              # Modelos de negócio e interfaces de repositórios
├── infrastructure/      # Integrações com serviços externos
├── presentation/        # Camada de UI (MVVM)
│   ├── viewmodels/      # Lógica de estado (agrupado por feature: auth, new_home, admin...)
│   ├── views/           # Telas e layouts (agrupado por feature)
│   │   ├── auth/        # Login, Registro, Boas-vindas
│   │   ├── home/        # Tela Principal
│   │   ├── calendar/    # Calendário
│   │   ├── admin/       # Telas Administrativas
│   │   └── ...
│   └── widgets/         # Componentes reutilizáveis
└── main.dart            # Ponto de entrada
```

## 🏁 Como Rodar o Projeto

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado.
- Um editor de código (VS Code ou Android Studio).
- Conta no Firebase configurada (com arquivos `google-services.json` para Android e `GoogleService-Info.plist` para iOS).

### Passo a Passo

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/GuilhermeTofino/TUCTTX
   cd TUCTTX
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase:**
   - Certifique-se de que os arquivos de configuração do Firebase estão nas pastas corretas:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Execute o aplicativo:**
   - Selecione um dispositivo (Emulador ou Físico) e rode:
   ```bash
   flutter run
   ```

### 📱 Notas Específicas
- **iOS**: Necessário Mac com Xcode para build. Lembre-se de configurar as permissões de FaceID no `Info.plist`.
- **Android**: Verifique se o `minSdkVersion` no `build.gradle` é compatível (recomendado 21+).

## 📦 Versão
Atual: **2.0.0+3**

---
Desenvolvido com 🤍 por Guilherme Tofino.
