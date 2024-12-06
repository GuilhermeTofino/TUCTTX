import 'package:app_tenda/Tela%20Inicial/calendario.dart';
import 'package:app_tenda/Tela%20Inicial/grid_pdfs.dart';
import 'package:app_tenda/Tela%20Inicial/vizualizador_pdf.dart';
import 'package:app_tenda/colors.dart';
import 'package:app_tenda/listas%20Pdfs/list_pdfs.dart';
import 'package:app_tenda/perfil_usuario.dart';
import 'package:app_tenda/splash.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/entrar.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Tela Inicial/filhos.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

int _selectedIndex = 0; // Índice da tela selecionada

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    _selectedIndex = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Recupera o nome do usuário passado como argumento
    String? nomeUsuario = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context), // Constrói o Drawer
      appBar: _buildAppBar(nomeUsuario), // Constrói o AppBar
      body: _buildBody(), // Constrói o corpo da tela
    );
  }

  // Constrói o AppBar
  AppBar _buildAppBar(String? nomeUsuario) {
    return AppBar(
      toolbarHeight: 65,
      automaticallyImplyLeading: false,
      backgroundColor: kPrimaryColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            isAdmin ? 'Olá - $nomeUsuario (ADM)' : 'Olá - $nomeUsuario',
            style: GoogleFonts.lato(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (isAdmin) const SizedBox(width: 100),
          if (!isAdmin) const SizedBox(width: 10),
          if (!isAdmin)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/perfilUsuario',
                  arguments: nomeUsuario,
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  nomeUsuario != null
                      ? nomeUsuario.substring(0, 1).toUpperCase()
                      : "",
                  style: const TextStyle(color: kPrimaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Constrói o corpo da tela
  Widget _buildBody() {
    return Stack(
      children: [
        IndexedStack(
          index: _selectedIndex,
          children: const [
            Calendario(),
            VisualizarPdf(
                appBarTitle: 'Apostila',
                pdfAssetPath:
                    'images/pdfs/TENDA DE UMBANDA DO CABOCLO TREME TERRA 2023.pdf',
                naoMostrar: false,
                voltar: false),
            VisualizarPdf(
              appBarTitle: 'Rumbê',
              pdfAssetPath: 'images/pdfs/RUMBE TUCTTX.pdf',
              voltar: false,
              naoMostrar: false,
            ),
            ListaPdf(
              appBarTitle: 'FAQ',
            ),
            VisualizarPdf(
              appBarTitle: 'Pontos Cantados',
              pdfAssetPath: 'images/pdfs/TUCTTX - Pontos Cantados.pdf',
              voltar: false,
              naoMostrar: false,
            ),
            VisualizarPdf(
              appBarTitle: 'Pontos Riscados',
              pdfAssetPath: 'images/pdfs/APOSTILA - PONTOS RISCADOS.pdf',
              voltar: false,
              naoMostrar: false,
            ),
            ListaPdf(
              appBarTitle: 'Ervas',
            ),
            ListaPdf(
              appBarTitle: 'Biblioteca',
            ),
            Filhos(),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: kPrimaryColor,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'TUCTTX',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // Constrói o Drawer
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.70, // Responsivo
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            // Usando DrawerHeader para o cabeçalho
            decoration: const BoxDecoration(
              color: kPrimaryColor,
            ),
            child: Image.asset(
              'images/logo_TUCTTX.png',
              fit: BoxFit.contain,
            ),
          ),
          // Itens do menu
          _buildDrawerItem(
              'Calendário', 0, Icons.calendar_today), // Exemplo de ícone
          _buildDrawerItem('APOSTILA', 1, Icons.book), // Ícone de livro
          _buildDrawerItem('RUMBÊ', 2, Icons.rule), // Ícone de música
          _buildDrawerItem('FAQ-PERGUNTAS FREQUENTES', 3,
              Icons.question_answer), // Ícone de chat
          _buildDrawerItem("Pontos Cantados", 4, Icons.graphic_eq),
          _buildDrawerItem("Pontos Riscados", 5, Icons.edit),
          _buildDrawerItem("Ervas", 6, Icons.compost),
          _buildDrawerItem("Biblioteca", 7, Icons.menu_book),
          if (isAdmin) _buildDrawerItem("Filhos", 8, Icons.people_alt_outlined),
          _buildDrawerItem("Sair", 9, Icons.exit_to_app)
          // ... outros itens
        ],
      ),
    );
  }

  // Constrói um item do Drawer
  Widget _buildDrawerItem(String title, int index, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(title,
          style: GoogleFonts.lato(
              fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.bold)),
      selected: _selectedIndex == index,
      onTap: () {
        if (title == "Sair") {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Splash()),
              (Route<dynamic> route) => false);
        } else {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        }
      },
    );
  }
}
