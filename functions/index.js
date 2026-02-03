const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

/**
 * Escuta a coleção 'notifications_queue' e envia a notificação via FCM.
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
            response = await messaging.send({
                topic: data.topic,
                ...message,
                ...options
            });
        } else if (data.tokens && data.tokens.length > 0) {
            response = await messaging.sendEachForMulticast({
                tokens: data.tokens,
                ...message,
                ...options
            });
        }

        await event.data.ref.delete();

    } catch (error) {
        console.error("Erro ao processar notificação da fila:", error);
        await event.data.ref.update({ status: 'error', error: error.message });
    }
});

/**
 * Função agendada para verificar mensalidades atrasadas.
 * Executa toda segunda-feira às 09:00 (Brasília).
 */
exports.checkLateFees = onSchedule({
    schedule: "every monday 09:00",
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1"
}, async (event) => {
    const db = getFirestore();
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    console.log(`Iniciando verificação de mensalidades: ${currentMonth}/${currentYear}`);

    const envs = ['dev', 'prod'];

    for (const env of envs) {
        const tenantsSnap = await db.collection("environments").doc(env).collection("tenants").get();

        for (const tenantDoc of tenantsSnap.docs) {
            const tenantId = tenantDoc.id;
            const usersSnap = await tenantDoc.ref.collection("users").get();

            for (const userDoc of usersSnap.docs) {
                const userData = userDoc.data();
                const userId = userDoc.id;

                // Busca mensalidades PENDENTES
                const feesSnap = await tenantDoc.ref.collection("financial").doc(userId).collection("monthly_fees")
                    .where("status", "==", "pending")
                    .get();

                for (const feeDoc of feesSnap.docs) {
                    const feeData = feeDoc.data();

                    // Verifica se o mês/ano já passou
                    const isPast = (feeData.year < currentYear) || (feeData.year === currentYear && feeData.month < currentMonth);

                    if (isPast) {
                        console.log(`Mensalidade ATRASADA encontrada: User ${userId}, ${feeData.month}/${feeData.year}`);

                        // 1. Atualiza status para 'late'
                        await feeDoc.ref.update({
                            status: "late",
                            updatedAt: FieldValue.serverTimestamp()
                        });

                        // 2. Agenda notificação se o usuário tiver tokens
                        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
                            const firstName = userData.name.split(' ')[0];
                            await db.collection("notifications_queue").add({
                                tokens: userData.fcmTokens,
                                title: "💰 Mensalidade em Atraso",
                                body: `Olá ${firstName}! Identificamos que a mensalidade de ${feeData.month}/${feeData.year} está em aberto.`,
                                tenantId: tenantId,
                                env: env,
                                status: "pending",
                                createdAt: FieldValue.serverTimestamp(),
                                data: { type: "finance_reminder", category: "fee" }
                            });
                        }
                    }
                }
            }
        }
    }

    console.log("Verificação de mensalidades concluída.");
});
