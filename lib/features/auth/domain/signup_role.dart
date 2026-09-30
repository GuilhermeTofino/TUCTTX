/// Papel com que um cadastro novo nasce.
///
/// O modo "consulente" (cadastro novo só vê o calendário até o admin aprovar) é uma
/// mudança que os membros sentiriam, então nasce DESLIGADO e é ligado sem publicar
/// outra versão, pelo Remote Config (`<tenant>_visitor_signup_enabled`). Desligado,
/// o cadastro continua exatamente como antes: entra como 'user'.
String signupRoleFor({required bool visitorSignupEnabled}) =>
    visitorSignupEnabled ? 'visitor' : 'user';
