import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Membro cujo cadastro ainda está incompleto: entrou como consulente (só nome e
/// telefone) e, depois de aprovado, ainda não informou o contato de emergência.
///
/// Consulente nunca é cobrado: para ele o cadastro básico já é o cadastro inteiro.
/// Membros antigos não são afetados: o cadastro deles sempre exigiu esse contato.
bool needsProfileCompletion(UserModel user) =>
    user.isMember && user.emergencyContact.trim().isEmpty;
