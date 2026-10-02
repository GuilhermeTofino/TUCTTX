/**
 * Liga/desliga as novidades visíveis das Functions, em `settings/features`:
 *   eventReminders       lembretes diários de véspera e dia (07:00) para os membros
 *   presenceRemovedPush  aviso aos admins quando alguém desmarca presença
 *   feeReminders         lembretes de mensalidade (pré-vencimento dia 7/10 e atraso semanal)
 * Tudo nasce DESLIGADO: publicar a Function não muda nada para ninguém até ligar aqui.
 *
 * Uso:
 *   node set-feature-flag.js --show                                   -> estado atual
 *   node set-feature-flag.js --flag eventReminders --on               -> preview
 *   node set-feature-flag.js --flag eventReminders --on --apply       -> liga de verdade
 *   node set-feature-flag.js --flag eventReminders --off --apply      -> desliga
 *
 * Variáveis: ADMIN_ENV (default dev), ADMIN_TENANT_ID (default tucttx),
 * ADMIN_SERVICE_ACCOUNT_PATH. Para produção: ADMIN_ENV=prod.
 *
 * (O cadastro de visitante é outro interruptor, no Remote Config:
 *  parâmetro `<tenant>_visitor_signup_enabled`. Ver docs/rollout.md.)
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

// Mantenha igual a functions/feature_flags.js.
const FLAGS = ["eventReminders", "presenceRemovedPush", "feeReminders"];

const args = process.argv.slice(2);
const APPLY = args.includes("--apply");
const SHOW = args.includes("--show");
const flagIndex = args.indexOf("--flag");
const FLAG = flagIndex !== -1 ? args[flagIndex + 1] : null;
const ON = args.includes("--on");
const OFF = args.includes("--off");

async function main() {
    if (!SHOW && (!FLAG || ON === OFF)) {
        console.error("Use --show, ou --flag <nome> com --on ou --off (um dos dois). Veja o cabeçalho do arquivo.");
        process.exit(1);
    }
    if (FLAG && !FLAGS.includes(FLAG)) {
        console.error(`Interruptor desconhecido: "${FLAG}". Válidos: ${FLAGS.join(", ")}`);
        process.exit(1);
    }
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }

    admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
    const ref = admin.firestore().collection("environments").doc(ENV)
        .collection("tenants").doc(TENANT_ID).collection("settings").doc("features");
    const current = (await ref.get()).data() || {};

    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);
    console.log("Estado atual:");
    for (const f of FLAGS) console.log(`  ${f.padEnd(22)} ${current[f] === true ? "LIGADO" : "desligado"}`);
    if (SHOW) return;

    const next = ON;
    console.log(`\n${FLAG}: ${current[FLAG] === true ? "LIGADO" : "desligado"} -> ${next ? "LIGADO" : "desligado"}`);
    console.log(`Modo: ${APPLY ? "APLICAR" : "PREVIEW (nada é alterado)"}`);
    if (!APPLY) {
        console.log("\nNenhuma escrita foi feita (preview). Rode com --apply.");
        return;
    }
    await ref.set({ [FLAG]: next, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    console.log("Gravado.");
}

main().catch((error) => { console.error("Erro:", error); process.exit(1); });
