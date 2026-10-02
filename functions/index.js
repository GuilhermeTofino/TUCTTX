const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getRemoteConfig } = require("firebase-admin/remote-config");
const { getStorage } = require("firebase-admin/storage");
const { GoogleAuth } = require("google-auth-library");
const { isExpiredReceipt } = require("./receipt_retention");
const { isFeatureEnabled } = require("./feature_flags");
const { saoPauloParts, saoPauloDayWindow, buildReminderPush, reminderTokens, chunk } = require("./event_reminders");
const { classifyFee, buildFeePush } = require("./fee_reminders");
const { buildPaymentReceiptPush, collectApproverTokens, pendingReceiptMonthKeys } = require("./payment_receipt_push");

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
// Encontra onde um parâmetro já existe (raiz ou dentro de algum grupo) e retorna
// um objeto { get, set } apontando pro lugar certo — evita duplicar a chave caso
// ela já tenha sido criada manualmente num grupo no console do Firebase.
function findParameterSlot(template, key) {
    if (template.parameters[key] !== undefined) {
        return {
            get: () => template.parameters[key],
            set: (value) => { template.parameters[key] = value; },
        };
    }
    for (const group of Object.values(template.parameterGroups || {})) {
        if (group.parameters?.[key] !== undefined) {
            return {
                get: () => group.parameters[key],
                set: (value) => { group.parameters[key] = value; },
            };
        }
    }
    // Não existe em lugar nenhum ainda: cria na raiz.
    return {
        get: () => undefined,
        set: (value) => { template.parameters[key] = value; },
    };
}

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
            const versionSlot = findParameterSlot(template, `${tenant.slug}_min_required_version_android`);
            const current = versionSlot.get()?.defaultValue?.value;
            if (liveAndroid && liveAndroid !== current) {
                versionSlot.set({ defaultValue: { value: liveAndroid }, valueType: "STRING" });
                const urlSlot = findParameterSlot(template, `${tenant.slug}_force_update_store_url_android`);
                urlSlot.set({ defaultValue: { value: tenant.playStoreUrl }, valueType: "STRING" });
                changed = true;
                console.log(`[${tenant.slug}] Android min version: ${current} -> ${liveAndroid}`);
            }
        } catch (e) {
            console.error(`[${tenant.slug}] Erro ao checar versão Android:`, e.message);
        }

        try {
            const liveIos = await getLiveIosVersion(tenant.appStoreId);
            const versionSlot = findParameterSlot(template, `${tenant.slug}_min_required_version_ios`);
            const current = versionSlot.get()?.defaultValue?.value;
            if (liveIos && liveIos !== current) {
                versionSlot.set({ defaultValue: { value: liveIos }, valueType: "STRING" });
                const urlSlot = findParameterSlot(template, `${tenant.slug}_force_update_store_url_ios`);
                urlSlot.set({ defaultValue: { value: tenant.appStoreUrl }, valueType: "STRING" });
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
 * Escuta confirmações de presença em eventos (events/{eventId}/confirmations/{userId})
 * e notifica os admins do tenant. Não depende de nenhuma mudança no app — o app já
 * grava esse documento hoje, então não precisa de nova versão nas lojas.
 */
exports.notifyAdminsOnPresenceConfirmed = onDocumentCreated({
    document: "environments/{env}/tenants/{tenantId}/events/{eventId}/confirmations/{userId}",
    region: "southamerica-east1"
}, async (event) => {
    const { env, tenantId, eventId, userId } = event.params;
    const confirmation = event.data.data();
    const db = getFirestore();

    try {
        const tenantRoot = db.collection("environments").doc(env).collection("tenants").doc(tenantId);

        const eventDoc = await tenantRoot.collection("events").doc(eventId).get();
        if (!eventDoc.exists) {
            console.log(`[${tenantId}] Evento ${eventId} não encontrado, ignorando confirmação de ${confirmation.name}.`);
            return;
        }
        const eventData = eventDoc.data();

        const eventDate = eventData.date?.toDate();
        const formattedDate = eventDate
            ? `${eventDate.getDate().toString().padStart(2, "0")}/${(eventDate.getMonth() + 1).toString().padStart(2, "0")}`
            : "";

        const adminsSnap = await tenantRoot.collection("users").where("role", "==", "admin").get();
        const tokens = [];
        adminsSnap.forEach((doc) => {
            if (doc.id === userId) return; // não notifica o próprio admin que confirmou
            const adminTokens = doc.data().fcmTokens;
            if (Array.isArray(adminTokens)) tokens.push(...adminTokens);
        });

        if (tokens.length === 0) {
            console.log(`[${tenantId}] Nenhum admin com token FCM para notificar sobre a confirmação de ${confirmation.name}.`);
            return;
        }

        const confirmationsCountSnap = await tenantRoot
            .collection("events").doc(eventId).collection("confirmations")
            .count().get();
        const confirmedCount = confirmationsCountSnap.data().count;

        await db.collection("notifications_queue").add({
            tokens,
            title: `🗓️ ${confirmation.name} vai na gira!`,
            body: `${confirmation.name} acabou de confirmar presença na "${eventData.title}"${formattedDate ? ` (dia ${formattedDate})` : ""}. Já são ${confirmedCount} confirmado${confirmedCount === 1 ? "" : "s"}!`,
            tenantId,
            env,
            status: "pending",
            createdAt: FieldValue.serverTimestamp(),
            data: { type: "presence_confirmed", eventId },
        });
        console.log(`[${tenantId}] Notificação enfileirada: ${confirmation.name} -> ${tokens.length} admin(s) sobre "${eventData.title}".`);
    } catch (error) {
        console.error("Erro ao notificar admins sobre confirmação de presença:", error);
    }
});

/**
 * Escuta comprovantes enviados por membros (payment_requests/{requestId}) e avisa
 * os aprovadores do financeiro (settings/finance -> approverIds), exceto o próprio
 * solicitante.
 */
exports.notifyApproversOnPaymentRequest = onDocumentCreated({
    document: "environments/{env}/tenants/{tenantId}/payment_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const { env, tenantId, requestId } = event.params;
    const request = event.data.data();
    const db = getFirestore();

    try {
        if (request.status !== "pending_approval") return;

        const tenantRoot = db.collection("environments").doc(env).collection("tenants").doc(tenantId);

        const settingsDoc = await tenantRoot.collection("settings").doc("finance").get();
        const approverIds = settingsDoc.exists ? (settingsDoc.data().approverIds || []) : [];
        if (approverIds.length === 0) {
            console.warn(`[${tenantId}] settings/finance sem approverIds: comprovante ${requestId} ficou sem notificação.`);
            return;
        }

        const userDocs = await Promise.all(approverIds.map((id) => tenantRoot.collection("users").doc(id).get()));
        const usersById = {};
        userDocs.forEach((doc) => { if (doc.exists) usersById[doc.id] = doc.data(); });

        const tokens = collectApproverTokens({ approverIds, usersById, requesterId: request.userId });
        if (tokens.length === 0) {
            console.warn(`[${tenantId}] Nenhum aprovador com token FCM para o comprovante ${requestId}.`);
            return;
        }

        const push = buildPaymentReceiptPush({ request, requestId, tenantId, env });
        await db.collection("notifications_queue").add({
            tokens,
            title: push.title,
            body: push.body,
            tenantId,
            env,
            status: "pending",
            createdAt: FieldValue.serverTimestamp(),
            data: push.data,
        });
        console.log(`[${tenantId}] Comprovante ${requestId} enfileirado para ${tokens.length} token(s) de aprovadores.`);
    } catch (error) {
        console.error("Erro ao notificar aprovadores sobre comprovante:", error);
    }
});

/**
 * Retenção de comprovantes: em 1º de janeiro apaga os arquivos de anos anteriores
 * (receipts/{ano}/...). Só o arquivo é removido; a solicitação e os dados contábeis
 * permanecem no Firestore, e o app passa a mostrar "comprovante indisponível".
 * Nunca toca no ano corrente. Apaga qualquer ano anterior (não só o último), para
 * recuperar uma execução perdida.
 */
exports.deleteExpiredReceipts = onSchedule({
    schedule: "0 3 1 1 *",
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1"
}, async () => {
    const db = getFirestore();
    const currentYear = new Date().getFullYear();
    const bucket = getStorage().bucket();

    console.log(`Limpeza de comprovantes: removendo anos anteriores a ${currentYear}.`);

    for (const env of ["dev", "prod"]) {
        const tenantsSnap = await db.collection("environments").doc(env).collection("tenants").get();

        for (const tenantDoc of tenantsSnap.docs) {
            const prefix = `environments/${env}/tenants/${tenantDoc.id}/receipts/`;
            try {
                const [files] = await bucket.getFiles({ prefix });
                const expired = files.filter((file) => isExpiredReceipt(file.name, currentYear));

                for (const file of expired) {
                    await file.delete();
                }
                console.log(`[${env}/${tenantDoc.id}] ${expired.length} comprovante(s) removido(s) de ${files.length} listado(s).`);
            } catch (error) {
                console.error(`[${env}/${tenantDoc.id}] Erro na limpeza de comprovantes:`, error);
            }
        }
    }
});

/**
 * Função agendada para verificar mensalidades atrasadas.
 * Executa toda segunda-feira às 09:00 (Brasília).
 * Tenants com `feeReminders` ligado são atendidos por sendFeeReminders (vencimento dia 10) e
 * ficam fora daqui, para não avisar em duplicidade.
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
            const flags = (await tenantDoc.ref.collection("settings").doc("features").get()).data();
            if (isFeatureEnabled(flags, "feeReminders")) continue;
            const usersSnap = await tenantDoc.ref.collection("users").get();

            // Meses com comprovante aguardando aprovação não são cobrados.
            const openRequestsSnap = await tenantDoc.ref.collection("payment_requests")
                .where("status", "==", "pending_approval")
                .get();
            const underReview = pendingReceiptMonthKeys(openRequestsSnap.docs.map((d) => d.data()));

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

                    if (isPast && underReview.has(`${userId}_${feeData.year}_${feeData.month}`)) {
                        console.log(`Mensalidade em análise, ignorada: User ${userId}, ${feeData.month}/${feeData.year}`);
                        continue;
                    }

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

/**
 * Lembretes de mensalidade, todo dia às 09:00 (Brasília). Vencimento: dia 10 (fee_reminders.js).
 *
 * - Pré-vencimento: 3 dias antes (dia 7) e no dia (10), para mensalidades pendentes.
 * - Atraso: no dia seguinte ao vencimento a mensalidade vira 'late' e o membro é avisado;
 *   quem segue em atraso é lembrado a cada 7 dias. Um push por membro e tipo, por execução.
 * - Só membros (user/admin). Mês com comprovante aguardando aprovação não é cobrado.
 * - Idempotente: marca `reminders_sent/fee_{uid}_{tipo}_{dia}`; reexecução não reenvia.
 * - Atrás do interruptor `feeReminders` (settings/features), desligado por padrão.
 */
exports.sendFeeReminders = onSchedule({
    schedule: "every day 09:00",
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1"
}, async () => {
    const db = getFirestore();
    const now = new Date();
    const sp = saoPauloParts(now);
    const today = { y: sp.y, m: sp.m + 1, d: sp.d };
    const dayKey = saoPauloDayWindow(now, 0).key;

    for (const env of ["dev", "prod"]) {
        const tenantsSnap = await db.collection("environments").doc(env).collection("tenants").get();

        for (const tenantDoc of tenantsSnap.docs) {
            const tenantId = tenantDoc.id;
            try {
                const flags = (await tenantDoc.ref.collection("settings").doc("features").get()).data();
                if (!isFeatureEnabled(flags, "feeReminders")) {
                    console.log(`[${env}/${tenantId}] feeReminders desligado: nada enviado.`);
                    continue;
                }

                const openRequestsSnap = await tenantDoc.ref.collection("payment_requests")
                    .where("status", "==", "pending_approval")
                    .get();
                const underReview = pendingReceiptMonthKeys(openRequestsSnap.docs.map((d) => d.data()));

                const usersSnap = await tenantDoc.ref.collection("users").where("role", "in", ["user", "admin"]).get();

                for (const userDoc of usersSnap.docs) {
                    const user = userDoc.data();
                    const userId = userDoc.id;
                    if (!Array.isArray(user.fcmTokens) || user.fcmTokens.length === 0) continue;

                    const feesSnap = await tenantDoc.ref.collection("financial").doc(userId).collection("monthly_fees")
                        .where("status", "in", ["pending", "late"])
                        .get();

                    const groups = { pre_due: [], due_today: [], overdue: [] };
                    for (const feeDoc of feesSnap.docs) {
                        const fee = feeDoc.data();
                        if (underReview.has(`${userId}_${fee.year}_${fee.month}`)) continue;
                        const action = classifyFee(fee, today, fee.lastReminderAt?.toDate?.());
                        if (!action) continue;
                        groups[action.startsWith("overdue") ? "overdue" : action].push({ fee, ref: feeDoc.ref });
                    }

                    const firstName = (user.name || "").split(" ")[0] || "";
                    for (const kind of Object.keys(groups)) {
                        const entries = groups[kind];
                        if (entries.length === 0) continue;

                        const marker = tenantDoc.ref.collection("reminders_sent").doc(`fee_${userId}_${kind}_${dayKey}`);
                        try {
                            await marker.create({ sentAt: FieldValue.serverTimestamp() });
                        } catch (error) {
                            if (error.code === 6 || /ALREADY_EXISTS/i.test(String(error.message))) continue;
                            throw error;
                        }

                        const fees = entries.map((e) => e.fee).sort((a, b) => a.year - b.year || a.month - b.month);
                        const push = buildFeePush({ kind, fees, firstName });
                        await db.collection("notifications_queue").add({
                            tokens: user.fcmTokens,
                            title: push.title,
                            body: push.body,
                            tenantId,
                            env,
                            status: "pending",
                            createdAt: FieldValue.serverTimestamp(),
                            data: push.data,
                        });

                        if (kind === "overdue") {
                            for (const { ref } of entries) {
                                await ref.update({
                                    status: "late",
                                    lastReminderAt: FieldValue.serverTimestamp(),
                                    updatedAt: FieldValue.serverTimestamp()
                                });
                            }
                        }
                    }
                }
            } catch (error) {
                console.error(`[${env}/${tenantId}] Erro nos lembretes de mensalidade:`, error);
            }
        }
    }
});

/**
 * Lembretes de eventos, todo dia às 07:00 (Brasília): véspera ("amanhã") e dia ("hoje").
 *
 * - Eventos guardam `date` como Timestamp; a janela do dia é calculada no fuso de
 *   São Paulo (ver event_reminders.js), não no do servidor (UTC).
 * - Não vai para visitantes, salvo evento com `audience` incluindo 'visitor'.
 * - Um push por evento e lote de 500 tokens, pela fila `notifications_queue`.
 * - Idempotente: marca `reminders_sent/{evento}_{tipo}_{dia}`; reexecução não reenvia.
 */
exports.sendEventReminders = onSchedule({
    schedule: "every day 07:00",
    timeZone: "America/Sao_Paulo",
    region: "southamerica-east1"
}, async () => {
    const db = getFirestore();
    const now = new Date();
    const windows = [
        { type: "lembrete_vespera", ...saoPauloDayWindow(now, 1) },
        { type: "lembrete_dia", ...saoPauloDayWindow(now, 0) },
    ];

    for (const env of ["dev", "prod"]) {
        const tenantsSnap = await db.collection("environments").doc(env).collection("tenants").get();

        for (const tenantDoc of tenantsSnap.docs) {
            const tenantId = tenantDoc.id;
            try {
                // Novidade visível para os membros: nasce desligada (settings/features).
                const flags = (await tenantDoc.ref.collection("settings").doc("features").get()).data();
                if (!isFeatureEnabled(flags, "eventReminders")) {
                    console.log(`[${env}/${tenantId}] eventReminders desligado: nada enviado.`);
                    continue;
                }

                const users = (await tenantDoc.ref.collection("users").get()).docs.map((d) => d.data());

                for (const window of windows) {
                    const eventsSnap = await tenantDoc.ref.collection("events")
                        .where("date", ">=", Timestamp.fromDate(window.start))
                        .where("date", "<", Timestamp.fromDate(window.end))
                        .get();

                    for (const eventDoc of eventsSnap.docs) {
                        const event = eventDoc.data();

                        // create() falha se a marca já existe: garante um envio por evento/dia.
                        const marker = tenantDoc.ref.collection("reminders_sent")
                            .doc(`${eventDoc.id}_${window.type}_${window.key}`);
                        try {
                            await marker.create({ sentAt: FieldValue.serverTimestamp() });
                        } catch (error) {
                            if (error.code === 6 || /ALREADY_EXISTS/i.test(String(error.message))) continue;
                            throw error;
                        }

                        const tokens = reminderTokens(users, event);
                        if (tokens.length === 0) continue;

                        const push = buildReminderPush({ type: window.type, event, eventId: eventDoc.id });
                        for (const batch of chunk(tokens, 500)) {
                            await db.collection("notifications_queue").add({
                                tokens: batch,
                                title: push.title,
                                body: push.body,
                                tenantId,
                                env,
                                status: "pending",
                                createdAt: FieldValue.serverTimestamp(),
                                data: push.data,
                            });
                        }
                        console.log(`[${env}/${tenantId}] ${window.type} "${event.title}": ${tokens.length} token(s).`);
                    }
                }
            } catch (error) {
                console.error(`[${env}/${tenantId}] Erro nos lembretes de eventos:`, error);
            }
        }
    }
});

/**
 * Presença desmarcada: quando a confirmação (events/{id}/confirmations/{uid}) é apagada,
 * avisa os admins. A confirmação em si já é tratada por notifyAdminsOnPresenceConfirmed.
 * Se o evento inteiro foi removido, não avisa (evita enxurrada ao excluir um evento).
 */
exports.notifyAdminsOnPresenceRemoved = onDocumentDeleted({
    document: "environments/{env}/tenants/{tenantId}/events/{eventId}/confirmations/{userId}",
    region: "southamerica-east1"
}, async (event) => {
    const { env, tenantId, eventId, userId } = event.params;
    const confirmation = event.data?.data() || {};
    const db = getFirestore();

    try {
        const tenantRoot = db.collection("environments").doc(env).collection("tenants").doc(tenantId);

        // Novidade visível para os admins: nasce desligada (settings/features).
        const flags = (await tenantRoot.collection("settings").doc("features").get()).data();
        if (!isFeatureEnabled(flags, "presenceRemovedPush")) return;

        const eventDoc = await tenantRoot.collection("events").doc(eventId).get();
        if (!eventDoc.exists) return;
        const eventData = eventDoc.data();

        const adminsSnap = await tenantRoot.collection("users").where("role", "==", "admin").get();
        const tokens = [];
        adminsSnap.forEach((doc) => {
            if (doc.id === userId) return; // não avisa o próprio admin
            if (Array.isArray(doc.data().fcmTokens)) tokens.push(...doc.data().fcmTokens);
        });
        if (tokens.length === 0) return;

        const eventDate = eventData.date?.toDate();
        const when = eventDate
            ? ` (dia ${String(eventDate.getUTCDate()).padStart(2, "0")}/${String(eventDate.getUTCMonth() + 1).padStart(2, "0")})`
            : "";
        const who = confirmation.name || "Um membro";

        await db.collection("notifications_queue").add({
            tokens: [...new Set(tokens)],
            title: `🗓️ ${who} desmarcou presença`,
            body: `${who} não vai mais na "${eventData.title || "gira"}"${when}.`,
            tenantId,
            env,
            status: "pending",
            createdAt: FieldValue.serverTimestamp(),
            data: { type: "presence_removed", eventId },
        });
    } catch (error) {
        console.error("Erro ao notificar admins sobre presença desmarcada:", error);
    }
});
