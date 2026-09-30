# Faxina — presença, ranking e notificações

Ferramentas de administração da faxina: importar presença a partir da foto do quadro de avisos, recalcular o ranking, disparar notificações (script local ou WhatsApp) e zerar o ranking quando precisar reiniciar o ciclo.

## Visão geral do fluxo

```
foto do quadro
      │
      ▼
transcrição com o Claude (chat) ──► escala_faxina.csv
      │
      ▼
node import-faxina-attendance.js --apply
      │
      ▼
Firestore atualizado (cleaningCrew / confirmedAttendance)
      │
      ├──► node faxina-ranking-notify.js --send   (dispara pelo terminal)
      │
      └──► "ranking faxina" no WhatsApp            (dispara pelo bot)
```

Importante: mandar `ranking faxina` no WhatsApp **não lê a foto nem importa nada** — ele só recalcula e notifica com base no que já estiver salvo no Firestore naquele momento. A importação da foto é sempre um passo manual anterior.

## Setup (uma vez só)

Todos os scripts usam as mesmas variáveis de ambiente, com defaults sensatos:

| Variável | Default |
|---|---|
| `FAXINA_ENV` | `prod` |
| `FAXINA_TENANT_ID` | `tucttx` |
| `FAXINA_SERVICE_ACCOUNT_PATH` | `~/Downloads/tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json` |
| `FAXINA_YEAR` (só no import) | ano atual |
| `FAXINA_CSV_PATH` (só no import) | `escala_faxina.csv` nesta pasta |

Instalar dependências (uma vez, ou sempre que o `package.json` mudar):

```bash
cd scripts/admin
npm install
```

## 1. Importar presença de uma foto nova

1. Manda a foto do quadro de avisos pro Claude, numa conversa.
2. Ele transcreve célula por célula pra um CSV (`nome,mes,dia`) e confere com você qualquer caligrafia ambígua ou data que não bate.
3. Salva o CSV confirmado em `escala_faxina.csv` (nesta pasta) — copie `escala_faxina.example.csv` como ponto de partida se for fazer manualmente.
4. Rode em modo prévia primeiro:
   ```bash
   node import-faxina-attendance.js
   ```
   Confere a lista de `[CRIAR]` (evento novo) e `[ATUALIZAR]` (evento existente) antes de aplicar.
5. Se aparecer erro de "mais de 1 evento no mesmo dia", copie `event-overrides.example.json` para `event-overrides.json` e escolha o id do evento certo (o erro já lista as opções com título de cada um).
6. Aplica de verdade:
   ```bash
   node import-faxina-attendance.js --apply
   ```

O que o script faz com cada nome do CSV:
- Se já existe **exatamente 1 evento** naquele dia: adiciona o nome em `cleaningCrew` e `confirmedAttendance` (via `arrayUnion` — nunca apaga o que já tinha).
- Se **não existe nenhum evento**: cria um evento novo (`title: "Faxina"`, `type: "Trabalho"`) com os nomes daquele dia.
- Se existem **2+ eventos** no mesmo dia: para, e pede pra resolver manualmente em `event-overrides.json` (não adivinha sozinho qual é o certo).

`escala_faxina.csv` e `event-overrides.json` não são versionados no git (mudam a cada rodada) — só os `.example` ficam no repositório como modelo.

## 2. Recalcular o ranking e notificar

O ranking é: para cada evento com `cleaningCrew` não vazio, conta quantas vezes cada nome aparece em `confirmedAttendance` (só conta se o nome também estiver escalado naquele evento). Ordena por contagem decrescente; em empate, ordem alfabética (mesma regra usada em `cleaning_dashboard_viewmodel.dart` no app).

Resolve nome → conta do app por primeiro nome (ignorando acento/caixa, e aceitando sobrenome no meio do nome cadastrado). Nomes ambíguos (duas pessoas com o mesmo primeiro nome) ficam em `overrides.json` (copie `overrides.example.json`).

```bash
node faxina-ranking-notify.js            # prévia (não envia nada)
node faxina-ranking-notify.js --send     # dispara notificação push pra cada pessoa com a posição dela
```

### Disparo pelo WhatsApp

Além de rodar o script manualmente, o mesmo recálculo pode ser disparado mandando uma mensagem de WhatsApp de um número autorizado (lista em `functions-whatsapp/index.js`, `WHATSAPP_ALLOWED_SENDERS`) para o número do bot:

- `ranking faxina teste` → roda tudo, mas **não envia nada** (modo de teste, só confirma o resultado)
- `ranking faxina` → dispara de verdade

Isso chama a Cloud Function `whatsappRankingTrigger` (codebase `whatsapp`, região `southamerica-east1`), que reusa a mesma lógica de `faxina_ranking.js`.

## 3. Zerar o ranking (reiniciar o ciclo)

Limpa `confirmedAttendance` de todos os eventos (mantém `cleaningCrew`, ou seja, o histórico de quem foi escalado continua):

```bash
node reset-faxina-ranking.js            # prévia
node reset-faxina-ranking.js --apply    # zera de verdade
```

## Arquivos desta pasta

| Arquivo | O que faz |
|---|---|
| `import-faxina-attendance.js` | Importa presença de um CSV local pro Firestore |
| `faxina-ranking-notify.js` | Recalcula o ranking e dispara notificação push |
| `reset-faxina-ranking.js` | Zera `confirmedAttendance` de todos os eventos |
| `escala_faxina.example.csv` | Modelo do CSV de presença (copie para `escala_faxina.csv`) |
| `event-overrides.example.json` | Modelo pra resolver dia com 2+ eventos (copie para `event-overrides.json`) |
| `overrides.example.json` | Modelo pra resolver nome ambíguo no ranking (copie para `overrides.json`) |

Nenhum desses três `.json`/`.csv` de dados reais é versionado no git — só os `.example` servem de modelo.

## WhatsApp — infraestrutura (referência)

- Código: `functions-whatsapp/` (codebase separado do `functions/` default, de propósito — assim o deploy nunca depende de secrets de outras functions não relacionadas, como o `PLAY_PUBLISHER_KEY`).
- Deploy: `firebase deploy --only functions:whatsapp` (da raiz do projeto).
- Secrets necessários (`firebase functions:secrets:set NOME`): `WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `SCHEDULER_TOKEN`.
- Números autorizados a comandar o bot: hardcoded em `functions-whatsapp/index.js` (`WHATSAPP_ALLOWED_SENDERS`).

---

# Comprovantes de mensalidade — aprovadores e retenção

O membro envia o comprovante do PIX pelo app e um aprovador do financeiro confere e dá baixa no mês. Quem aprova é definido por uma lista em `environments/{env}/tenants/{tenant}/settings/finance` (campo `approverIds`).

## Definir os aprovadores

Pelo app: Painel administrativo → Membros → toque no membro (que já deve ser admin) → **Aprovador Financeiro** (ou **Remover Aprovador**). Rebaixar um admin também o tira da lista. O script abaixo continua útil para configurar um tenant novo ou várias pessoas de uma vez.

Só admins podem entrar na lista (as regras do Firestore exigem ser admin **e** constar em `approverIds`). Sem essa lista ninguém aprova e ninguém recebe o push de "comprovante aguardando".

```bash
cd scripts/admin
node set-finance-approvers.js --list-admins                  # uid e nome dos admins
node set-finance-approvers.js --approvers uid1,uid2          # preview (não escreve)
node set-finance-approvers.js --approvers uid1,uid2 --apply  # grava
node set-finance-approvers.js --show                         # lista atual
```

- A gravação **substitui** a lista inteira: passe todos os aprovadores de uma vez.
- O script recusa uid inexistente ou que não seja admin, e não grava nada nesse caso.
- Por padrão usa `FINANCE_ENV=dev`. Para produção: `FINANCE_ENV=prod node set-finance-approvers.js ...`. Outras variáveis: `FINANCE_TENANT_ID` (default `tucttx`) e `FINANCE_SERVICE_ACCOUNT_PATH`.

## Retenção dos arquivos

Os comprovantes ficam em `receipts/{ano}/{userId}/{requestId}`, na pasta do ano do mês mais recente que o comprovante cobre. A Function `deleteExpiredReceipts` roda em 1º de janeiro (03:00, America/Sao_Paulo) e apaga os arquivos de anos **anteriores** ao atual; o ano corrente nunca é tocado.

Só o arquivo é removido. A solicitação e os dados contábeis (valor, `paidAt`, aprovador) continuam no Firestore; a tela de revisão passa a mostrar "comprovante indisponível".

---

# Papéis, skills e dados de saúde

Modelo de acesso: `visitor` (só vê o calendário), `user` (filho de santo; acessa mural, estudos, financeiro etc. e tem as **skills** que o admin marcar) e `admin` (todas as skills + gestão de membros). Todo cadastro novo nasce visitante e pede acesso pelo app; o admin aprova em Painel administrativo → Membros. Toda mudança de papel/skills vai para o `audit_log` e pode ser desfeita pelo histórico do membro.

Skills: `calendario.gerenciar`, `mural.publicar`, `estudos.gerenciar`, `financeiro.gerenciar`, `bazar.gerenciar`, `limpeza.gerenciar`, `entidades.moderar`, `notificacoes.enviar`. As regras (`firestore.rules`/`storage.rules`) conhecem exatamente estas 8; se mudar uma, mude em `PermissionService` também. Gestão de membros, atalhos da Home e aprovação de comprovantes continuam só do admin.

Variáveis dos scripts abaixo: `ADMIN_ENV` (default `dev`), `ADMIN_TENANT_ID` (default `tucttx`), `ADMIN_SERVICE_ACCOUNT_PATH`.

## Catálogo de skills (opcional)

```bash
cd scripts/admin
node seed-skills-catalog.js          # preview
node seed-skills-catalog.js --apply  # grava (não sobrescreve rótulos já editados)
```

O app funciona sem o catálogo (usa rótulos padrão). Serve para o admin ajustar rótulo e descrição.

## Migrar dados de saúde para a subcoleção privada

Alergias, medicamentos, condições médicas e tipo sanguíneo são dado pessoal sensível (LGPD). Antes ficavam no documento do usuário, que qualquer membro logado lê. Agora ficam em `users/{uid}/private/health` (só o dono e os admins leem).

```bash
node migrate-private-health.js          # preview: só contagens, nunca imprime os valores
node migrate-private-health.js --apply  # copia para o privado e remove do documento aberto
```

- Idempotente; o que já estiver no privado prevalece.
- **Em produção, rode só depois de a versão nova estar nas lojas e a atualização estar forçada.** O app antigo ainda grava saúde no documento aberto; rode de novo depois, sem risco.
- Enquanto não migrar, a tela de perfil e a ficha do admin caem nos campos antigos do documento.

---

# Interruptores das novidades

Lembretes de eventos e o aviso de presença desmarcada são visíveis para os membros/admins, então nascem **desligados**: a Function publicada fica dormente até alguém ligar, por tenant, em `settings/features`.

```bash
node set-feature-flag.js --show                                  # estado
node set-feature-flag.js --flag eventReminders --on --apply      # liga (ADMIN_ENV=prod para produção)
node set-feature-flag.js --flag presenceRemovedPush --off --apply
```

O cadastro de visitante é outro interruptor, no Remote Config (`<tenant>_visitor_signup_enabled`). Ver `docs/rollout.md` para a ordem completa de publicação.
