const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getRemoteConfig } = require("firebase-admin/remote-config");
const { GoogleAuth } = require("google-auth-library");

initializeApp();

const PLAY_PUBLISHER_KEY = defineSecret("PLAY_PUBLISHER_KEY");

// Tenants cujo release em loja é acompanhado para forçar atualização.
// Adicione uma entrada aqui quando outro tenant passar a publicar via CI.
const FORCE_UPDATE_TENANTS = [
    {
        slug: "tucttx",
        androidPackage: "com.appTenda",
        appStoreId: "6758684822",
        playStoreUrl: "https://play.google.com/store/apps/details?id=com.appTenda",
        appStoreUrl: "https://apps.apple.com/app/id6758684822",
    },
];

async function getLiveAndroidVersion(packageName, serviceAccountJson) {
    const auth = new GoogleAuth({
        credentials: JSON.parse(serviceAccountJson),
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const client = await auth.getClient();
    const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}`;

    const edit = await client.request({ method: "POST", url: `${base}/edits` });
    const editId = edit.data.id;

    try {
        const track = await client.request({ url: `${base}/edits/${editId}/tracks/production` });
        return track.data.releases?.[0]?.name || null;
    } finally {
        await client.request({ method: "DELETE", url: `${base}/edits/${editId}` }).catch(() => {});
    }
}

async function getLiveIosVersion(appStoreId) {
    // A API legada itunes.apple.com/lookup fica com cache desatualizado por um
    // bom tempo após a Apple liberar a versão. A própria página pública da loja
    // reflete a versão real assim que fica "Pronta para Venda".
    const res = await fetch(`https://apps.apple.com/br/app/id${appStoreId}`, {
        headers: { "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" },
    });
    const html = await res.text();
    const match = html.match(/"style":"overview".*?"primarySubtitle":"Vers[ãa]o ([0-9.]+)"/);
    return match ? match[1] : null;
}

/**
 * Roda periodicamente e sincroniza o Remote Config (chaves *_min_required_version_*)
 * com a versão realmente publicada em produção nas lojas. Assim que uma nova versão
 * fica pública (Play Store ou App Store), usuários em versões antigas passam a ser
 * obrigados a atualizar — sem nenhum passo manual após o release.
 */
exports.syncForceUpdateVersion = onSchedule({
    schedule: "every 30 minutes",
    region: "southamerica-east1",
    secrets: [PLAY_PUBLISHER_KEY],
}, async () => {
    const rc = getRemoteConfig();
    const template = await rc.getTemplate();
    let changed = false;

    for (const tenant of FORCE_UPDATE_TENANTS) {
        try {
            const liveAndroid = await getLiveAndroidVersion(tenant.androidPackage, PLAY_PUBLISHER_KEY.value());
            const key = `${tenant.slug}_min_required_version_android`;
            const current = template.parameters[key]?.defaultValue?.value;
            if (liveAndroid && liveAndroid !== current) {
                template.parameters[key] = { defaultValue: { value: liveAndroid }, valueType: "STRING" };
                template.parameters[`${tenant.slug}_force_update_store_url_android`] = {
                    defaultValue: { value: tenant.playStoreUrl },
                    valueType: "STRING",
                };
                changed = true;
                console.log(`[${tenant.slug}] Android min version: ${current} -> ${liveAndroid}`);
            }
        } catch (e) {
            console.error(`[${tenant.slug}] Erro ao checar versão Android:`, e.message);
        }

        try {
            const liveIos = await getLiveIosVersion(tenant.appStoreId);
            const key = `${tenant.slug}_min_required_version_ios`;
            const current = template.parameters[key]?.defaultValue?.value;
            if (liveIos && liveIos !== current) {
                template.parameters[key] = { defaultValue: { value: liveIos }, valueType: "STRING" };
                template.parameters[`${tenant.slug}_force_update_store_url_ios`] = {
                    defaultValue: { value: tenant.appStoreUrl },
                    valueType: "STRING",
                };
                changed = true;
                console.log(`[${tenant.slug}] iOS min version: ${current} -> ${liveIos}`);
            }
        } catch (e) {
            console.error(`[${tenant.slug}] Erro ao checar versão iOS:`, e.message);
        }
    }

    if (changed) {
        await rc.validateTemplate(template);
        await rc.publishTemplate(template);
        console.log("Remote Config publicado com novas versões mínimas.");
    } else {
        console.log("Nenhuma mudança de versão detectada.");
    }
});

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
