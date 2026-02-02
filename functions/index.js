const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Escuta a coleção 'notifications_queue' e envia a notificação via FCM.
 * Após o envio, remove o documento da fila para mantê-la limpa.
 */
exports.processNotificationQueue = onDocumentCreated({
    document: "notifications_queue/{docId}",
    region: "southamerica-east1"
}, async (event) => {
    const data = event.data.data();
    const messaging = getMessaging();

    try {
        const message = {
            notification: {
                title: data.title,
                body: data.body,
            },
            data: data.data || {},
        };

        // Prioridade e som para popups "amigáveis"
        const options = {
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId: "high_importance_channel",
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    }
                }
            }
        };

        let response;

        if (data.topic) {
            // Envio por Tópico (Ex: Avisos Gerais)
            response = await messaging.send({
                topic: data.topic,
                ...message,
                ...options
            });
            console.log(`Notificação enviada para o tópico ${data.topic}:`, response);
        } else if (data.tokens && data.tokens.length > 0) {
            // Envio por Tokens Individuais (Ex: Escala de Faxina)
            response = await messaging.sendEachForMulticast({
                tokens: data.tokens,
                ...message,
                ...options
            });
            console.log(`${response.successCount} notificações enviadas com sucesso.`);
        }

        // Remove da fila após processar com sucesso (ou após tentativa)
        await event.data.ref.delete();

    } catch (error) {
        console.error("Erro ao processar notificação da fila:", error);
        // Atualiza o status para erro em caso de falha crítica (mantém na fila para debug se necessário)
        await event.data.ref.update({ status: 'error', error: error.message });
    }
});
