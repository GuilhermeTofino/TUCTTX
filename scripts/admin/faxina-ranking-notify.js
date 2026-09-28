/**
 * Recalcula o ranking de faxina direto do Firestore (mesma fórmula usada em
 * cleaning_dashboard_viewmodel.dart) e envia notificação push personalizada
 * com a posição de cada pessoa, para quem tiver conta e token FCM no app.
 *
 * Não depende de nenhuma planilha: os dados de presença já estão em
 * events/{id}.cleaningCrew / confirmedAttendance, então basta rodar este
 * script sempre que quiser recalcular e reenviar o ranking atualizado.
 *
 * Configuração via variáveis de ambiente (todas opcionais, têm default):
 *   FAXINA_ENV                    (default: "prod")
 *   FAXINA_TENANT_ID              (default: "tucttx")
 *   FAXINA_SERVICE_ACCOUNT_PATH   (default: ~/Downloads/tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json)
 *
 * Uso:
 *   cd scripts/admin
 *   npm install          (só na primeira vez)
 *   node faxina-ranking-notify.js            -> preview (não envia nada)
 *   node faxina-ranking-notify.js --send     -> envia de verdade
 *
 * Nomes que aparecerem como AMBIGUO ou SEM_USUARIO na prévia podem ser
 * resolvidos manualmente em overrides.json (copie overrides.example.json).
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
const OVERRIDES_PATH = path.join(__dirname, "overrides.json");

const SEND = process.argv.includes("--send");

function loadOverrides() {
  if (!fs.existsSync(OVERRIDES_PATH)) return {};
  const raw = JSON.parse(fs.readFileSync(OVERRIDES_PATH, "utf8"));
  delete raw._comment;
  return raw;
}

function norm(s) {
  return s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .trim();
}

function parseName(rawName) {
  const m = rawName.match(/^(.+?)\s*"(.+)"$/);
  if (m) return { base: m[1].trim(), nickname: m[2].trim() };
  return { base: rawName.trim(), nickname: null };
}

function isSubsequence(baseTokens, userTokens) {
  let i = 0;
  for (const t of userTokens) {
    if (t === baseTokens[i]) i++;
    if (i === baseTokens.length) return true;
  }
  return false;
}

async function main() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
    console.error("Defina FAXINA_SERVICE_ACCOUNT_PATH ou coloque o arquivo no caminho default.");
    process.exit(1);
  }

  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  function tenantCollection(name) {
    return db.collection("environments").doc(ENV).collection("tenants").doc(TENANT_ID).collection(name);
  }

  const MANUAL_USER_OVERRIDE = loadOverrides();

  const eventsSnap = await tenantCollection("events").get();
  const attendanceMap = new Map();

  eventsSnap.forEach((doc) => {
    const e = doc.data();
    const crew = e.cleaningCrew;
    if (!crew || crew.length === 0) return;
    const attendance = e.confirmedAttendance || [];
    for (const name of attendance) {
      if (crew.includes(name)) {
        attendanceMap.set(name, (attendanceMap.get(name) || 0) + 1);
      }
    }
  });

  // Desempate por nome usa comparação ordinal (por code unit), igual ao
  // String.compareTo do Dart em cleaning_dashboard_viewmodel.dart — não
  // localeCompare, que segue regras de idioma e pode ordenar diferente.
  function ordinalCompare(a, b) {
    return a < b ? -1 : a > b ? 1 : 0;
  }

  const ranking = Array.from(attendanceMap.entries())
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || ordinalCompare(a.name, b.name));

  console.log(`Modo: ${SEND ? "ENVIAR (vai disparar push de verdade)" : "PREVIEW (nada é enviado)"}`);
  console.log(`Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);
  console.log(`Total de pessoas no ranking (>=1 presença): ${ranking.length}`);
  console.log("---");

  const usersSnap = await tenantCollection("users").get();
  const allUsers = [];
  usersSnap.forEach((doc) => allUsers.push({ id: doc.id, ...doc.data() }));

  function candidatesFor(base) {
    const baseTokens = norm(base).split(/\s+/);
    return allUsers.filter((u) => {
      if (!u.name) return false;
      const userTokens = norm(u.name).split(/\s+/);
      if (baseTokens.length === 1) {
        return userTokens[0] === baseTokens[0];
      }
      if (userTokens[0] !== baseTokens[0]) return false;
      return isSubsequence(baseTokens, userTokens);
    });
  }

  const notFound = [];
  const ambiguous = [];
  const noToken = [];
  const toSend = [];
  const statusByName = new Map();

  ranking.forEach((entry, idx) => {
    const position = idx + 1;

    if (MANUAL_USER_OVERRIDE[entry.name]) {
      const user = allUsers.find((u) => u.id === MANUAL_USER_OVERRIDE[entry.name]);
      if (user && user.fcmTokens && user.fcmTokens.length > 0) {
        toSend.push({ ...entry, position, userId: user.id, userName: user.name, tokens: user.fcmTokens });
        statusByName.set(entry.name, "OK");
      } else if (user) {
        noToken.push({ ...entry, position, userId: user.id });
        statusByName.set(entry.name, "SEM_TOKEN");
      } else {
        notFound.push({ ...entry, position });
        statusByName.set(entry.name, "SEM_USUARIO");
      }
      return;
    }

    const { base, nickname } = parseName(entry.name);
    let candidates = candidatesFor(base);

    if (candidates.length > 1 && nickname) {
      const byNickname = candidates.filter((u) => norm(u.name).includes(norm(nickname)));
      if (byNickname.length === 1) candidates = byNickname;
    }

    if (candidates.length === 0) {
      notFound.push({ ...entry, position });
      statusByName.set(entry.name, "SEM_USUARIO");
      return;
    }
    if (candidates.length > 1) {
      ambiguous.push({ ...entry, position, candidates: candidates.map((c) => `${c.name} (${c.id})`) });
      statusByName.set(entry.name, "AMBIGUO");
      return;
    }
    const user = candidates[0];
    if (!user.fcmTokens || user.fcmTokens.length === 0) {
      noToken.push({ ...entry, position, userId: user.id });
      statusByName.set(entry.name, "SEM_TOKEN");
      return;
    }
    toSend.push({ ...entry, position, userId: user.id, userName: user.name, tokens: user.fcmTokens });
    statusByName.set(entry.name, "OK");
  });

  ranking.forEach((entry, idx) => {
    const position = idx + 1;
    const status = statusByName.get(entry.name);
    const extra = status === "OK" ? ` -> ${toSend.find((s) => s.name === entry.name).userName}` : "";
    console.log(`${String(position).padStart(3)}º | ${entry.count.toString().padStart(3)} presenças | ${status.padEnd(12)} | ${entry.name}${extra}`);
  });

  console.log("---");
  console.log(`Vão receber push (match único e com token): ${toSend.length}`);
  console.log(`Sem usuário correspondente no app: ${notFound.length} -> ${notFound.map((n) => n.name).join(", ") || "-"}`);
  console.log("AMBÍGUOS (mais de um usuário candidato, resolva em overrides.json):");
  ambiguous.forEach((a) => console.log(`   - ${a.name} (posição ${a.position}) -> ${a.candidates.join(" | ")}`));
  console.log(`Usuário encontrado mas sem token FCM: ${noToken.length} -> ${noToken.map((n) => n.name).join(", ") || "-"}`);

  if (!SEND) {
    console.log("\nPreview apenas. Rode com --send para disparar de verdade.");
    return;
  }

  console.log("\nEnviando...");
  let queued = 0;
  for (const entry of toSend) {
    const title = "🏆 Ranking de Faxina";
    const body = `Olá ${entry.name}! Você está na posição ${entry.position}º do ranking de faxina, com ${entry.count} presença${entry.count === 1 ? "" : "s"} confirmada${entry.count === 1 ? "" : "s"}.`;
    await db.collection("notifications_queue").add({
      tokens: entry.tokens,
      title,
      body,
      data: { type: "cleaning_ranking", position: String(entry.position), count: String(entry.count) },
      tenantId: TENANT_ID,
      env: ENV,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    queued++;
  }
  console.log(`Notificações enfileiradas: ${queued}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Erro:", err);
    process.exit(1);
  });
