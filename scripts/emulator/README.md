# Ambiente de teste local (Firebase Emulator)

Dev e prod compartilham o **mesmo projeto Firebase** (`tenda-white-label`); "dev" é só um caminho (`environments/dev/...`). Testar regras e telas novas no Firebase real significaria publicá-las em produção. Por isso existe este ambiente: Auth, Firestore, Storage e Functions rodando na sua máquina, com as regras deste repositório.

## Subir

Precisa de Java 21+ (o do Android Studio serve).

```bash
# Terminal 1 — emuladores (deixe aberto). UI em http://127.0.0.1:4000
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
firebase emulators:start --project tenda-white-label --only auth,firestore,storage,functions

# Terminal 2 — contas e dados de teste (repita quando quiser zerar: reinicie o emulador antes)
node scripts/emulator/seed.js

# Terminal 3 — o app, apontando para o emulador
flutter run --flavor tucttxDev \
  --dart-define=TENANT=tucttx --dart-define=ENV=dev --dart-define-from-file=env.json \
  --dart-define=USE_EMULATOR=true
```

Host do emulador: Android emulator usa `10.0.2.2` (padrão); iOS simulator, `--dart-define=EMULATOR_HOST=localhost`; aparelho físico, o IP do Mac (`--dart-define=EMULATOR_HOST=192.168.x.x`).

Com `USE_EMULATOR=true` o app mostra a faixa **EMULADOR** no canto e recusa abrir se o Firestore não estiver mesmo no emulador. Nunca funciona em build de release.

## Contas (senha `teste123`)

| E-mail | Quem é |
|---|---|
| admin@teste.dev | Ana Admin, admin e aprovadora do financeiro |
| admin2@teste.dev | Bruno Admin, admin e aprovador do financeiro |
| membro@teste.dev | Carla Membro, sem permissões, com 12 mensalidades e dados de saúde |
| mural@teste.dev | Diego Mural, membro com a skill "publicar no mural" |
| visitante@teste.dev | Elisa Visitante, visitante ativo |
| pendente@teste.dev | Fabio Pendente, visitante que já pediu acesso |

## O que o emulador NÃO cobre

- **Push (FCM)** não é emulado. As Functions rodam e enfileiram (`notifications_queue` na UI), mas o envio depende do Google: só sai para um aparelho com token real registrado no emulador.
- **Funções agendadas** (lembretes de eventos, mensalidades atrasadas, limpeza anual) não disparam sozinhas no emulador.
- Play Services do Android emulator mostra erros `DEVELOPER_ERROR`; são ruído e não afetam o teste.

## Testes automáticos das regras

`firestore-tests/` (131 testes) roda contra este mesmo emulador. Ver `firestore-tests/README.md`.
