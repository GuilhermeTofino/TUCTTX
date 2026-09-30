/**
 * Cria/atualiza o catálogo de skills (`skills_catalog/{skillKey}`) do tenant.
 * O app já funciona sem ele (usa rótulos padrão); o catálogo serve para o admin
 * ajustar rótulo e descrição. Só as 8 chaves abaixo existem: são as que
 * firestore.rules e storage.rules conhecem. Não cria chave nova.
 *
 * Uso:
 *   node seed-skills-catalog.js            -> preview
 *   node seed-skills-catalog.js --apply    -> grava (não sobrescreve rótulo/descrição já editados)
 *
 * Variáveis: ADMIN_ENV (default dev), ADMIN_TENANT_ID (default tucttx),
 * ADMIN_SERVICE_ACCOUNT_PATH.
 */

const fs = require("fs");
const path = require("path");
const os = require("os");
const admin = require("firebase-admin");

const ENV = process.env.ADMIN_ENV || "dev";
const TENANT_ID = process.env.ADMIN_TENANT_ID || "tucttx";
const SERVICE_ACCOUNT_PATH =
    process.env.ADMIN_SERVICE_ACCOUNT_PATH ||
    process.env.FAXINA_SERVICE_ACCOUNT_PATH ||
    path.join(os.homedir(), "Downloads", "tenda-white-label-firebase-adminsdk-fbsvc-8105b9edc3.json");
const APPLY = process.argv.includes("--apply");

// Mantenha igual a PermissionService (lib/core/services/permission_service.dart).
const SKILLS = {
    "calendario.gerenciar": ["Gerenciar calendário", "Criar e editar giras e escalas."],
    "mural.publicar": ["Publicar no mural", "Postar avisos para a casa."],
    "estudos.gerenciar": ["Gerenciar estudos", "Enviar e remover materiais de estudo."],
    "financeiro.gerenciar": ["Gerenciar financeiro", "Ver e dar baixa nas mensalidades e metas."],
    "bazar.gerenciar": ["Gerenciar bazar", "Lançar e baixar dívidas do bazar."],
    "limpeza.gerenciar": ["Gerenciar limpeza", "Editar escala e presença da faxina."],
    "entidades.moderar": ["Moderar entidades", "Ajustar as entidades cadastradas pelos membros."],
    "notificacoes.enviar": ["Enviar notificações", "Disparar avisos por push."],
};

async function main() {
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`Service account não encontrada em: ${SERVICE_ACCOUNT_PATH}`);
        process.exit(1);
    }
    admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
    const catalog = admin.firestore().collection("environments").doc(ENV)
        .collection("tenants").doc(TENANT_ID).collection("skills_catalog");

    console.log(`Modo: ${APPLY ? "APLICAR" : "PREVIEW (nada é alterado)"} | Ambiente: ${ENV} | Tenant: ${TENANT_ID}`);
    for (const [key, [label, description]] of Object.entries(SKILLS)) {
        const ref = catalog.doc(key);
        const existing = await ref.get();
        const data = existing.exists ? existing.data() : {};
        const next = { label: data.label || label, description: data.description || description };
        console.log(`  ${existing.exists ? "[existe]  " : "[criar]   "} ${key} -> "${next.label}"`);
        if (APPLY) await ref.set({ ...next, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }
    if (!APPLY) console.log("\nNenhuma escrita foi feita (preview). Rode com --apply para gravar.");
}

main().catch((error) => { console.error("Erro:", error); process.exit(1); });
