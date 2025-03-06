import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  final String bucketName = 'pdfs'; // Nome do bucket

  /// 🔥 Faz upload de um PDF para o Supabase Storage
  Future<String?> uploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = file.uri.pathSegments.last;

      try {
        await supabase.storage.from(bucketName).upload(fileName, file);
        String publicUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
        return publicUrl; // Retorna a URL do arquivo salvo
      } catch (e) {
        print("Erro ao enviar PDF: $e");
        return null;
      }
    }
    return null;
  }

  /// 🔥 Lista todos os PDFs no Supabase Storage
  Future<List<String>> getPDFList() async {
    final response = await supabase.storage.from(bucketName).list();
    List<String> pdfUrls = response.map((file) => supabase.storage.from(bucketName).getPublicUrl(file.name)).toList();
    return pdfUrls;
  }
}