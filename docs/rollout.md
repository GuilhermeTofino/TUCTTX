# Roteiro de publicação: comprovantes PIX, papéis e skills, edição de cadastro

Objetivo: colocar tudo em produção **sem que quem já usa o app sinta a mudança**, e ligar cada novidade visível só quando a equipe quiser.

> Dev e prod compartilham o **mesmo projeto Firebase** (`tenda-white-label`); "dev" é só um caminho. Todo `firebase deploy` vale para produção na hora.

## Princípio

Publicar por trás: primeiro o que é invisível e compatível com o app atual, depois o app, e por fim ligar as novidades, uma de cada vez.

| Fase | O que sobe | Quem já usa o app sente? |
|---|---|---|
| 1 | Regras do Firestore e Storage | Não (compatíveis com o app atual; 131 testes) |
| 2 | Functions novas, **desligadas** | Não |
| 3 | Dados de configuração (aprovadores, interruptores) | Não |
| 4 | App novo nas lojas, cadastro de visitante **desligado** | Só vê "Editar Meu Cadastro" |
| 5 | Atualização forçada (automática) e migração da saúde | Não |
| 6 | Ligar novidades, uma por vez | Sim, de propósito |
| 7 | Tirar a compatibilidade com o app antigo das regras | Não |

## Antes de tudo

- [ ] Roteiro de testes no emulador aprovado (`scripts/emulator/README.md`).
- [ ] `firestore-tests`: `firebase emulators:exec --only firestore,storage --project demo-tucttx "npm test"` verde (131).
- [ ] `flutter analyze`, `flutter test` e os testes de Node (`node functions/*.test.js scripts/admin/*.test.js`) verdes.
- [ ] Node 20 das Functions **deixa de aceitar deploy em 30/10/2026**. Faça a fase 2 antes disso ou atualize o runtime.

## Fase 1: regras

```bash
firebase deploy --only firestore:rules,storage
```

Conferir: entrar com uma conta real de membro e uma de admin no app **atual** e abrir Home, Calendário, Mural, Estudos, Financeiro e (admin) Membros. Tudo como antes.

Reverter: `git checkout 2240172 -- firestore.rules storage.rules` e publicar de novo (é a versão que está no ar hoje).

## Fase 2: Functions (dormentes)

```bash
firebase deploy --only functions:default:sendEventReminders,functions:default:notifyAdminsOnPresenceRemoved
```

As duas nascem **desligadas** (`settings/features`): a Function existe, mas não envia nada. Conferir:

```bash
ADMIN_ENV=prod node scripts/admin/set-feature-flag.js --show   # tudo "desligado"
```

Nos logs do Firebase deve aparecer `eventReminders desligado: nada enviado.`

## Fase 3: dados de configuração em produção

- **Aprovadores do financeiro** (sem isso ninguém aprova comprovante nem recebe o push): pelo app (Membros → membro admin → Aprovador Financeiro) ou `FINANCE_ENV=prod node scripts/admin/set-finance-approvers.js --approvers <uid1,uid2> --apply`.
- **Remote Config** (console do Firebase): criar o parâmetro `tucttx_visitor_signup_enabled` (booleano) com valor **false** e publicar. Criar explicitamente evita dúvida sobre o estado.
- Catálogo de skills (opcional): `ADMIN_ENV=prod node scripts/admin/seed-skills-catalog.js --apply`.

## Fase 4: app novo

1. **Incrementar a versão** em `pubspec.yaml` (hoje `2.26.080+61`). O Play recusa upload com `versionCode` repetido.
2. Abrir o PR para `develop` e revisar.
3. **Atenção: o merge na `develop` (ou `main`) dispara o Codemagic**, que compila o flavor de **produção** e publica no **teste interno** do Google Play. Não vai para todos: a promoção para produção é manual no Play Console.
4. Testar o build no teste interno em aparelho real (login, Home, Editar Meu Cadastro, comprovante, foto de perfil).
5. Promover para produção no Play Console. iOS é manual: `pod install`, arquivar no Xcode (o `aps-environment` vira `production` sozinho no arquivamento) e enviar ao TestFlight.

## Fase 5: atualização forçada e migração da saúde

A Function `syncForceUpdateVersion` copia a versão publicada nas lojas para o Remote Config a cada 30 minutos, então **quem está numa versão antiga é forçado a atualizar sozinho** depois do lançamento.

Só quando praticamente todos tiverem atualizado:

```bash
ADMIN_ENV=prod node scripts/admin/migrate-private-health.js            # preview: só contagens
ADMIN_ENV=prod node scripts/admin/migrate-private-health.js --apply    # migra
```

Hoje os dados de saúde dos membros estão no documento aberto, legível por qualquer usuário logado. Essa é a maior razão para não adiar esta fase.

## Fase 6: ligar as novidades, uma por vez

```bash
# lembretes diários de véspera e dia, às 07:00, para todos os membros
ADMIN_ENV=prod node scripts/admin/set-feature-flag.js --flag eventReminders --on --apply
# aviso aos admins quando alguém desmarca presença
ADMIN_ENV=prod node scripts/admin/set-feature-flag.js --flag presenceRemovedPush --on --apply
```

Cadastro de visitante: no Remote Config, `tucttx_visitor_signup_enabled` = true e publicar. Chega aos aparelhos em até 1 hora. **Antes de ligar**, combine quem vai aprovar visitantes (Membros → filtro "Aguardando aprovação"), porque cadastros novos passam a ver só o calendário.

Para desligar qualquer um, o mesmo comando com `--off` (Remote Config: valor false).

## Fase 7: limpar a compatibilidade

Depois da fase 5 concluída, um commit de regras: parar de aceitar cadastro com `role: 'user'` e recusar campos de saúde no documento aberto do usuário.

## O que os usuários sentem em cada caso

- Quem já usa o app: o item **Editar Meu Cadastro** nas configurações. Nada mais, até a fase 6.
- Admins: novas opções no cartão do membro (aprovar visitante, permissões, histórico).
- Quem entra pela primeira vez, só depois de ligar o cadastro de visitante: vê apenas o calendário até ser aprovado.
