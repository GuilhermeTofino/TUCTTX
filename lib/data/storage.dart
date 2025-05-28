import 'dart:io';
import 'package:app_tenda/widgets/fcm.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload de arquivo
  Future<String> uploadFile(File file, String? folder) async {
    try {
      String fileName = path.basename(file.path);
      String filePath = folder != null ? '$folder/$fileName' : fileName;
      Reference ref = _storage.ref().child(filePath);

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // await sendFCMToAll(
      //     'Arquivo enviado', 'O arquivo $fileName foi enviado para $filePath.');

      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao enviar arquivo: $e');
    }
  }

  // Download de arquivo para um File local (não aplicável no Flutter Web)
  Future<File> downloadFile(String filePath, String localPath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      File file = File(localPath);
      await ref.writeToFile(file);

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await sendFCMMessage('Arquivo baixado',
            'O arquivo $filePath foi baixado para este dispositivo.', fcmToken);
      }

      return file;
    } catch (e) {
      throw Exception('Erro ao baixar arquivo: $e');
    }
  }

  // Deletar arquivo
  Future<void> deleteFile(String filePath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      await ref.delete();
      print("deletado com sucesso");
      await sendFCMToAll('Arquivo deletado', 'O arquivo $filePath foi deletado do aplicativo.');
    } catch (e) {
      throw Exception('Erro ao deletar arquivo: $e');
    }
  }

  // Obter URL pública do arquivo
  Future<String> getDownloadURL(String filePath) async {
    try {
      Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao obter URL do arquivo: $e');
    }
  }

  // Listar arquivos dentro de uma pasta
  Future<List<Reference>> listFilesInFolder(String folderName) async {
    try {
      final result = await _storage.ref(folderName).listAll();
      return result.items;
    } catch (e) {
      throw Exception('Erro ao listar arquivos da pasta $folderName: $e');
    }
  }
}

Future<void> sendFCMToAll(String title, String body) async {
  try {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .where('fcm_token', isGreaterThan: '')
        .get();

    for (var doc in usersSnapshot.docs) {
      final token = doc['fcm_token'];
      await sendFCMMessage(title, body, token);
    }
  } catch (e) {
    print('Erro ao enviar notificação FCM para todos: $e');
  }
}
