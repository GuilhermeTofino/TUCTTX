import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIEventParser {
  final String apiKey;
  late GenerativeModel _model;

  AIEventParser(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'title': Schema.string(description: 'Nome da gira ou evento'),
              'date': Schema.string(description: 'Data e hora no formato ISO8601'),
              // Removemos o enumValues/enumShapes para evitar erro de compilação
              'type': Schema.string(description: 'Tipo: Pública, Fechada, Festa ou Desenvolvimento'),
              'description': Schema.string(description: 'Resumo do que ocorrerá'),
            },
            requiredProperties: ['title', 'date', 'type', 'description'],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> parseWhatsAppText(String text) async {
    if (text.trim().isEmpty) return [];

    // Reforçamos os ENUMS aqui no Prompt, já que o Schema deu erro de parâmetro
    final prompt = '''
    Você é um assistente de terreiro de Umbanda experiente.
    Extraia os eventos do texto abaixo e retorne um JSON.
    
    REGRAS DE OURO:
    1. O campo "type" DEVE ser obrigatoriamente um destes: "Pública", "Fechada", "Festa" ou "Desenvolvimento".
    2. Use o ano de 2026 para as datas.
    3. Formate a data no padrão ISO8601 (Ex: 2026-05-20T20:00:00).

    Texto do WhatsApp: "$text"
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) throw Exception("Resposta vazia");
      
      final List<dynamic> parsedData = jsonDecode(response.text!);
      return parsedData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Erro no Parsing: $e");
      return [];
    }
  }
}