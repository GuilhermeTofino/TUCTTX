// Teste sem framework: `node functions/feature_flags.test.js`
const assert = require("node:assert");
const { FEATURE_KEYS, isFeatureEnabled } = require("./feature_flags");

// nasce desligado
assert.strictEqual(isFeatureEnabled(undefined, "eventReminders"), false);
assert.strictEqual(isFeatureEnabled(null, "eventReminders"), false);
assert.strictEqual(isFeatureEnabled({}, "presenceRemovedPush"), false);
// só o booleano true liga (texto, número e afins não)
assert.strictEqual(isFeatureEnabled({ eventReminders: true }, "eventReminders"), true);
for (const v of ["true", 1, "1", "on", {}, [], 0, false, null]) {
    assert.strictEqual(isFeatureEnabled({ eventReminders: v }, "eventReminders"), false, String(v));
}
// um interruptor não liga o outro
assert.strictEqual(isFeatureEnabled({ eventReminders: true }, "presenceRemovedPush"), false);
// nome errado é erro, não "desligado" (evita ficar dormente por typo)
assert.throws(() => isFeatureEnabled({ eventReminder: true }, "eventReminder"), /desconhecido/);
assert.deepStrictEqual(FEATURE_KEYS, ["eventReminders", "presenceRemovedPush", "feeReminders"]);

console.log("feature_flags: ok");
