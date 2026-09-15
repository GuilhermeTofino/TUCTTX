import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:app_tenda/core/config/app_config.dart';
import 'package:app_tenda/core/services/base_firestore_datasource.dart';

/// Resumo de uma casa, usado em telas que listam instituições (ex: seleção
/// de casa no cadastro), sem precisar carregar a config completa.
class TenantSummary {
  final String slug;
  final String name;

  const TenantSummary({required this.slug, required this.name});
}

/// Dados que o dirigente/responsável informa ao cadastrar a casa dele
/// durante o próprio cadastro no app (em vez de entrar numa casa já
/// existente).
class NewTenantInput {
  final String tenantName;
  final String responsavel;
  final Color? primaryColor;
  final String? pixKey;
  final String? paymentLink;

  const NewTenantInput({
    required this.tenantName,
    required this.responsavel,
    this.primaryColor,
    this.pixKey,
    this.paymentLink,
  });
}

/// Carrega a configuração de uma casa (nome, cor, logo) a partir do
/// Firestore. Substitui a antiga `TenantFactory`, que fixava essas casas em
/// código: agora cadastrar uma casa nova é só criar o doc
/// `environments/{env}/tenants/{slug}`, sem precisar de novo build do app.
class TenantRepository extends BaseFirestoreDataSource {
  /// Busca a config completa de uma casa pelo slug. Lançado logo após o
  /// login descobrir a qual casa o usuário pertence.
  Future<TenantConfig> fetchTenant(String slug) async {
    final doc = await environmentRoot.collection('tenants').doc(slug).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      throw Exception('Casa "$slug" não encontrada.');
    }

    return TenantConfig.fromMap(slug, data);
  }

  /// Lista as casas cadastradas. NÃO deve ser usada pra o membro comum
  /// escolher a própria casa no cadastro (ver [resolveSlugByInviteCode]) —
  /// serve só pra telas administrativas/internas.
  Future<List<TenantSummary>> listTenants() async {
    final snapshot = await environmentRoot.collection('tenants').get();
    return snapshot.docs
        .map(
          (doc) => TenantSummary(
            slug: doc.id,
            name: (doc.data())['tenantName'] as String? ?? doc.id,
          ),
        )
        .toList();
  }

  /// Resolve o slug de uma casa a partir do código de convite dela. É assim
  /// que um filho/irmão de fé entra na casa certa no cadastro: o dirigente
  /// passa esse código pra ele (WhatsApp, cartão, etc), em vez do app expor
  /// uma lista pública de casas — evita entrar (por engano ou não) numa casa
  /// que não é a dele.
  Future<String> resolveSlugByInviteCode(String inviteCode) async {
    final normalized = inviteCode.trim().toUpperCase();
    final snapshot = await environmentRoot
        .collection('tenants')
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Código de convite inválido.');
    }

    return snapshot.docs.first.id;
  }

  /// Gera um novo código de convite pra casa (ex: se o antigo vazou). Ação
  /// do dirigente, numa tela administrativa.
  Future<String> regenerateInviteCode(String slug) async {
    final tenants = environmentRoot.collection('tenants');
    final newCode = await _generateUniqueInviteCode(tenants);
    await tenants.doc(slug).update({'inviteCode': newCode});
    return newCode;
  }

  /// Cadastra uma casa nova a partir dos dados informados pelo dirigente no
  /// próprio cadastro dele. Gera o slug a partir do nome da casa (garantindo
  /// que não colida com nenhuma já existente) e um código de convite único,
  /// usado depois pelos filhos de fé pra entrar nessa casa. Retorna o slug.
  ///
  /// [responsavelUid] é o uid (Firebase Auth) de quem está cadastrando —
  /// guardado no doc da casa pra sabermos quem é o dirigente/admin dela.
  Future<String> createTenant(
    NewTenantInput input, {
    required String responsavelUid,
  }) async {
    final baseSlug = _slugify(input.tenantName);
    final tenants = environmentRoot.collection('tenants');
    final inviteCode = await _generateUniqueInviteCode(tenants);

    return firestore.runTransaction<String>((transaction) async {
      var slug = baseSlug;
      var attempt = 1;
      var ref = tenants.doc(slug);
      var snapshot = await transaction.get(ref);

      // Evita colidir com uma casa já cadastrada com nome parecido.
      while (snapshot.exists) {
        attempt++;
        slug = '$baseSlug$attempt';
        ref = tenants.doc(slug);
        snapshot = await transaction.get(ref);
      }

      transaction.set(ref, {
        'tenantName': input.tenantName,
        'responsavel': input.responsavel,
        'responsavelUid': responsavelUid,
        'inviteCode': inviteCode,
        if (input.primaryColor != null)
          'primaryColor': _colorToHex(input.primaryColor!),
        if (input.pixKey != null) 'pixKey': input.pixKey,
        if (input.paymentLink != null) 'paymentLink': input.paymentLink,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return slug;
    });
  }

  /// Sobe a logo da casa para o Storage e atualiza o doc do tenant.
  /// Chamado depois de [createTenant], quando já existe um slug.
  Future<String> uploadTenantLogo(File image, String slug) async {
    final env = AppConfig.instance.environment == AppEnvironment.dev
        ? 'dev'
        : 'prod';

    final storage = FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: "tenda-white-label.firebasestorage.app",
    );

    final storageRef = storage
        .ref()
        .child('environments')
        .child(env)
        .child('tenants')
        .child(slug)
        .child('logo.jpg');

    final uploadTask = await storageRef.putData(
      await image.readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final logoUrl = await uploadTask.ref.getDownloadURL();

    await environmentRoot.collection('tenants').doc(slug).update({
      'logoUrl': logoUrl,
    });

    return logoUrl;
  }

  /// Gera um código de convite não usado por nenhuma outra casa. Em 5
  /// tentativas malsucedidas (extremamente improvável, com esse espaço de
  /// caracteres) desiste e propaga o erro.
  static Future<String> _generateUniqueInviteCode(
    CollectionReference tenants,
  ) async {
    for (var i = 0; i < 5; i++) {
      final code = _randomInviteCode();
      final existing = await tenants
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    throw Exception(
      'Não foi possível gerar um código de convite único. Tente novamente.',
    );
  }

  // Sem caracteres ambíguos (0/O, 1/I/L) pra facilitar digitar/ler em voz alta.
  static const _inviteCodeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String _randomInviteCode({int length = 6}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _inviteCodeChars[random.nextInt(_inviteCodeChars.length)],
    ).join();
  }

  static String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

  /// Slug simples: minúsculo, sem acento, só letras e números.
  static String _slugify(String input) {
    const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucn';

    final normalized = input.toLowerCase().trim().split('').map((char) {
      final index = withAccents.indexOf(char);
      return index >= 0 ? withoutAccents[index] : char;
    }).join();

    final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return slug.isEmpty ? 'casa' : slug;
  }
}
