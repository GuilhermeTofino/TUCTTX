const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { computeAndQueueRanking } = require("./faxina_ranking");

initializeApp();

const WHATSAPP_VERIFY_TOKEN = defineSecret("WHATSAPP_VERIFY_TOKEN");
const WHATSAPP_ACCESS_TOKEN = defineSecret("WHATSAPP_ACCESS_TOKEN");
const WHATSAPP_PHONE_NUMBER_ID = defineSecret("WHATSAPP_PHONE_NUMBER_ID");
const SCHEDULER_TOKEN = defineSecret("SCHEDULER_TOKEN");

// Números autorizados a disparar comandos por WhatsApp (formato E.164, sem "+",
// igual ao "from"/"wa_id" que a Meta manda no webhook).
// Qualquer mensagem de um número fora desta lista é ignorada silenciosamente.
const WHATSAPP_ALLOWED_SENDERS = [
    "5511992609315",
    "5511975793122",
    "5511989604994",
];

const WHATSAPP_RANKING_KEYWORD = "ranking faxina";
const WHATSAPP_RANKING_TEST_KEYWORD = "ranking faxina teste";

/**
 * Webhook do WhatsApp Cloud API (Meta). GET é a verificação de assinatura do
 * webhook (handshake exigido pela Meta ao configurar); POST recebe as
 * mensagens de fato. Só aceita comandos de números autorizados
 * (WHATSAPP_ALLOWED_SENDERS) e só reage à palavra-chave WHATSAPP_RANKING_KEYWORD.
 * Ao receber o comando válido, recalcula o ranking de faxina e enfileira as
 * notificações (mesma lógica de scripts/admin/faxina-ranking-notify.js).
 */
exports.whatsappRankingTrigger = onRequest({
    region: "southamerica-east1",
    secrets: [WHATSAPP_VERIFY_TOKEN, WHATSAPP_ACCESS_TOKEN, WHATSAPP_PHONE_NUMBER_ID],
}, async (req, res) => {
    if (req.method === "GET") {
        const mode = req.query["hub.mode"];
        const token = req.query["hub.verify_token"];
        const challenge = req.query["hub.challenge"];

        if (mode === "subscribe" && token === WHATSAPP_VERIFY_TOKEN.value()) {
            res.status(200).send(challenge);
        } else {
            console.warn("whatsappRankingTrigger: verificação de webhook falhou (token não bate).");
            res.sendStatus(403);
        }
        return;
    }

    async function sendWhatsAppReply(to, body) {
        const url = `https://graph.facebook.com/v21.0/${WHATSAPP_PHONE_NUMBER_ID.value()}/messages`;
        const resp = await fetch(url, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${WHATSAPP_ACCESS_TOKEN.value()}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                messaging_product: "whatsapp",
                to,
                text: { body },
            }),
        });
        const responseText = await resp.text();
        if (!resp.ok) {
            console.error("whatsappRankingTrigger: falha ao responder via WhatsApp", resp.status, responseText);
        } else {
            console.log("whatsappRankingTrigger: resposta da Meta ao enviar mensagem", resp.status, responseText);
        }
    }

    try {
        const message = req.body.entry?.[0]?.changes?.[0]?.value?.messages?.[0];

        // Outros eventos do webhook (status de entrega, etc.) não têm "messages".
        if (!message) {
            res.sendStatus(200);
            return;
        }

        const from = message.from; // ex: "5511992609315", sem "+"
        const text = (message.text?.body || "").trim().toLowerCase();

        if (!WHATSAPP_ALLOWED_SENDERS.includes(from)) {
            console.warn(`whatsappRankingTrigger: remetente não autorizado (${from}), ignorado.`);
            res.sendStatus(200);
            return;
        }

        if (text !== WHATSAPP_RANKING_KEYWORD && text !== WHATSAPP_RANKING_TEST_KEYWORD) {
            await sendWhatsAppReply(
                from,
                `Comando não reconhecido. Envie "${WHATSAPP_RANKING_TEST_KEYWORD}" para testar sem disparar nada, ou "${WHATSAPP_RANKING_KEYWORD}" para disparar de verdade.`
            );
            res.sendStatus(200);
            return;
        }

        const dryRun = text === WHATSAPP_RANKING_TEST_KEYWORD;
        const result = await computeAndQueueRanking({ dryRun });
        console.log("whatsappRankingTrigger: ranking processado", result);

        const replyText = dryRun
            ? `[TESTE, nada foi enviado] ${result.wouldQueue} notificações seriam enfileiradas (${result.totalRanking} no ranking, ${result.notFound} sem conta no app, ${result.ambiguous} ambíguos).`
            : `Ranking de faxina disparado! ${result.queued} notificações enfileiradas (${result.totalRanking} no ranking, ${result.notFound} sem conta no app, ${result.ambiguous} ambíguos).`;

        await sendWhatsAppReply(from, replyText);
        res.sendStatus(200);
    } catch (error) {
        console.error("whatsappRankingTrigger: erro ao processar webhook", error);
        // Responde 200 mesmo em erro para a Meta não ficar reenviando o mesmo evento.
        res.sendStatus(200);
    }
});

/**
 * Disparo único (via Cloud Scheduler) do aviso de que o ranking de faxina foi
 * zerado. Protegida por um token compartilhado no header (não é pública) —
 * só quem tem o SCHEDULER_TOKEN consegue chamar. Manda pro tópico geral do
 * app (todos os usuários do tenant), não depende de resolver nome->conta.
 */
exports.sendFaxinaResetAnnouncement = onRequest({
    region: "southamerica-east1",
    secrets: [SCHEDULER_TOKEN],
}, async (req, res) => {
    if (req.get("x-scheduler-token") !== SCHEDULER_TOKEN.value()) {
        console.warn("sendFaxinaResetAnnouncement: token inválido, requisição ignorada.");
        res.sendStatus(403);
        return;
    }

    const db = getFirestore();
    await db.collection("notifications_queue").add({
        topic: "tucttx_prod_all",
        title: "🧹✨ Faxômetro zerado!",
        body: "Respira fundo, geral: o ranking de faxina voltou a zero! A partir de agora, quem sobe no ranking é quem marca a presença lá no quadro de avisos — então já sabe: roda o pano, assina a lista, e garante seu lugar no topo (e a paz com o pessoal da faxina) 🧽🏆",
        data: { type: "cleaning_ranking_reset" },
        tenantId: "tucttx",
        env: "prod",
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
    });

    console.log("sendFaxinaResetAnnouncement: anúncio enfileirado.");
    res.sendStatus(200);
});
