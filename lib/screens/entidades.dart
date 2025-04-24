import 'package:app_tenda/screens/entidades_detail.dart';
import 'package:app_tenda/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Entidades extends StatefulWidget {
  const Entidades({super.key});

  @override
  State<Entidades> createState() => _EntidadesState();
}

class _EntidadesState extends State<Entidades> {
  final List<String> entidades = [
    'Caboclos',
    'Pretos Velhos',
    'Exus',
    'Exus Mirins',
    'Pombas Giras',
    'Boiadeiros',
    'Malandros',
    'Baianos',
    'Marinheiros',
    'Erês',
  ];

  List<String> filteredEntidades = [];

  @override
  void initState() {
    super.initState();
    filteredEntidades = List.from(entidades);
    filteredEntidades.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _filterEntidades(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredEntidades = List.from(entidades);
        filteredEntidades.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    } else {
      setState(() {
        filteredEntidades = entidades
            .where((entidade) => entidade.toLowerCase().contains(query.toLowerCase()))
            .toList();
        filteredEntidades.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        toolbarHeight: 100,
        title: Column(
          children: [
            Text('Entidades de Trabalho da Casa', style: GoogleFonts.lato(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: _filterEntidades,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: GoogleFonts.lato(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 5.0,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredEntidades.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EntidadeDetailScreen(
                          entidade: filteredEntidades[index],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: Text(
                        filteredEntidades[index],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
