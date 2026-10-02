// Teste simples sem framework: `node functions/fee_reminders.test.js`
const assert = require("node:assert");
const { daysUntilDue, classifyFee, buildFeePush } = require("./fee_reminders");

const fee = (month, year, status) => ({ month, year, status });
const day = (y, m, d) => ({ y, m, d });

// --- dias até o vencimento (dia 10)
assert.strictEqual(daysUntilDue(fee(10, 2026), day(2026, 10, 7)), 3);
assert.strictEqual(daysUntilDue(fee(10, 2026), day(2026, 10, 10)), 0);
assert.strictEqual(daysUntilDue(fee(10, 2026), day(2026, 10, 11)), -1);
assert.strictEqual(daysUntilDue(fee(12, 2026), day(2027, 1, 1)), -22); // virada de ano

// --- pendente
assert.strictEqual(classifyFee(fee(10, 2026, "pending"), day(2026, 10, 7)), "pre_due");
assert.strictEqual(classifyFee(fee(10, 2026, "pending"), day(2026, 10, 10)), "due_today");
assert.strictEqual(classifyFee(fee(10, 2026, "pending"), day(2026, 10, 11)), "overdue_new");
assert.strictEqual(classifyFee(fee(10, 2026, "pending"), day(2026, 10, 8)), null);
assert.strictEqual(classifyFee(fee(11, 2026, "pending"), day(2026, 10, 15)), null); // mês futuro

// --- paga nunca avisa
assert.strictEqual(classifyFee(fee(10, 2026, "paid"), day(2026, 10, 7)), null);
assert.strictEqual(classifyFee(fee(9, 2026, "paid"), day(2026, 10, 20)), null);

// --- atraso repetido a cada 7 dias
const last = new Date(Date.UTC(2026, 9, 11));
assert.strictEqual(classifyFee(fee(10, 2026, "late"), day(2026, 10, 17), last), null);
assert.strictEqual(classifyFee(fee(10, 2026, "late"), day(2026, 10, 18), last), "overdue_again");
assert.strictEqual(classifyFee(fee(10, 2026, "late"), day(2026, 10, 18)), "overdue_again"); // sem registro

// --- textos
const pre = buildFeePush({ kind: "pre_due", fees: [fee(10, 2026)], firstName: "Ana" });
assert.match(pre.body, /outubro\/2026 vence em 3 dias \(dia 10\)/);
assert.strictEqual(pre.data.category, "fee");
assert.match(buildFeePush({ kind: "due_today", fees: [fee(3, 2026)], firstName: "Ana" }).body, /março\/2026 vence hoje/);
assert.match(buildFeePush({ kind: "overdue", fees: [fee(9, 2026)], firstName: "Ana" }).body, /setembro\/2026 está em atraso/);
assert.match(buildFeePush({ kind: "overdue", fees: [fee(8, 2026), fee(9, 2026)], firstName: "Ana" }).body, /2 mensalidades.*agosto\/2026, setembro\/2026/);

console.log("fee_reminders: ok");
