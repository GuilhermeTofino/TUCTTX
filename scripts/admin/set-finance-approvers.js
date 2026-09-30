/**
 * Define quem aprova comprovantes de mensalidade: grava `approverIds` em
 * `environments/{env}/tenants/{tenant}/settings/finance`.
 *
 * Só admins podem entrar na lista (as regras do Firestore exigem os dois: ser
 * admin E constar em `approverIds`). O script recusa ids que não existam ou não
 * sejam admin.
 *
 * Uso:
 *   node set-finance-approvers.js --list-admins                 -> lista os admins (uid e nome)
 *   node set-finance-approvers.js --approvers uid1,uid2         -> preview (não escreve nada)
 *   node set-finance-approvers.js --approvers uid1,uid2 --apply -> grava de verdade
 *   node set-finance-approvers.js --show                        -> mostra a lista atual
 *
 * A gravação SUBSTITUI a lista inteira; passe todos os aprovadores de uma vez.
 *
 * Configuração via variáveis de ambiente:
 *   FINANCE_ENV                   (default: "dev" — a feature ainda não está em prod)
 *   FINANCE_TENANT_ID             (default: "tucttx")
 *   FINANCE_SERVICE_ACCOUNT_PATH  (default: o mesmo dos scripts de faxina)
 */

const fs = require("fs");
const path = require("path");
const os = require("os");
const admin = require("firebase-admin");

const ENV = process.env.FINANCE_ENV || "dev";
const TENANT_ID = process.env.FINANCE_TENANT_ID || "tucttx";
const SERVICE_ACCOUNT_PATH =
    process.env.FINANCE_SERVICE_ACCOUNT_PATH ||
    process.env.FAXINA_SERVICE_ACCOUNT_PATH ||
    path.join(os.homedir(), "Downloads", "tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json");

const args = process.argv.slice(2);
const APPLY = args.includes("--apply");
const LIST_ADMINS = args.includes("--list-admins");
const SHOW = args.includes("--show");

function approverIdsFromArgs() {
    const index = args.indexOf("--approvers");
    if (index === -1 || !args[index + 1]) return null;
    return [...new Set(args[index + 1].split(",").map((id) => id.trim()).filter(Boolean))];
}

async function main() {
    const approverIds = approverIdsFromArgs();
    if (!LIST_ADMINS && !SHOW && !approverIds) {
        console.error("Informe --approvers uid1,uid2 (ou use --list-admins / --show). Veja o cabeçalho do arquivo.");
        process.exit(1);
    }

    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }

    admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
    const db = admin.firestore();
    const tenantRoot = db.collection("environments").doc(ENV).collection("tenants").doc(TENANT_ID);
    const settingsRef = tenantRoot.collection("settings").doc("finance");

    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);

    if (LIST_ADMINS) {
        const admins = await tenantRoot.collection("users").where("role", "==", "admin").get();
        console.log(`Admins (${admins.size}):`);
        admins.forEach((doc) => console.log(`  ${doc.id}  ${doc.data().name || "(sem nome)"}`));
        return;
    }

    const current = await settingsRef.get();
    const currentIds = current.exists ? current.data().approverIds || [] : [];

    if (SHOW) {
        console.log(`Aprovadores atuais (${currentIds.length}): ${currentIds.join(", ") || "(nenhum)"}`);
        return;
    }

    // Valida cada id: precisa existir e ser admin.
    const problems = [];
    console.log("---");
    for (const id of approverIds) {
        const userDoc = await tenantRoot.collection("users").doc(id).get();
        if (!userDoc.exists) {
            problems.push(`${id}: usuário não encontrado`);
        } else if (userDoc.data().role !== "admin") {
            problems.push(`${id} (${userDoc.data().name}): não é admin`);
        } else {
            console.log(`OK  ${id}  ${userDoc.data().name}`);
        }
    }

    if (problems.length > 0) {
        console.error("\nNada foi gravado. Corrija:");
        problems.forEach((p) => console.error(`  - ${p}`));
        process.exit(1);
    }

    console.log(`\nAtual:  ${currentIds.join(", ") || "(nenhum)"}`);
    console.log(`Novo:   ${approverIds.join(", ")}`);
    console.log(`Modo: ${APPLY ? "APLICAR (vai gravar de verdade)" : "PREVIEW (nada é alterado)"}`);

    if (!APPLY) {
        console.log("\nNenhuma escrita foi feita (preview). Rode com --apply para gravar.");
        return;
    }

    await settingsRef.set({
        approverIds,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log("\nLista de aprovadores gravada.");
}

main().catch((error) => {
    console.error("Erro:", error);
    process.exit(1);
});
