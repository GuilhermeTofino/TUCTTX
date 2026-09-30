import 'package:app_tenda/features/auth/domain/models/user_model.dart';

/// Abas da lista de membros.
///  - [visitors]: quem ainda é consulente;
///  - [members]: filhos de santo E administradores (admin também é membro);
///  - [admins]: só os administradores (por isso um admin aparece em duas abas).
enum MemberTab { visitors, members, admins }

extension MemberTabRules on MemberTab {
  bool includes(UserModel user) {
    switch (this) {
      case MemberTab.visitors:
        return user.isVisitor;
      case MemberTab.members:
        return user.isMember;
      case MemberTab.admins:
        return user.isAdmin;
    }
  }
}

/// Usuários de uma aba, já filtrados pela [query] (nome ou e-mail, sem
/// diferenciar maiúsculas) e ordenados. Na aba de consulentes quem pediu acesso vem
/// primeiro, porque é quem está esperando resposta; depois, por nome.
List<UserModel> usersForTab(
  List<UserModel> all,
  MemberTab tab, {
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  final list = all.where((u) {
    if (!tab.includes(u)) return false;
    if (q.isEmpty) return true;
    return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
  }).toList();

  list.sort((a, b) {
    if (tab == MemberTab.visitors && a.isPendingApproval != b.isPendingApproval) {
      return a.isPendingApproval ? -1 : 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}
