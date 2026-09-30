/**
 * Cria contas e dados de teste no EMULADOR local do Firebase (Auth + Firestore).
 * Nunca toca produção: fixa os hosts do emulador e não usa credencial nenhuma,
 * então mesmo um erro de digitação não alcança o projeto real.
 *
 * Uso (com o emulador rodando, ver scripts/emulator/README.md):
 *   node scripts/emulator/seed.js
 *
 * Contas (senha de todas: teste123):
 *   admin@teste.dev       Ana Admin        admin  (aprovadora do financeiro)
 *   admin2@teste.dev      Bruno Admin      admin  (aprovador do financeiro)
 *   membro@teste.dev      Carla Membro     membro, sem permissões, com mensalidades e dados de saúde
 *   mural@teste.dev       Diego Mural      membro com a skill "publicar no mural"
 *   visitante@teste.dev   Elisa Visitante  visitante ativo
 *   pendente@teste.dev    Fabio Pendente   visitante que já pediu acesso
 */

// Fixa o emulador ANTES de carregar o admin SDK.
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.GCLOUD_PROJECT = "tenda-white-label";

const admin = require("../admin/node_modules/firebase-admin");
admin.initializeApp({ projectId: "tenda-white-label" }); // sem credencial: só emulador

const PASSWORD = "teste123";
const TENANT = "environments/dev/tenants/tucttx";

const ACCOUNTS = [
    { uid: "seed-admin", email: "admin@teste.dev", name: "Ana Admin", role: "admin" },
    { uid: "seed-admin2", email: "admin2@teste.dev", name: "Bruno Admin", role: "admin" },
    { uid: "seed-membro", email: "membro@teste.dev", name: "Carla Membro", role: "user" },
    { uid: "seed-mural", email: "mural@teste.dev", name: "Diego Mural", role: "user", skills: ["mural.publicar"] },
    { uid: "seed-visitante", email: "visitante@teste.dev", name: "Elisa Visitante", role: "visitor" },
    { uid: "seed-pendente", email: "pendente@teste.dev", name: "Fabio Pendente", role: "visitor", status: "pending_approval" },
];

/** Daqui a [days] dias às [hour]:00 de São Paulo (UTC-3), como Timestamp. */
function spDate(days, hour) {
    const now = new Date(Date.now() - 3 * 3600 * 1000);
    const ms = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + days, hour + 3, 0, 0);
    return admin.firestore.Timestamp.fromMillis(ms);
}

async function main() {
    const auth = admin.auth();
    const db = admin.firestore();

    for (const a of ACCOUNTS) {
        try {
            await auth.createUser({ uid: a.uid, email: a.email, password: PASSWORD, displayName: a.name });
        } catch (error) {
            if (error.code !== "auth/uid-already-exists" && error.code !== "auth/email-already-exists") throw error;
        }
        await db.doc(`${TENANT}/users/${a.uid}`).set({
            id: a.uid,
            name: a.name,
            email: a.email,
            phone: "11988887777",
            emergencyContact: "11977776666",
            tenantSlug: "tucttx",
            createdAt: new Date().toISOString(),
            role: a.role,
            status: a.status || "active",
            skills: a.skills || [],
            jaTirouSanto: a.role !== "visitor",
            jogoComTata: false,
            fcmTokens: null,
        });
    }

    // Saúde só na subcoleção privada (nunca no documento aberto).
    await db.doc(`${TENANT}/users/seed-membro/private/health`).set({
        alergias: "Amendoim", medicamentos: null, condicoesMedicas: null, tipoSanguineo: "O+",
    });

    // Quem aprova comprovantes.
    await db.doc(`${TENANT}/settings/finance`).set({ approverIds: ["seed-admin", "seed-admin2"] });

    // Atalhos da Home (como em produção: só o Calendário é aberto a visitantes).
    const menus = [
        { id: "calendario", title: "Calendário", icon: "calendar_today_outlined", color: "primary", action: "route:/calendar", order: 1 },
        { id: "financeiro", title: "Financeiro", icon: "payments_outlined", color: "green", action: "internal:finance", order: 2 },
        { id: "estudos", title: "Estudos", icon: "menu_book_outlined", color: "blue", action: "internal:studies", order: 3 },
        { id: "cambones", title: "Cambones", icon: "people", color: "orange", action: "route:/cambone-list", order: 4 },
    ];
    for (const { id, ...m } of menus) await db.doc(`${TENANT}/menus/${id}`).set({ ...m, isEnabled: true });

    // Eventos: passado, hoje e amanhã (para os lembretes).
    await db.doc(`${TENANT}/events/evento-passado`).set({ title: "Gira passada", date: spDate(-7, 19), description: "Já aconteceu", type: "Gira", cleaningCrew: [], confirmedAttendance: [] });
    await db.doc(`${TENANT}/events/evento-hoje`).set({ title: "Gira de hoje", date: spDate(0, 19), description: "Trazer branco", type: "Gira", cleaningCrew: [], confirmedAttendance: [] });
    await db.doc(`${TENANT}/events/evento-amanha`).set({ title: "Gira de amanhã", date: spDate(1, 19), description: "Roupa branca", type: "Gira", cleaningCrew: [], confirmedAttendance: [] });

    // Mural (para membros; visitante não lê).
    await db.doc(`${TENANT}/announcements/aviso-1`).set({
        title: "Bem-vindos ao ambiente de teste", body: "Este aviso só existe no emulador.",
        createdAt: admin.firestore.Timestamp.now(), authorId: "seed-admin", authorName: "Ana Admin",
    });

    // Mensalidades da Carla (12 meses do ano corrente, pendentes).
    const year = new Date().getFullYear();
    for (let m = 1; m <= 12; m++) {
        await db.doc(`${TENANT}/financial/seed-membro/monthly_fees/${year}_${m}`).set({
            userId: "seed-membro", month: m, year, value: 100, status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log("Emulador populado. Contas (senha: %s):", PASSWORD);
    for (const a of ACCOUNTS) console.log(`  ${a.email.padEnd(22)} ${a.name.padEnd(16)} ${a.role}${a.status ? " · " + a.status : ""}${a.skills ? " · " + a.skills.join(",") : ""}`);
}

main().then(() => process.exit(0)).catch((error) => { console.error("Erro no seed:", error.message); process.exit(1); });
