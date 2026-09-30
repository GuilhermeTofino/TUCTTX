# Testes das regras do Firebase

Testam `firestore.rules` e `storage.rules` contra o **emulador local** (nada é publicado, nenhum dado real é tocado).

## Rodar

Requer Java 21+ (o do Android Studio serve) e o `firebase-tools`:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
cd firestore-tests
npm install                       # uma vez
firebase emulators:exec --only firestore,storage --project demo-tucttx "npm test"
```

## O que cobrem

- **Firestore** (`firestore.rules.test.js`): cadastro, edição do próprio perfil, pedido de aprovação do visitante, admin e moderação, dados de saúde privados, auditoria, skills por coleção, financeiro, comprovantes e aprovadores, fila de notificações.
- **Storage** (`storage.rules.test.js`): comprovantes (dono, aprovador, tipo, tamanho, sobrescrita), estudos por papel/skill e foto de perfil.

## Como confiar nos testes

Faça um teste de mutação: copie a regra, quebre de propósito (ex.: `isMember()` retornando `true`) e rode com
`RULES_PATH=/caminho/regra_quebrada.rules` (Firestore) ou `STORAGE_RULES_PATH=...` (Storage). A suíte tem de falhar.
