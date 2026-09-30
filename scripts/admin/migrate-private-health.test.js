// Teste sem framework: `node scripts/admin/migrate-private-health.test.js`
const assert = require("node:assert");
const { planMove } = require("./migrate-private-health");

// documento antigo com saúde, sem privado: copia o que tem valor, remove todos os campos presentes
let plan = planMove({ name: "x", alergias: " amendoim ", medicamentos: "", tipoSanguineo: "O+" }, null);
assert.deepStrictEqual(plan.toCopy, { alergias: "amendoim", tipoSanguineo: "O+" });
assert.deepStrictEqual(plan.toDelete.sort(), ["alergias", "medicamentos", "tipoSanguineo"]);

// o privado já tem valor: prevalece; ainda assim o campo sai do documento aberto
plan = planMove({ alergias: "antiga" }, { alergias: "nova" });
assert.deepStrictEqual(plan.toCopy, {});
assert.deepStrictEqual(plan.toDelete, ["alergias"]);

// privado existe mas está vazio nesse campo: preenche
plan = planMove({ alergias: "antiga" }, { alergias: "  " });
assert.deepStrictEqual(plan.toCopy, { alergias: "antiga" });

// já migrado (nada de saúde no documento): não faz nada
plan = planMove({ name: "x", role: "user" }, { alergias: "a" });
assert.deepStrictEqual(plan, { toCopy: {}, toDelete: [] });

// campos null (o app antigo gravava null) são removidos sem copiar
plan = planMove({ alergias: null, medicamentos: null }, null);
assert.deepStrictEqual(plan.toCopy, {});
assert.deepStrictEqual(plan.toDelete.sort(), ["alergias", "medicamentos"]);

// idempotência: depois de aplicar, planejar de novo não faz nada
const after = { name: "x" }; // documento sem os campos
assert.deepStrictEqual(planMove(after, { alergias: "amendoim" }), { toCopy: {}, toDelete: [] });

console.log("migrate-private-health: ok");
