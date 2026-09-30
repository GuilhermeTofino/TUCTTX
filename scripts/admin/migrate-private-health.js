/**
 * Move os dados de saúde de dentro do documento do usuário para a subcoleção
 * privada `users/{uid}/private/health`.
 *
 * Por quê: o documento do usuário é legível por qualquer membro logado. Alergias,
 * medicamentos, condições médicas e tipo sanguíneo são dado pessoal sensível
 * (LGPD) e só devem ser vistos pelo próprio usuário e pelos admins.
 *
 * O que faz, para cada usuário que ainda tem esses campos no documento:
 *   1. copia os campos para users/{uid}/private/health (o que já existir lá
 *      prevalece: só preenche o que falta);
 *   2. remove os campos do documento do usuário.
 * É idempotente: pode rodar de novo sem duplicar nem sobrescrever.
 * NUNCA imprime os valores de saúde, só contagens e uids.
 *
 * Uso:
 *   node migrate-private-health.js            -> preview (não escreve nada)
 *   node migrate-private-health.js --apply    -> migra de verdade
 *
 * QUANDO RODAR EM PRODUÇÃO: só depois de a versão nova do app estar nas lojas e a
 * atualização estar forçada. O app antigo ainda grava saúde no documento do
 * usuário; rodar antes só empurra o problema (é seguro rodar de novo depois).
 *
 * Variáveis de ambiente:
 *   ADMIN_ENV                   (default: "dev")
 *   ADMIN_TENANT_ID             (default: "tucttx")
 *   ADMIN_SERVICE_ACCOUNT_PATH  (default: o mesmo dos outros scripts)
 */

const fs = require("fs");
const path = require("path");
const os = require("os");
const admin = require("firebase-admin");

const ENV = process.env.ADMIN_ENV || "dev";
const TENANT_ID = process.env.ADMIN_TENANT_ID || "tucttx";
const SERVICE_ACCOUNT_PATH =
    process.env.ADMIN_SERVICE_ACCOUNT_PATH ||
    process.env.FAXINA_SERVICE_ACCOUNT_PATH ||
    path.join(os.homedir(), "Downloads", "tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json");
const APPLY = process.argv.includes("--apply");

const HEALTH_FIELDS = ["alergias", "medicamentos", "condicoesMedicas", "tipoSanguineo"];
const hasValue = (v) => typeof v === "string" ? v.trim() !== "" : v != null;

/** Campos de saúde a mover: os que existem no documento e ainda faltam no privado. */
function planMove(userData, privateData) {
    const toCopy = {};
    const toDelete = [];
    for (const field of HEALTH_FIELDS) {
        if (!(field in userData)) continue;
        toDelete.push(field); // sai do documento aberto, tenha valor ou não
        if (hasValue(userData[field]) && !hasValue(privateData?.[field])) {
            toCopy[field] = typeof userData[field] === "string" ? userData[field].trim() : userData[field];
        }
    }
    return { toCopy, toDelete };
}

async function main() {
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }
    admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
    const db = admin.firestore();
    const users = db.collection("environments").doc(ENV).collection("tenants").doc(TENANT_ID).collection("users");

    console.log(`Modo: ${APPLY ? "APLICAR (vai mover de verdade)" : "PREVIEW (nada é alterado)"}`);
    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);

    const snapshot = await users.get();
    let toMigrate = 0, copiedFields = 0, deletedFields = 0;

    for (const doc of snapshot.docs) {
        const privateRef = doc.ref.collection("private").doc("health");
        const privateSnap = await privateRef.get();
        const { toCopy, toDelete } = planMove(doc.data(), privateSnap.exists ? privateSnap.data() : null);
        if (toDelete.length === 0) continue;

        toMigrate++;
        copiedFields += Object.keys(toCopy).length;
        deletedFields += toDelete.length;
        console.log(`  ${doc.id}: copia ${Object.keys(toCopy).length} campo(s), remove ${toDelete.length} do documento aberto`);

        if (!APPLY) continue;
        // Primeiro grava no privado; só remove do documento aberto se isso deu certo.
        if (Object.keys(toCopy).length > 0) {
            await privateRef.set({ ...toCopy, migratedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        }
        const removal = {};
        for (const field of toDelete) removal[field] = admin.firestore.FieldValue.delete();
        await doc.ref.update(removal);
    }

    console.log("---");
    console.log(`Usuários no tenant: ${snapshot.size}`);
    console.log(`Usuários com saúde no documento aberto: ${toMigrate}`);
    console.log(`Campos a copiar: ${copiedFields} | campos a remover do documento: ${deletedFields}`);
    if (!APPLY) console.log("\nNenhuma escrita foi feita (preview). Rode com --apply para migrar.");
}

if (require.main === module) {
    main().catch((error) => { console.error("Erro:", error); process.exit(1); });
}

module.exports = { planMove };
