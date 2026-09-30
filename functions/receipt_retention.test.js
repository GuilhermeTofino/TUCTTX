// Teste simples sem framework: `node functions/receipt_retention.test.js`
const assert = require("node:assert");
const { receiptYearFromPath, isExpiredReceipt } = require("./receipt_retention");

const base = "environments/prod/tenants/tucttx/receipts";

assert.strictEqual(receiptYearFromPath(`${base}/2026/u1/r1`), 2026);
assert.strictEqual(receiptYearFromPath(`${base}/2026/`), 2026);
assert.strictEqual(receiptYearFromPath("environments/prod/tenants/tucttx/profiles/u1"), null);
assert.strictEqual(receiptYearFromPath("environments/prod/tenants/tucttx/studies/apostila/a.pdf"), null);
assert.strictEqual(receiptYearFromPath(`${base}/abcd/u1/r1`), null);

// Ano anterior e mais antigos expiram; o ano corrente nunca.
assert.strictEqual(isExpiredReceipt(`${base}/2026/u1/r1`, 2027), true);
assert.strictEqual(isExpiredReceipt(`${base}/2024/u1/r1`, 2027), true);
assert.strictEqual(isExpiredReceipt(`${base}/2027/u1/r1`, 2027), false);
assert.strictEqual(isExpiredReceipt(`${base}/2028/u1/r1`, 2027), false);

// Nunca apaga o que não é comprovante, mesmo com "ano" antigo no nome.
assert.strictEqual(isExpiredReceipt("environments/prod/tenants/tucttx/studies/2020/a.pdf", 2027), false);
assert.strictEqual(isExpiredReceipt("environments/prod/tenants/tucttx/profiles/u1", 2027), false);

console.log("receipt_retention: ok");
