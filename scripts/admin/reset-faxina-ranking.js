/**
 * Zera o ranking de faxina: limpa o campo `confirmedAttendance` de todos os
 * eventos que têm `cleaningCrew` definido, mantendo `cleaningCrew` intacto
 * (quem estava escalado continua registrado, só as presenças são zeradas).
 *
 * Uso:
 *   node reset-faxina-ranking.js            -> preview (não escreve nada)
 *   node reset-faxina-ranking.js --apply    -> zera de verdade
 *
 * Configuração via variáveis de ambiente (mesmas do faxina-ranking-notify.js):
 *   FAXINA_ENV                    (default: "prod")
 *   FAXINA_TENANT_ID              (default: "tucttx")
 *   FAXINA_SERVICE_ACCOUNT_PATH   (default: ~/Downloads/tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json)
 */

const fs = require("fs");
const path = require("path");
const os = require("os");
const admin = require("firebase-admin");

const ENV = process.env.FAXINA_ENV || "prod";
const TENANT_ID = process.env.FAXINA_TENANT_ID || "tucttx";
const SERVICE_ACCOUNT_PATH =
    process.env.FAXINA_SERVICE_ACCOUNT_PATH ||
    path.join(os.homedir(), "Downloads", "tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json");

const APPLY = process.argv.includes("--apply");

async function main() {
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }

    const serviceAccount = require(SERVICE_ACCOUNT_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    const db = admin.firestore();

    const eventsRef = db
        .collection("environments")
        .doc(ENV)
        .collection("tenants")
        .doc(TENANT_ID)
        .collection("events");

    const snapshot = await eventsRef.get();

    const toReset = [];
    snapshot.forEach((doc) => {
        const e = doc.data();
        const crew = e.cleaningCrew;
        const attendance = e.confirmedAttendance;
        if (crew && crew.length > 0 && attendance && attendance.length > 0) {
            toReset.push({ id: doc.id, title: e.title, date: e.date?.toDate?.(), attendance });
        }
    });

    console.log(`Modo: ${APPLY ? "APLICAR (vai zerar de verdade)" : "PREVIEW (nada é alterado)"}`);
    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);
    console.log(`Eventos com presença confirmada a zerar: ${toReset.length}`);
    console.log("---");

    for (const e of toReset) {
        console.log(`${e.date?.toISOString().slice(0, 10) || "?"} | ${e.title} (${e.id}): ${e.attendance.join(", ")}`);
    }

    if (!APPLY) {
        console.log("\nNenhuma escrita foi feita (preview). Rode com --apply para zerar de verdade.");
        return;
    }

    console.log("\nZerando...");
    let updated = 0;
    for (const e of toReset) {
        await eventsRef.doc(e.id).update({
            confirmedAttendance: [],
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        updated++;
    }
    console.log(`Eventos zerados: ${updated}`);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error("Erro:", err);
        process.exit(1);
    });
