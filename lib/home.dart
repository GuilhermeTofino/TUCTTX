import 'package:app_tenda/screens/calendario.dart';
import 'package:app_tenda/financeiro.dart';
import 'package:app_tenda/grid_pdfs.dart';
import 'package:app_tenda/screens/entidades.dart';
import 'package:app_tenda/vizualizador_pdf.dart';
import 'package:app_tenda/widgets/colors.dart';
import 'package:app_tenda/demonstrativo.dart';
import 'package:app_tenda/splash.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/entrar.dart';
import 'package:google_fonts/google_fonts.dart';

import 'filhos.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Índice da tela selecionada

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    String? nomeUsuario = ModalRoute.of(context)!.settings.arguments as String?;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context),
        appBar: _buildAppBar(nomeUsuario),
        body: _buildBody(),
      ),
    );
  }

  // Constrói o AppBar
  AppBar _buildAppBar(String? nomeUsuario) {
    return AppBar(
      toolbarHeight: 45,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isAdmin || isBazar
                ? 'Olá - $nomeUsuario (ADM)'
                : 'Olá - $nomeUsuario',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/perfilUsuario',
                  arguments: nomeUsuario);
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
              voltar: false,
            ),
            VisualizarPdf(
              appBarTitle: 'Rumbê',
              pdfAssetPath: 'images/pdfs/RUMBE TUCTTX.pdf',
              voltar: false,
              naoMostrar: false,
            ),
            ListaPdf(appBarTitle: 'FAQ'),
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
            ListaPdf(appBarTitle: 'Ervas'),
            ListaPdf(appBarTitle: 'Biblioteca'),
            Filhos(),
            Financeiro(),
            // BazarScreen(),
            DemonstrativosScreen(),
            Entidades(),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: kPrimaryColor,
            padding: const EdgeInsets.all(8.0),
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

  // Constrói o Drawer com categorias expansíveis
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.70, // Responsivo
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            child: Image.asset('images/logo_TUCTTX.png', fit: BoxFit.contain),
          ),
          _buildDrawerItem('Calendário', 0, Icons.calendar_today),

          // Categoria Apostilas
          _buildExpansionTile(
            title: "ESTUDOS",
            icon: Icons.book,
            children: [
              _buildDrawerItem('APOSTILA', 1, Icons.book),
              _buildDrawerItem('RUMBÊ', 2, Icons.rule),
              _buildDrawerItem(
                  'FAQ-PERGUNTAS FREQUENTES', 3, Icons.question_answer),
              _buildDrawerItem("Pontos Cantados", 4, Icons.graphic_eq),
              _buildDrawerItem("Pontos Riscados", 5, Icons.edit),
              _buildDrawerItem("Ervas", 6, Icons.compost),
              _buildDrawerItem("Biblioteca", 7, Icons.menu_book),
            ],
          ),

          // Categoria Administração (Apenas para Admins)
          if (isAdmin)
            _buildExpansionTile(
              title: "ADMINISTRAÇÃO",
              icon: Icons.admin_panel_settings,
              children: [
                _buildDrawerItem("Filhos", 8, Icons.people_alt_outlined),
                // _buildDrawerItem("Bazar", 10, Icons.shopping_bag),
                _buildDrawerItem("Financeiro", 9, Icons.attach_money),
                _buildDrawerItem("Demonstrativos", 10, Icons.picture_as_pdf),
              ],
            ),

          // Caso seja usuário do bazar, adiciona Financeiro e Bazar separadamente
          // if (isBazar) _buildDrawerItem("Bazar", 10, Icons.money_rounded),
          _buildDrawerItem("Entidades da Casa", 11, Icons.people),
          _buildDrawerItem("Sair", 12, Icons.exit_to_app),
        ],
      ),
    );
  }

  // Constrói um ExpansionTile para categorias do Drawer
  Widget _buildExpansionTile(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return ExpansionTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(title,
          style: GoogleFonts.lato(
              fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor)),
      trailing: const Icon(
        Icons.arrow_drop_down,
        color: kPrimaryColor,
      ),
      children: children,
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
      selectedTileColor: Colors.grey[200],
      trailing: _selectedIndex == index
          ? const Icon(Icons.arrow_forward_ios, color: kPrimaryColor)
          : null,
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
