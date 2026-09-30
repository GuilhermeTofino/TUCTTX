const MONTH_NAMES = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
];

/**
 * Monta o push enviado aos aprovadores quando um membro envia comprovante.
 * Isolado do index.js para poder ser testado sem Firebase.
 * Todos os valores de `data` precisam ser string (exigência do FCM).
 */
function buildPaymentReceiptPush({ request, requestId, tenantId, env }) {
    const months = (request.items || [])
        .map((i) => `${MONTH_NAMES[(i.month || 1) - 1]}/${i.year}`)
        .join(", ");
    const name = request.userName || "Um membro";

    return {
        title: "🧾 Comprovante aguardando aprovação",
        body: `${name} enviou comprovante de ${months}. Toque para revisar.`,
        data: {
            type: "payment_receipt_pending",
            requestId: String(requestId),
            userId: String(request.userId || ""),
            tenantId: String(tenantId),
            env: String(env),
        },
    };
}

/**
 * Tokens FCM dos aprovadores, sem o próprio solicitante (não há autoaprovação)
 * e apenas de quem ainda é admin.
 */
function collectApproverTokens({ approverIds, usersById, requesterId }) {
    const tokens = [];
    for (const id of approverIds) {
        if (id === requesterId) continue;
        const user = usersById[id];
        if (!user || user.role !== "admin") continue;
        if (Array.isArray(user.fcmTokens)) tokens.push(...user.fcmTokens);
    }
    return [...new Set(tokens)];
}

/**
 * Chaves `userId_ano_mes` dos meses que ainda têm comprovante aguardando
 * aprovação. O checkLateFees usa isso para não cobrar quem já pagou e espera.
 */
function pendingReceiptMonthKeys(requests) {
    const keys = new Set();
    for (const request of requests) {
        for (const item of request.items || []) {
            if (item.status === "pending_approval") {
                keys.add(`${request.userId}_${item.year}_${item.month}`);
            }
        }
    }
    return keys;
}

module.exports = { buildPaymentReceiptPush, collectApproverTokens, pendingReceiptMonthKeys };
