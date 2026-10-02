/**
 * Ativa as mensalidades de todos os membros de uma vez (o que o botão de sincronizar
 * do perfil faz, um a um): cria `financial/{uid}/monthly_fees/{ano}_{mês}` com status
 * `pending` para cada mês do ano que ainda não existe.
 *
 * - Só entra quem tem role `user` ou `admin` (`--roles user` para só membros).
 * - `--from-month N` (1-12): só cria de N em diante. Default: o mês atual se o ano for o
 *   atual (meses passados não são criados, para não nascerem já vencidos); 1 em outro ano.
 * - Idempotente: mês que já existe (pago, atrasado, valor editado) nunca é tocado.
 * - Valor inicial: R$ 120 (`--value N` troca). Não é fixo: o valor real é ajustado na
 *   baixa, no app.
 *
 * Uso:
 *   node activate-monthly-fees.js                      -> preview, ano atual, user+admin
 *   node activate-monthly-fees.js --apply              -> grava de verdade
 *   node activate-monthly-fees.js --from-month 1 --apply   -> inclui meses passados
 *   node activate-monthly-fees.js --year 2027 --apply
 *   node activate-monthly-fees.js --roles user --apply
 *   node activate-monthly-fees.js --value 150 --apply
 *
 * Variáveis: ADMIN_ENV (default dev), ADMIN_TENANT_ID (default tucttx),
 * ADMIN_SERVICE_ACCOUNT_PATH. Para produção: ADMIN_ENV=prod.
 * ATENÇÃO: dev e prod compartilham o projeto Firebase; confira o ambiente impresso.
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

const args = process.argv.slice(2);
const APPLY = args.includes("--apply");

function argValue(name) {
    const index = args.indexOf(name);
    return index !== -1 ? args[index + 1] : null;
}

const YEAR = argValue("--year") ? Number(argValue("--year")) : new Date().getFullYear();
const VALUE = argValue("--value") ? Number(argValue("--value")) : 120;
const CURRENT = new Date();
const FROM_MONTH = argValue("--from-month")
    ? Number(argValue("--from-month"))
    : (YEAR === CURRENT.getFullYear() ? CURRENT.getMonth() + 1 : 1);
const ROLES = (argValue("--roles") || "user,admin").split(",").map((r) => r.trim()).filter(Boolean);

async function main() {
    if (!Number.isInteger(YEAR) || YEAR < 2000 || YEAR > 2100) {
        console.error(`Ano inválido: ${argValue("--year")}`);
        process.exit(1);
    }
    if (!Number.isInteger(FROM_MONTH) || FROM_MONTH < 1 || FROM_MONTH > 12) {
        console.error(`Mês inválido: ${argValue("--from-month")}`);
        process.exit(1);
    }
    if (!Number.isFinite(VALUE) || VALUE < 0) {
        console.error(`Valor inválido: ${argValue("--value")}`);
        process.exit(1);
    }
    if (ROLES.length === 0 || ROLES.some((r) => !["user", "admin"].includes(r))) {
        console.error('--roles aceita apenas "user" e/ou "admin".');
        process.exit(1);
    }
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }

    admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
    const db = admin.firestore();
    const tenantRoot = db.collection("environments").doc(ENV).collection("tenants").doc(TENANT_ID);

    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID} | Ano: ${YEAR} (a partir do mês ${FROM_MONTH}) | Roles: ${ROLES.join(",")} | Valor inicial: ${VALUE}`);
    console.log(`Modo: ${APPLY ? "APLICAR (vai gravar de verdade)" : "PREVIEW (nada é alterado)"}\n`);

    const users = await tenantRoot.collection("users").where("role", "in", ROLES).get();
    const writer = db.bulkWriter();
    let created = 0;
    let usersTouched = 0;

    for (const userDoc of users.docs) {
        const coll = tenantRoot.collection("financial").doc(userDoc.id).collection("monthly_fees");
        const existing = new Set((await coll.get()).docs.map((d) => d.id));
        const missing = [];
        for (let m = FROM_MONTH; m <= 12; m++) if (!existing.has(`${YEAR}_${m}`)) missing.push(m);

        console.log(`${missing.length === 0 ? "OK   " : "CRIAR"} ${userDoc.data().name || userDoc.id}: ${missing.length === 0 ? "já completo" : `${missing.length} mês(es)`}`);
        if (missing.length === 0) continue;

        usersTouched++;
        created += missing.length;
        if (!APPLY) continue;
        for (const m of missing) {
            // create() não sobrescreve: se alguém criou no meio do caminho, só falha esse doc.
            writer.create(coll.doc(`${YEAR}_${m}`), {
                userId: userDoc.id,
                month: m,
                year: YEAR,
                value: VALUE,
                status: "pending",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }).catch((e) => console.error(`  falha em ${userDoc.id} ${YEAR}_${m}: ${e.message}`));
        }
    }

    await writer.close();
    console.log(`\n${users.size} membro(s) lidos; ${usersTouched} precisam de mensalidades (${created} documento(s)).`);
    console.log(APPLY ? "Gravado." : "Nenhuma escrita foi feita (preview). Rode com --apply para gravar.");
}

main().catch((error) => {
    console.error("Erro:", error);
    process.exit(1);
});
