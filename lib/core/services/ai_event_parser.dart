import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIEventParser {
  final String apiKey;
  late GenerativeModel _model;
  late GenerativeModel _camboneModel; // Modelo específico para cambones

  AIEventParser(this.apiKey) {
    // Modelo padrão para Eventos
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'title': Schema.string(description: 'Nome da gira ou evento'),
              'date': Schema.string(
                description: 'Data e hora no formato ISO8601',
              ),
              'type': Schema.string(
                description: 'Tipo: Pública, Fechada, Festa ou Desenvolvimento',
              ),
              'description': Schema.string(
                description: 'Resumo do que ocorrerá',
              ),
              'cleaningCrew': Schema.array(
                items: Schema.string(),
                description:
                    'Lista de nomes das pessoas responsáveis pela faxina neste dia',
              ),
            },
            requiredProperties: ['title', 'date', 'type', 'description'],
          ),
        ),
      ),
    );

    // Modelo específico para Escalas de Cambones
    _camboneModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'camboneName': Schema.string(description: 'Nome do Cambone'),
              'mediums': Schema.array(
                items: Schema.string(),
                description: 'Lista de nomes dos médiuns associados',
              ),
            },
            requiredProperties: ['camboneName', 'mediums'],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> parseWhatsAppText(String text) async {
    if (text.trim().isEmpty) return [];

    // Reforçamos os ENUMS aqui no Prompt, já que o Schema deu erro de parâmetro
    final prompt =
        '''
    Você é um assistente de terreiro de Umbanda experiente.
    Extraia os eventos do texto abaixo e retorne um JSON.
    
    REGRAS DE OURO:
    1. O campo "type" DEVE ser obrigatoriamente um destes: "Pública", "Fechada", "Festa" ou "Desenvolvimento".
    2. Use o ano de 2026 para as datas.
    3. Formate a data no padrão ISO8601 (Ex: 2026-05-20T20:00:00).
    4. Se houver menção de "Equipe de Faxina" ou nomes listados para limpeza, preencha o campo "cleaningCrew".

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

  Future<List<Map<String, dynamic>>> parseImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    final prompt = '''
    Analise esta imagem de escala/calendário de terreiro.
    Identifique os eventos (Giras, Reuniões) e as Equipes de Faxina.
    
    REGRAS:
    1. "type" deve ser: "Pública", "Fechada", "Festa" ou "Desenvolvimento". Se não estiver claro, use "Pública".
    2. Data no formato ISO8601. Assuma o ano atual (2026) se não especificado.
    3. Para dias de "Faxina" ou que tenham nomes de pessoas listados em colunas específicas (geralmente abaixo de uma data ou nome de gira), crie um evento. 
       - Se for apenas faxina, o título pode ser "Faxina".
       - Se for uma Gira com nomes associados, coloque os nomes no campo "cleaningCrew".
    4. Retorne apenas JSON válido.
    ''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);

      if (response.text == null) throw Exception("Resposta vazia da IA");

      // Sanitização básica caso a IA retorne markdown
      String jsonText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '');

      final List<dynamic> parsedData = jsonDecode(jsonText);
      return parsedData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Erro no Parsing de Imagem: $e");
      return [];
    }
  }

  // Novo método para parsear texto de escala de cambones
  Future<List<Map<String, dynamic>>> parseCamboneScheduleText(
    String text,
  ) async {
    if (text.trim().isEmpty) return [];

    final prompt =
        '''
    Você é um assistente de terreiro.
    Analise o texto abaixo que contém uma escala de cambones e seus médiuns.
    Retorne um JSON com a lista de atribuições.

    REGRAS CRITICAS DE INTERPRETAÇÃO:
    1. O formato geralmente é: "Nomes dos Médiuns - Nome do Cambone". 
       Exemplo: "PAI RICARDO - TAMARA" significa que TAMARA é o Cambone e PAI RICARDO é o Médium.
    2. Pode haver vários médiuns separados por barra (/) ou vírgula.
       Exemplo: "BRANCA/MA - NATALIA" -> Cambone: NATALIA, Médiuns: ["BRANCA", "MA"].

    ESTRUTURA DO JSON (Lista de Objetos):
    [
      {
        "camboneName": "Nome do Cambone (sempre quem cuida)",
        "mediums": ["Médium 1", "Médium 2"]
      }
    ]

    OUTRAS REGRAS:
    - Se houver uma data no texto, ignore por enquanto, foque na associação Cambone-Médiuns.
    - Retorne APENAS o JSON válido, sem markdown.

    Texto para Análise: "$text"
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _camboneModel.generateContent(content);

      if (response.text == null) throw Exception("Resposta vazia");

      print(
        "AI RAW RESPONSE: ${response.text}",
      ); // Debug solicitado pelo usuário

      var jsonText = response.text!.trim();

      // Remove blocos de código se houver
      if (jsonText.startsWith('```')) {
        jsonText = jsonText
            .replaceAll(RegExp(r'^```[a-z]*\n'), '')
            .replaceAll(RegExp(r'\n```$'), '');
      }

      // Tenta encontrar o início e fim do JSON array
      final startIndex = jsonText.indexOf('[');
      final endIndex = jsonText.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1) {
        jsonText = jsonText.substring(startIndex, endIndex + 1);
      }

      final List<dynamic> parsedData = jsonDecode(jsonText);
      return parsedData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Erro no Parsing de Escala de Cambones (Texto): $e");
      return [];
    }
  }

  // Novo método para parsear imagem de escala de cambones
  Future<List<Map<String, dynamic>>> parseCamboneScheduleImage(
    File imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();

    final prompt = '''
    Analise esta imagem de escala de cambones.
    Identifique os pares de Cambone e seus respectivos Médiuns.

    REGRAS:
    1. O JSON deve ser uma lista de objetos:
       [
         {
           "camboneName": "Nome do Cambone",
           "mediums": ["Nome Médium 1", "Nome Médium 2"]
         }
       ]
    2. Geralmente a imagem tem uma coluna para Cambones e outra para Médiuns, ou agrupa os médiuns sob o nome do cambone.
    3. Retorne APENAS o JSON válido, sem markdown.
    ''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // USANDO O MODELO ESPECÍFICO PARA CAMBONES
      final response = await _camboneModel.generateContent(content);

      if (response.text == null) throw Exception("Resposta vazia da IA");

      var jsonText = response.text!.trim();

      // Remove blocos de código se houver
      if (jsonText.startsWith('```')) {
        jsonText = jsonText
            .replaceAll(RegExp(r'^```[a-z]*\n'), '')
            .replaceAll(RegExp(r'\n```$'), '');
      }

      // Tenta encontrar o início e fim do JSON array
      final startIndex = jsonText.indexOf('[');
      final endIndex = jsonText.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1) {
        jsonText = jsonText.substring(startIndex, endIndex + 1);
      }

      final List<dynamic> parsedData = jsonDecode(jsonText);
      return parsedData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Erro no Parsing de Escala de Cambones (Imagem): $e");
      return [];
    }
  }
}
