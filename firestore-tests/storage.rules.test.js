// Testes de storage.rules (com leitura cruzada do Firestore). Veja README.md.
const { test, before, after, beforeEach, describe } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const { initializeTestEnvironment, assertSucceeds, assertFails } = require("@firebase/rules-unit-testing");
const { doc, setDoc } = require("firebase/firestore");
const { ref, uploadBytes, getBytes, deleteObject } = require("firebase/storage");

const TENANT = "environments/dev/tenants/tucttx";
const USERS = {
  ADMIN: { role: "admin", skills: [] },
  MEMBRO: { role: "user", skills: [] },
  APROV: { role: "admin", skills: [] },
  S_EST: { role: "user", skills: ["estudos.gerenciar"] },
  VISIT: { role: "visitor", skills: [] },
  OUTRO: { role: "user", skills: [] },
};
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-tucttx",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8") },
    storage: { rules: fs.readFileSync(process.env.STORAGE_RULES_PATH || path.join(__dirname, "..", "storage.rules"), "utf8") },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, data] of Object.entries(USERS)) await setDoc(doc(db, `${TENANT}/users/${uid}`), data);
    await setDoc(doc(db, `${TENANT}/settings/finance`), { approverIds: ["APROV"] });
  });
});

const st = (uid) => env.authenticatedContext(uid).storage();
const anon = () => env.unauthenticatedContext().storage();
const bytes = (n) => new Uint8Array(n).fill(1);
const R = (p) => `${TENANT}/${p}`;

async function seed(p, contentType = "image/png") {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), R(p)), bytes(10), { contentType });
  });
}

let seq = 0;
describe("comprovantes: receipts/{ano}/{userId}/{requestId}", () => {
  let own;
  beforeEach(() => { own = `receipts/2026/MEMBRO/r${++seq}`; });
  test("dono envia imagem", () => assertSucceeds(uploadBytes(ref(st("MEMBRO"), R(own)), bytes(100), { contentType: "image/png" })));
  test("dono envia PDF", () => assertSucceeds(uploadBytes(ref(st("MEMBRO"), R(own)), bytes(100), { contentType: "application/pdf" })));
  test("tipo não permitido (zip)", () => assertFails(uploadBytes(ref(st("MEMBRO"), R(own)), bytes(100), { contentType: "application/zip" })));
  test("arquivo maior que 5 MB", () => assertFails(uploadBytes(ref(st("MEMBRO"), R(own)), bytes(5 * 1024 * 1024 + 1), { contentType: "image/png" })));
  test("enviar na pasta de OUTRA pessoa", () => assertFails(uploadBytes(ref(st("OUTRO"), R(own)), bytes(100), { contentType: "image/png" })));
  test("sem login", () => assertFails(uploadBytes(ref(anon(), R(own)), bytes(100), { contentType: "image/png" })));
  test("sobrescrever comprovante existente", async () => {
    await seed(own);
    await assertFails(uploadBytes(ref(st("MEMBRO"), R(own)), bytes(100), { contentType: "image/png" }));
  });
  test("dono lê", async () => { await seed(own); await assertSucceeds(getBytes(ref(st("MEMBRO"), R(own)))); });
  test("aprovador lê", async () => { await seed(own); await assertSucceeds(getBytes(ref(st("APROV"), R(own)))); });
  test("outro membro NÃO lê", async () => { await seed(own); await assertFails(getBytes(ref(st("OUTRO"), R(own)))); });
  test("admin que não é aprovador NÃO lê", async () => { await seed(own); await assertFails(getBytes(ref(st("ADMIN"), R(own)))); });
  test("dono NÃO apaga", async () => { await seed(own); await assertFails(deleteObject(ref(st("MEMBRO"), R(own)))); });
});

describe("estudos: studies/{topic}/{file}", () => {
  let f;
  beforeEach(() => { f = `studies/apostila/a${++seq}.pdf`; });
  test("membro lê", async () => { await seed(f, "application/pdf"); await assertSucceeds(getBytes(ref(st("MEMBRO"), R(f)))); });
  test("visitante NÃO lê", async () => { await seed(f, "application/pdf"); await assertFails(getBytes(ref(st("VISIT"), R(f)))); });
  test("sem login NÃO lê", async () => { await seed(f, "application/pdf"); await assertFails(getBytes(ref(anon(), R(f)))); });
  test("admin grava", () => assertSucceeds(uploadBytes(ref(st("ADMIN"), R(f)), bytes(10), { contentType: "application/pdf" })));
  test("skill estudos.gerenciar grava", () => assertSucceeds(uploadBytes(ref(st("S_EST"), R(f)), bytes(10), { contentType: "application/pdf" })));
  test("membro sem skill NÃO grava (antes qualquer logado gravava)", () => assertFails(uploadBytes(ref(st("MEMBRO"), R(f)), bytes(10), { contentType: "application/pdf" })));
  test("visitante NÃO grava", () => assertFails(uploadBytes(ref(st("VISIT"), R(f)), bytes(10), { contentType: "application/pdf" })));
});

describe("foto de perfil (regra que já existia)", () => {
  // a foto é sempre profiles/{uid}; o emulador não limpa entre testes, então
  // cada teste usa um uid próprio.
  test("dono grava a própria", () => assertSucceeds(uploadBytes(ref(st("MEMBRO"), R("profiles/MEMBRO")), bytes(10), { contentType: "image/png" })));
  test("grava a de OUTRO", () => assertFails(uploadBytes(ref(st("OUTRO"), R("profiles/MEMBRO")), bytes(10), { contentType: "image/png" })));
  test("qualquer logado lê", async () => { await seed("profiles/MEMBRO"); await assertSucceeds(getBytes(ref(st("VISIT"), R("profiles/MEMBRO")))); });
});
