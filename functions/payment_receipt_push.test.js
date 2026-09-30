// Teste simples sem framework: `node functions/payment_receipt_push.test.js`
const assert = require("node:assert");
const { buildPaymentReceiptPush, collectApproverTokens } = require("./payment_receipt_push");

const request = {
    userId: "u1",
    userName: "Fulano",
    items: [{ month: 9, year: 2026 }, { month: 10, year: 2026 }],
};

const push = buildPaymentReceiptPush({ request, requestId: "r1", tenantId: "tucttx", env: "prod" });
assert.match(push.body, /Fulano enviou comprovante de Setembro\/2026, Outubro\/2026/);
assert.strictEqual(push.data.type, "payment_receipt_pending");
assert.strictEqual(push.data.requestId, "r1");
for (const value of Object.values(push.data)) {
    assert.strictEqual(typeof value, "string", "FCM exige data com strings");
}

const usersById = {
    a1: { role: "admin", fcmTokens: ["t1", "t2"] },
    a2: { role: "admin", fcmTokens: ["t2", "t3"] },
    a3: { role: "user", fcmTokens: ["t4"] },
    a4: { role: "admin" },
    u1: { role: "admin", fcmTokens: ["self"] },
};

// Ignora o solicitante, quem não é admin, quem não tem token e ids inexistentes.
const tokens = collectApproverTokens({
    approverIds: ["a1", "a2", "a3", "a4", "u1", "ghost"],
    usersById,
    requesterId: "u1",
});
assert.deepStrictEqual(tokens.sort(), ["t1", "t2", "t3"]);

assert.deepStrictEqual(
    collectApproverTokens({ approverIds: [], usersById, requesterId: "u1" }),
    [],
);

console.log("payment_receipt_push: ok");
