// Testes de firestore.rules contra o emulador. Veja README.md para rodar.
const { test, before, after, beforeEach, describe } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection,
} = require("firebase/firestore");

const TENANT = "environments/dev/tenants/tucttx";
let env;

// Quem existe no "banco" (perfil já gravado em users/{uid}).
const USERS = {
  ADMIN: { role: "admin", status: "active", skills: [], name: "Admin" },
  MEMBRO: { role: "user", status: "active", skills: [], name: "Membro" },
  LEGADO: { role: "user", name: "Usuario antigo" }, // doc antigo, sem status/skills
  VISIT: { role: "visitor", status: "active", skills: [], name: "Visitante" },
  VISIT_PEND: { role: "visitor", status: "pending_approval", skills: [], name: "Pendente" },
  S_FIN: { role: "user", status: "active", skills: ["financeiro.gerenciar"], name: "Fin" },
  S_BAZ: { role: "user", status: "active", skills: ["bazar.gerenciar"], name: "Baz" },
  S_MURAL: { role: "user", status: "active", skills: ["mural.publicar"], name: "Mural" },
  S_CAL: { role: "user", status: "active", skills: ["calendario.gerenciar"], name: "Cal" },
  S_LIMP: { role: "user", status: "active", skills: ["limpeza.gerenciar"], name: "Limp" },
  S_ENT: { role: "user", status: "active", skills: ["entidades.moderar"], name: "Ent" },
  S_NOTIF: { role: "user", status: "active", skills: ["notificacoes.enviar"], name: "Notif" },
  S_EST: { role: "user", status: "active", skills: ["estudos.gerenciar"], name: "Est" },
  // visitante com skill "no papel" não pode valer (skill só vale para role 'user')
  VISIT_SKILL: { role: "visitor", status: "active", skills: ["mural.publicar"], name: "VisitSkill" },
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-tucttx",
    firestore: {
      rules: fs.readFileSync(process.env.RULES_PATH || path.join(__dirname, "..", "firestore.rules"), "utf8"),
    },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, data] of Object.entries(USERS)) {
      await setDoc(doc(db, `${TENANT}/users/${uid}`), data);
    }
    await setDoc(doc(db, `${TENANT}/settings/finance`), { approverIds: ["ADMIN"] });
    await setDoc(doc(db, `${TENANT}/events/E1`), { title: "Gira", cleaningCrew: [], confirmedAttendance: [] });
    await setDoc(doc(db, `${TENANT}/announcements/A1`), { title: "Aviso" });
    await setDoc(doc(db, `${TENANT}/studies/S1`), { title: "Apostila" });
    await setDoc(doc(db, `${TENANT}/financial/MEMBRO/monthly_fees/2026_9`), { status: "pending", value: 100 });
    await setDoc(doc(db, `${TENANT}/financial/S_FIN/monthly_fees/2026_9`), { status: "pending", value: 100 });
    await setDoc(doc(db, `${TENANT}/financial/MEMBRO/bazaar_debts/D1`), { value: 10 });
    await setDoc(doc(db, `${TENANT}/users/MEMBRO/private/health`), { alergias: "amendoim" });
    await setDoc(doc(db, `${TENANT}/audit_log/L1`), { actorId: "ADMIN", targetUserId: "MEMBRO", undone: false, action: "role_change" });
    await setDoc(doc(db, `${TENANT}/payment_requests/R_OUTRO`), { userId: "MEMBRO", status: "pending_approval" });
    await setDoc(doc(db, `${TENANT}/payment_requests/R_ADMIN`), { userId: "ADMIN", status: "pending_approval" });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const ref = (db, p) => doc(db, `${TENANT}/${p}`);

describe("users: cadastro", () => {
  const visitor = { role: "visitor", status: "active", skills: [], name: "N" };
  const legacy = { role: "user", name: "N" }; // app antigo nas lojas

  test("visitante ativo sem skills (app novo)", () => assertSucceeds(setDoc(ref(as("NOVO"), "users/NOVO"), visitor)));
  test("role 'user' sem status/skills (app antigo)", () => assertSucceeds(setDoc(ref(as("NOVO"), "users/NOVO"), legacy)));
  test("se autopromover a admin", () => assertFails(setDoc(ref(as("NOVO"), "users/NOVO"), { ...legacy, role: "admin" })));
  test("visitante já com skills", () => assertFails(setDoc(ref(as("NOVO"), "users/NOVO"), { ...visitor, skills: ["financeiro.gerenciar"] })));
  test("'user' já com skills", () => assertFails(setDoc(ref(as("NOVO"), "users/NOVO"), { ...legacy, skills: ["financeiro.gerenciar"] })));
  test("visitante já em pending_approval", () => assertFails(setDoc(ref(as("NOVO"), "users/NOVO"), { ...visitor, status: "pending_approval" })));
  test("criar o perfil de OUTRA pessoa", () => assertFails(setDoc(ref(as("NOVO"), "users/OUTRO"), legacy)));
  test("sem login", () => assertFails(setDoc(ref(anon(), "users/NOVO"), legacy)));
});

describe("users: edição do próprio perfil", () => {
  test("usuário ANTIGO (doc sem skills/status) edita dados pessoais", () =>
    assertSucceeds(updateDoc(ref(as("LEGADO"), "users/LEGADO"), { name: "Novo", endereco: "Rua", skills: [], status: "active" })));
  test("edita só campos pessoais", () => assertSucceeds(updateDoc(ref(as("MEMBRO"), "users/MEMBRO"), { phone: "1", endereco: "Rua" })));
  test("registra token de push (fcmTokens)", () => assertSucceeds(updateDoc(ref(as("MEMBRO"), "users/MEMBRO"), { fcmTokens: ["t1"] })));
  test("se autopromover a admin", () => assertFails(updateDoc(ref(as("MEMBRO"), "users/MEMBRO"), { role: "admin" })));
  test("visitante vira 'user' sozinho", () => assertFails(updateDoc(ref(as("VISIT"), "users/VISIT"), { role: "user" })));
  test("se conceder skills", () => assertFails(updateDoc(ref(as("MEMBRO"), "users/MEMBRO"), { skills: ["financeiro.gerenciar"] })));
  test("editar perfil de OUTRA pessoa", () => assertFails(updateDoc(ref(as("MEMBRO"), "users/VISIT"), { name: "Hack" })));
  test("visitante pede aprovação (active -> pending_approval)", () =>
    assertSucceeds(updateDoc(ref(as("VISIT"), "users/VISIT"), { status: "pending_approval" })));
  test("visitante pendente se aprova sozinho (-> active)", () => assertFails(updateDoc(ref(as("VISIT_PEND"), "users/VISIT_PEND"), { status: "active" })));
  test("visitante pede aprovação mas já muda o papel", () =>
    assertFails(updateDoc(ref(as("VISIT"), "users/VISIT"), { status: "pending_approval", role: "user" })));
  test("visitante pede aprovação e já se dá skills", () =>
    assertFails(updateDoc(ref(as("VISIT"), "users/VISIT"), { status: "pending_approval", skills: ["mural.publicar"] })));
  test("membro (não visitante) tenta ir para pending_approval", () =>
    assertFails(updateDoc(ref(as("MEMBRO"), "users/MEMBRO"), { status: "pending_approval" })));
  test("sem login", () => assertFails(updateDoc(ref(anon(), "users/MEMBRO"), { name: "x" })));
});

describe("users: admin e moderação", () => {
  test("admin promove membro a admin", () => assertSucceeds(updateDoc(ref(as("ADMIN"), "users/MEMBRO"), { role: "admin" })));
  test("admin concede skills", () => assertSucceeds(updateDoc(ref(as("ADMIN"), "users/MEMBRO"), { skills: ["estudos.gerenciar"] })));
  test("admin aprova visitante pendente", () =>
    assertSucceeds(updateDoc(ref(as("ADMIN"), "users/VISIT_PEND"), { role: "user", status: "active" })));
  test("quem modera entidades altera SÓ 'entities' de outro", () =>
    assertSucceeds(updateDoc(ref(as("S_ENT"), "users/MEMBRO"), { entities: [] })));
  test("moderador de entidades NÃO altera outros campos", () =>
    assertFails(updateDoc(ref(as("S_ENT"), "users/MEMBRO"), { name: "Hack" })));
  test("moderador de entidades NÃO mexe em role", () => assertFails(updateDoc(ref(as("S_ENT"), "users/MEMBRO"), { role: "admin" })));
  test("membro sem a skill não altera 'entities' de outro", () => assertFails(updateDoc(ref(as("MEMBRO"), "users/S_ENT"), { entities: [] })));
  test("leitura por autenticado", () => assertSucceeds(getDoc(ref(as("VISIT"), "users/MEMBRO"))));
  test("leitura sem login", () => assertFails(getDoc(ref(anon(), "users/MEMBRO"))));
});

describe("users/private (saúde)", () => {
  test("dono lê", () => assertSucceeds(getDoc(ref(as("MEMBRO"), "users/MEMBRO/private/health"))));
  test("dono grava", () => assertSucceeds(setDoc(ref(as("MEMBRO"), "users/MEMBRO/private/health"), { alergias: "x" })));
  test("visitante grava o próprio", () => assertSucceeds(setDoc(ref(as("VISIT"), "users/VISIT/private/health"), { alergias: "x" })));
  test("outro membro NÃO lê", () => assertFails(getDoc(ref(as("S_FIN"), "users/MEMBRO/private/health"))));
  test("outro membro NÃO grava", () => assertFails(setDoc(ref(as("S_FIN"), "users/MEMBRO/private/health"), { alergias: "x" })));
  test("admin lê", () => assertSucceeds(getDoc(ref(as("ADMIN"), "users/MEMBRO/private/health"))));
  test("admin NÃO grava", () => assertFails(setDoc(ref(as("ADMIN"), "users/MEMBRO/private/health"), { alergias: "x" })));
  test("sem login", () => assertFails(getDoc(ref(anon(), "users/MEMBRO/private/health"))));
});

describe("audit_log e skills_catalog", () => {
  const log = { actorId: "ADMIN", targetUserId: "MEMBRO", action: "role_change", before: {}, after: {}, undone: false };
  test("admin cria log com seu próprio actorId", () => assertSucceeds(setDoc(ref(as("ADMIN"), "audit_log/L2"), log)));
  test("admin NÃO cria log em nome de outro", () => assertFails(setDoc(ref(as("ADMIN"), "audit_log/L2"), { ...log, actorId: "S_FIN" })));
  test("membro NÃO cria log", () => assertFails(setDoc(ref(as("MEMBRO"), "audit_log/L2"), { ...log, actorId: "MEMBRO" })));
  test("admin marca undone", () => assertSucceeds(updateDoc(ref(as("ADMIN"), "audit_log/L1"), { undone: true })));
  test("admin NÃO altera o conteúdo do log", () => assertFails(updateDoc(ref(as("ADMIN"), "audit_log/L1"), { after: { role: "x" } })));
  test("ninguém apaga log", () => assertFails(deleteDoc(ref(as("ADMIN"), "audit_log/L1"))));
  test("admin lê", () => assertSucceeds(getDoc(ref(as("ADMIN"), "audit_log/L1"))));
  test("membro NÃO lê", () => assertFails(getDoc(ref(as("MEMBRO"), "audit_log/L1"))));
  test("catálogo: admin lê e grava", async () => {
    await assertSucceeds(setDoc(ref(as("ADMIN"), "skills_catalog/x"), { label: "X" }));
    await assertSucceeds(getDoc(ref(as("ADMIN"), "skills_catalog/x")));
  });
  test("catálogo: membro NÃO", () => assertFails(getDoc(ref(as("MEMBRO"), "skills_catalog/x"))));
});

describe("skills nas coleções", () => {
  test("mural: membro lê", () => assertSucceeds(getDoc(ref(as("MEMBRO"), "announcements/A1"))));
  test("mural: visitante NÃO lê", () => assertFails(getDoc(ref(as("VISIT"), "announcements/A1"))));
  test("mural: skill publica", () => assertSucceeds(setDoc(ref(as("S_MURAL"), "announcements/A2"), { title: "x" })));
  test("mural: admin publica", () => assertSucceeds(setDoc(ref(as("ADMIN"), "announcements/A2"), { title: "x" })));
  test("mural: membro sem skill NÃO publica", () => assertFails(setDoc(ref(as("MEMBRO"), "announcements/A2"), { title: "x" })));
  test("mural: skill de OUTRA área NÃO publica", () => assertFails(setDoc(ref(as("S_FIN"), "announcements/A2"), { title: "x" })));
  test("mural: visitante com skill escrita NÃO vale", () => assertFails(setDoc(ref(as("VISIT_SKILL"), "announcements/A2"), { title: "x" })));

  test("estudos: membro lê / visitante NÃO", async () => {
    await assertSucceeds(getDoc(ref(as("MEMBRO"), "studies/S1")));
    await assertFails(getDoc(ref(as("VISIT"), "studies/S1")));
  });
  test("estudos: skill grava", () => assertSucceeds(setDoc(ref(as("S_EST"), "studies/S2"), { title: "x" })));
  test("estudos: membro sem skill NÃO grava", () => assertFails(setDoc(ref(as("MEMBRO"), "studies/S2"), { title: "x" })));

  test("calendário: visitante lê", () => assertSucceeds(getDoc(ref(as("VISIT"), "events/E1"))));
  test("calendário: skill cria evento", () => assertSucceeds(setDoc(ref(as("S_CAL"), "events/E2"), { title: "x" })));
  test("calendário: membro sem skill NÃO cria", () => assertFails(setDoc(ref(as("MEMBRO"), "events/E2"), { title: "x" })));
  test("faxina: skill altera SÓ escala/presença", () =>
    assertSucceeds(updateDoc(ref(as("S_LIMP"), "events/E1"), { cleaningCrew: ["a"], confirmedAttendance: ["a"] })));
  test("faxina: skill NÃO altera o título", () => assertFails(updateDoc(ref(as("S_LIMP"), "events/E1"), { title: "x" })));
  test("faxina: skill NÃO cria evento", () => assertFails(setDoc(ref(as("S_LIMP"), "events/E9"), { title: "x" })));
  test("presença: membro confirma a própria", () => assertSucceeds(setDoc(ref(as("MEMBRO"), "events/E1/confirmations/MEMBRO"), { name: "m" })));
  test("presença: membro desmarca a própria", async () => {
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), `${TENANT}/events/E1/confirmations/MEMBRO`), { name: "m" }));
    await assertSucceeds(deleteDoc(ref(as("MEMBRO"), "events/E1/confirmations/MEMBRO")));
  });
  test("presença: visitante NÃO confirma", () => assertFails(setDoc(ref(as("VISIT"), "events/E1/confirmations/VISIT"), { name: "v" })));
  test("presença: confirmar por OUTRA pessoa", () => assertFails(setDoc(ref(as("MEMBRO"), "events/E1/confirmations/S_FIN"), { name: "m" })));

  test("cambone: skill de calendário grava", () => assertSucceeds(setDoc(ref(as("S_CAL"), "cambone_schedules/C1"), { x: 1 })));
  test("cambone: membro sem skill NÃO grava", () => assertFails(setDoc(ref(as("MEMBRO"), "cambone_schedules/C1"), { x: 1 })));
});

describe("financeiro (skills + regras que já existiam)", () => {
  test("membro lê a própria mensalidade", () => assertSucceeds(getDoc(ref(as("MEMBRO"), "financial/MEMBRO/monthly_fees/2026_9"))));
  test("membro NÃO lê a de outro", () => assertFails(getDoc(ref(as("MEMBRO"), "financial/S_FIN/monthly_fees/2026_9"))));
  test("membro NÃO grava a própria mensalidade", () => assertFails(updateDoc(ref(as("MEMBRO"), "financial/MEMBRO/monthly_fees/2026_9"), { status: "paid" })));
  test("skill financeira lê a de outro", () => assertSucceeds(getDoc(ref(as("S_FIN"), "financial/MEMBRO/monthly_fees/2026_9"))));
  test("skill financeira baixa mensalidade", () => assertSucceeds(updateDoc(ref(as("S_FIN"), "financial/MEMBRO/monthly_fees/2026_9"), { status: "paid" })));
  test("admin baixa mensalidade", () => assertSucceeds(updateDoc(ref(as("ADMIN"), "financial/MEMBRO/monthly_fees/2026_9"), { status: "paid" })));
  test("skill de bazar NÃO baixa mensalidade", () => assertFails(updateDoc(ref(as("S_BAZ"), "financial/MEMBRO/monthly_fees/2026_9"), { status: "paid" })));
  test("skill de bazar grava dívida de bazar", () => assertSucceeds(setDoc(ref(as("S_BAZ"), "financial/MEMBRO/bazaar_debts/D2"), { value: 5 })));
  test("skill financeira NÃO grava dívida de bazar", () => assertFails(setDoc(ref(as("S_FIN"), "financial/MEMBRO/bazaar_debts/D2"), { value: 5 })));
  test("skill financeira lê dívida de bazar", () => assertSucceeds(getDoc(ref(as("S_FIN"), "financial/MEMBRO/bazaar_debts/D1"))));
  test("metas: skill financeira", () => assertSucceeds(setDoc(ref(as("S_FIN"), "financial_goals/annual_2026"), { targetValue: 1 })));
  test("metas: membro NÃO", () => assertFails(getDoc(ref(as("MEMBRO"), "financial_goals/annual_2026"))));
});

describe("comprovantes e aprovadores (feature PIX)", () => {
  test("membro cria o próprio como pending_approval", () =>
    assertSucceeds(setDoc(ref(as("MEMBRO"), "payment_requests/R1"), { userId: "MEMBRO", status: "pending_approval" })));
  test("membro cria já como approved", () =>
    assertFails(setDoc(ref(as("MEMBRO"), "payment_requests/R1"), { userId: "MEMBRO", status: "approved" })));
  test("visitante NÃO envia comprovante", () =>
    assertFails(setDoc(ref(as("VISIT"), "payment_requests/R1"), { userId: "VISIT", status: "pending_approval" })));
  test("membro NÃO cria em nome de outro", () =>
    assertFails(setDoc(ref(as("MEMBRO"), "payment_requests/R1"), { userId: "S_FIN", status: "pending_approval" })));
  test("aprovador decide o de outro", () =>
    assertSucceeds(updateDoc(ref(as("ADMIN"), "payment_requests/R_OUTRO"), { status: "approved" })));
  test("aprovador NÃO decide o próprio", () =>
    assertFails(updateDoc(ref(as("ADMIN"), "payment_requests/R_ADMIN"), { status: "approved" })));
  test("skill financeira que não é aprovador NÃO decide", () =>
    assertFails(updateDoc(ref(as("S_FIN"), "payment_requests/R_OUTRO"), { status: "approved" })));
  test("dono lê o próprio", () => assertSucceeds(getDoc(ref(as("MEMBRO"), "payment_requests/R_OUTRO"))));
  test("outro membro NÃO lê", () => assertFails(getDoc(ref(as("S_FIN"), "payment_requests/R_OUTRO"))));
  test("settings: membro NÃO escreve a lista de aprovadores", () =>
    assertFails(updateDoc(ref(as("MEMBRO"), "settings/finance"), { approverIds: ["MEMBRO"] })));
  test("settings: admin escreve", () => assertSucceeds(updateDoc(ref(as("ADMIN"), "settings/finance"), { approverIds: ["ADMIN", "X"] })));
});

describe("notifications_queue", () => {
  const push = { tenantId: "tucttx", env: "dev", title: "t", body: "b", status: "pending" };
  const q = (db) => addDoc(collection(db, "notifications_queue"), push);
  test("admin enfileira", () => assertSucceeds(q(as("ADMIN"))));
  test("skill 'notificacoes.enviar' enfileira", () => assertSucceeds(q(as("S_NOTIF"))));
  test("membro sem a skill NÃO", () => assertFails(q(as("MEMBRO"))));
  test("skill de outra área NÃO", () => assertFails(q(as("S_MURAL"))));
  test("visitante NÃO", () => assertFails(q(as("VISIT"))));
  test("ninguém lê a fila", async () => {
    let id;
    await env.withSecurityRulesDisabled(async (c) => { id = (await addDoc(collection(c.firestore(), "notifications_queue"), push)).id; });
    await assertFails(getDoc(doc(as("ADMIN"), `notifications_queue/${id}`)));
  });
});
