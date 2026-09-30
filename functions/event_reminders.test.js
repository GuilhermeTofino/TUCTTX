// Teste simples sem framework: `node functions/event_reminders.test.js`
const assert = require("node:assert");
const { saoPauloDayWindow, formatTimeSaoPaulo, buildReminderPush, reminderTokens, chunk } = require("./event_reminders");

// --- janelas do dia em São Paulo (UTC-3)
// 07:00 em São Paulo de 29/09/2026 = 10:00 UTC
let w = saoPauloDayWindow(new Date("2026-09-29T10:00:00Z"), 0);
assert.strictEqual(w.key, "2026-09-29");
assert.strictEqual(w.start.toISOString(), "2026-09-29T03:00:00.000Z");
assert.strictEqual(w.end.toISOString(), "2026-09-30T03:00:00.000Z");
w = saoPauloDayWindow(new Date("2026-09-29T10:00:00Z"), 1);
assert.strictEqual(w.key, "2026-09-30");
assert.strictEqual(w.start.toISOString(), "2026-09-30T03:00:00.000Z");

// 23:30 em SP de 29/09 = 02:30 UTC de 30/09: o "dia" ainda é 29 (o servidor em UTC erraria)
w = saoPauloDayWindow(new Date("2026-09-30T02:30:00Z"), 0);
assert.strictEqual(w.key, "2026-09-29");
// 00:30 em SP de 30/09 = 03:30 UTC
assert.strictEqual(saoPauloDayWindow(new Date("2026-09-30T03:30:00Z"), 0).key, "2026-09-30");
// virada de mês e de ano
assert.strictEqual(saoPauloDayWindow(new Date("2026-09-30T10:00:00Z"), 1).key, "2026-10-01");
assert.strictEqual(saoPauloDayWindow(new Date("2026-12-31T10:00:00Z"), 1).key, "2027-01-01");
assert.strictEqual(saoPauloDayWindow(new Date("2028-02-28T10:00:00Z"), 1).key, "2028-02-29"); // bissexto

// um evento às 19:00 de SP (22:00 UTC) cai dentro da janela do dia
const evt = new Date("2026-09-29T22:00:00Z");
w = saoPauloDayWindow(new Date("2026-09-29T10:00:00Z"), 0);
assert.ok(evt >= w.start && evt < w.end);
// um evento à 00:30 de SP do dia seguinte (03:30 UTC) NÃO cai no dia de hoje
assert.ok(!(new Date("2026-09-30T03:30:00Z") >= w.start && new Date("2026-09-30T03:30:00Z") < w.end));

// --- hora local
assert.strictEqual(formatTimeSaoPaulo(new Date("2026-09-29T22:00:00Z")), "19:00");
assert.strictEqual(formatTimeSaoPaulo(new Date("2026-09-29T02:05:00Z")), "23:05"); // dia anterior em SP

// --- mensagens
const event = { title: "Gira de Caboclo", description: "Trazer branco", date: { toDate: () => new Date("2026-09-29T22:00:00Z") } };
let push = buildReminderPush({ type: "lembrete_vespera", event, eventId: "e1" });
assert.strictEqual(push.body, "Amanhã tem Gira de Caboclo: Trazer branco. Se prepare!");
assert.deepStrictEqual(push.data, { type: "lembrete_vespera", eventId: "e1", category: "event" });
push = buildReminderPush({ type: "lembrete_dia", event, eventId: "e1" });
assert.strictEqual(push.body, "Hoje tem Gira de Caboclo às 19:00: Trazer branco");
push = buildReminderPush({ type: "lembrete_dia", event: { date: event.date }, eventId: "e2" });
assert.strictEqual(push.body, "Hoje tem Evento às 19:00"); // sem título/descrição
for (const v of Object.values(push.data)) assert.strictEqual(typeof v, "string"); // FCM exige strings

// --- destinatários
const users = [
    { role: "admin", fcmTokens: ["a", "b"] },
    { role: "user", fcmTokens: ["b", "c"] },
    { role: "visitor", fcmTokens: ["v"] },
    { role: "user" },
    { role: "user", fcmTokens: "quebrado" },
];
assert.deepStrictEqual(reminderTokens(users, {}).sort(), ["a", "b", "c"]);
assert.deepStrictEqual(reminderTokens(users, { audience: ["visitor"] }).sort(), ["a", "b", "c", "v"]);
assert.deepStrictEqual(reminderTokens(users, { audience: ["user"] }).sort(), ["a", "b", "c"]);
assert.deepStrictEqual(reminderTokens([], {}), []);

// --- blocos
assert.deepStrictEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
assert.deepStrictEqual(chunk([], 500), []);

console.log("event_reminders: ok");
