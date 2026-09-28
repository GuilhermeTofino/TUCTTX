/**
 * Importa presença de faxina a partir de um CSV local (transcrito manualmente
 * de uma foto do quadro de avisos, com a ajuda do Claude numa conversa) para
 * o Firestore, em environments/{ENV}/tenants/{TENANT}/events.
 *
 * Fluxo de uso:
 *   1. Manda a foto da planilha/quadro pro Claude, revisa a transcrição junto.
 *   2. Salva o CSV confirmado em escala_faxina.csv (mesma pasta deste script),
 *      no formato: nome,mes,dia  (mes por extenso: Janeiro, Fevereiro, ...;
 *      nomes com apelido usam aspas duplas escapadas, ex: "Gabriel ""Lopez""").
 *   3. Roda este script.
 *
 * Para cada (nome, mes, dia, ano):
 *   - procura um evento existente nesse dia calendário
 *   - se existir exatamente 1: adiciona os nomes em cleaningCrew e
 *     confirmedAttendance (arrayUnion, não apaga nada que já tinha)
 *   - se não existir nenhum: cria um evento novo (title: "Faxina",
 *     type: "Trabalho") com cleaningCrew e confirmedAttendance com os nomes
 *   - se existir mais de 1 no mesmo dia: precisa resolver manualmente em
 *     event-overrides.json (veja event-overrides.example.json)
 *
 * Uso:
 *   node import-faxina-attendance.js                -> dry-run (não escreve nada)
 *   node import-faxina-attendance.js --apply         -> executa de verdade
 *
 * Configuração via variáveis de ambiente (mesmas dos outros scripts em admin/):
 *   FAXINA_ENV                    (default: "prod")
 *   FAXINA_TENANT_ID              (default: "tucttx")
 *   FAXINA_SERVICE_ACCOUNT_PATH   (default: ~/Downloads/tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json)
 *   FAXINA_YEAR                   (default: ano atual)
 *   FAXINA_CSV_PATH               (default: escala_faxina.csv, nesta mesma pasta)
 */

const fs = require("fs");
const path = require("path");
const os = require("os");
const admin = require("firebase-admin");

const ENV = process.env.FAXINA_ENV || "prod";
const TENANT_ID = process.env.FAXINA_TENANT_ID || "tucttx";
const YEAR = parseInt(process.env.FAXINA_YEAR || String(new Date().getFullYear()), 10);
const CSV_PATH = process.env.FAXINA_CSV_PATH || path.join(__dirname, "escala_faxina.csv");
const EVENT_OVERRIDES_PATH = path.join(__dirname, "event-overrides.json");
const SERVICE_ACCOUNT_PATH =
    process.env.FAXINA_SERVICE_ACCOUNT_PATH ||
    path.join(os.homedir(), "Downloads", "tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json");

const APPLY = process.argv.includes("--apply");

const MESES = {
    Janeiro: 1, Fevereiro: 2, Marco: 3, Abril: 4, Maio: 5, Junho: 6,
    Julho: 7, Agosto: 8, Setembro: 9, Outubro: 10, Novembro: 11, Dezembro: 12,
};

function loadEventOverrides() {
    if (!fs.existsSync(EVENT_OVERRIDES_PATH)) return {};
    const raw = JSON.parse(fs.readFileSync(EVENT_OVERRIDES_PATH, "utf8"));
    delete raw._comment;
    return raw;
}

function parseCsv(content) {
    const lines = content.trim().split("\n");
    const header = lines[0].split(",");
    const rows = [];
    for (let i = 1; i < lines.length; i++) {
        const line = lines[i];
        if (!line.trim()) continue;
        const fields = [];
        let cur = "";
        let inQuotes = false;
        for (let j = 0; j < line.length; j++) {
            const c = line[j];
            if (c === '"') {
                if (inQuotes && line[j + 1] === '"') {
                    cur += '"';
                    j++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c === "," && !inQuotes) {
                fields.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        fields.push(cur);
        const row = {};
        header.forEach((h, idx) => (row[h.trim()] = fields[idx]));
        rows.push(row);
    }
    return rows;
}

function groupByDate(rows) {
    const byDate = new Map();
    for (const row of rows) {
        const mes = MESES[row.mes];
        if (!mes) {
            throw new Error(`Mes desconhecido: "${row.mes}" (linha: ${JSON.stringify(row)})`);
        }
        const dia = parseInt(row.dia, 10);
        const key = `${YEAR}-${String(mes).padStart(2, "0")}-${String(dia).padStart(2, "0")}`;
        if (!byDate.has(key)) byDate.set(key, new Set());
        byDate.get(key).add(row.nome);
    }
    return byDate;
}

async function main() {
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }
    if (!fs.existsSync(CSV_PATH)) {
        console.error(`CSV não encontrado em: ${CSV_PATH}`);
        console.error(`Copie escala_faxina.example.csv para escala_faxina.csv e preencha (ou defina FAXINA_CSV_PATH).`);
        process.exit(1);
    }

    const serviceAccount = require(SERVICE_ACCOUNT_PATH);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    const db = admin.firestore();

    const eventOverrides = loadEventOverrides();
    const csvContent = fs.readFileSync(CSV_PATH, "utf8");
    const rows = parseCsv(csvContent);
    const byDate = groupByDate(rows);

    console.log(`Modo: ${APPLY ? "APLICAR (vai escrever no Firestore)" : "DRY-RUN (só simulação)"}`);
    console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID} | Ano: ${YEAR}`);
    console.log(`CSV: ${CSV_PATH}`);
    console.log(`Datas distintas no CSV: ${byDate.size}`);
    console.log("---");

    const eventsRef = db
        .collection("environments").doc(ENV)
        .collection("tenants").doc(TENANT_ID)
        .collection("events");

    let matched = 0;
    let created = 0;
    const summary = [];
    const sortedDates = Array.from(byDate.keys()).sort();

    for (const dateKey of sortedDates) {
        const names = Array.from(byDate.get(dateKey)).sort();
        const [y, m, d] = dateKey.split("-").map(Number);

        const startOfDay = new Date(y, m - 1, d, 0, 0, 0, 0);
        const endOfDay = new Date(y, m - 1, d, 23, 59, 59, 999);

        const snapshot = await eventsRef
            .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
            .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
            .get();

        let targetDoc = null;
        if (snapshot.size > 1) {
            const overrideId = eventOverrides[dateKey];
            if (!overrideId) {
                throw new Error(
                    `${snapshot.size} eventos encontrados em ${dateKey} e não há override em event-overrides.json. ` +
                    `Ids: ${snapshot.docs.map((d) => `${d.id} (${d.data().title})`).join(", ")}`
                );
            }
            targetDoc = snapshot.docs.find((d) => d.id === overrideId);
            if (!targetDoc) {
                throw new Error(`Override ${overrideId} para ${dateKey} não encontrado entre os eventos retornados.`);
            }
        } else if (snapshot.size === 1) {
            targetDoc = snapshot.docs[0];
        }

        if (!targetDoc) {
            summary.push({ dateKey, action: "CRIAR", names, eventId: null });
            created++;
            if (APPLY) {
                const noonLocal = new Date(y, m - 1, d, 12, 0, 0, 0);
                await eventsRef.add({
                    title: "Faxina",
                    date: admin.firestore.Timestamp.fromDate(noonLocal),
                    type: "Trabalho",
                    tenantId: TENANT_ID,
                    cleaningCrew: names,
                    confirmedAttendance: names,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        } else {
            summary.push({ dateKey, action: "ATUALIZAR", names, eventId: targetDoc.id, title: targetDoc.data().title });
            matched++;
            if (APPLY) {
                await targetDoc.ref.update({
                    cleaningCrew: admin.firestore.FieldValue.arrayUnion(...names),
                    confirmedAttendance: admin.firestore.FieldValue.arrayUnion(...names),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
    }

    for (const s of summary) {
        console.log(
            `${s.dateKey} [${s.action}]${s.eventId ? ` (evento ${s.eventId} - ${s.title})` : ""}: ${s.names.join(", ")}`
        );
    }

    console.log("---");
    console.log(`Eventos existentes atualizados: ${matched}`);
    console.log(`Eventos novos criados: ${created}`);
    console.log(`Total de datas processadas: ${sortedDates.length}`);
    if (!APPLY) {
        console.log("\nNenhuma escrita foi feita (dry-run). Rode com --apply para gravar de verdade.");
    }
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error("Erro:", err.message);
        process.exit(1);
    });
