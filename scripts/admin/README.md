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
