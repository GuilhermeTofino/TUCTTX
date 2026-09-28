const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const ENV = "prod";
const TENANT_ID = "tucttx";

// Nomes do ranking que o matching automático (por primeiro nome) não
// consegue resolver sozinho, porque existe mais de uma pessoa cadastrada
// com o mesmo primeiro nome (ex.: duas "Milena"). Resolvido manualmente
// uma vez; só precisa mudar se um caso novo desses aparecer.
const MANUAL_USER_OVERRIDE = {
    'Milena "Nena"': "7lMSwOr6jZgHo8NXfLukrrt9Ew82", // Milena Barbosa de Barros Leite
    'Milena "ruiva"': "aMosZReZoZWgKhv3PgXPoqHhzum1", // Milena Cavicchioli
};

function norm(s) {
    return s
        .normalize("NFD")
        .replace(/[̀-ͯ]/g, "")
        .toLowerCase()
        .trim();
}

function parseName(rawName) {
    const m = rawName.match(/^(.+?)\s*"(.+)"$/);
    if (m) return { base: m[1].trim(), nickname: m[2].trim() };
    return { base: rawName.trim(), nickname: null };
}

function isSubsequence(baseTokens, userTokens) {
    let i = 0;
    for (const t of userTokens) {
        if (t === baseTokens[i]) i++;
        if (i === baseTokens.length) return true;
    }
    return false;
}

// Mesma comparação ordinal usada em cleaning_dashboard_viewmodel.dart
// (String.compareTo do Dart), para o desempate bater com o app.
function ordinalCompare(a, b) {
    return a < b ? -1 : a > b ? 1 : 0;
}

/**
 * Recalcula o ranking de faxina a partir do Firestore, resolve nome -> usuário
 * -> tokens FCM, e enfileira uma notificação personalizada por pessoa em
 * notifications_queue. Retorna um resumo do que foi feito.
 *
 * Com dryRun=true, faz todo o cálculo e a resolução de nomes normalmente,
 * mas NÃO escreve nada em notifications_queue — não dispara push de verdade.
 * Serve pra validar o fluxo (webhook, autorização, matching de nomes) sem
 * incomodar ninguém.
 */
async function computeAndQueueRanking({ dryRun = false } = {}) {
    const db = getFirestore();

    function tenantCollection(name) {
        return db.collection("environments").doc(ENV).collection("tenants").doc(TENANT_ID).collection(name);
    }

    const eventsSnap = await tenantCollection("events").get();
    const attendanceMap = new Map();

    eventsSnap.forEach((doc) => {
        const e = doc.data();
        const crew = e.cleaningCrew;
        if (!crew || crew.length === 0) return;
        const attendance = e.confirmedAttendance || [];
        for (const name of attendance) {
            if (crew.includes(name)) {
                attendanceMap.set(name, (attendanceMap.get(name) || 0) + 1);
            }
        }
    });

    const ranking = Array.from(attendanceMap.entries())
        .map(([name, count]) => ({ name, count }))
        .sort((a, b) => b.count - a.count || ordinalCompare(a.name, b.name));

    const usersSnap = await tenantCollection("users").get();
    const allUsers = [];
    usersSnap.forEach((doc) => allUsers.push({ id: doc.id, ...doc.data() }));

    function candidatesFor(base) {
        const baseTokens = norm(base).split(/\s+/);
        return allUsers.filter((u) => {
            if (!u.name) return false;
            const userTokens = norm(u.name).split(/\s+/);
            if (baseTokens.length === 1) {
                return userTokens[0] === baseTokens[0];
            }
            if (userTokens[0] !== baseTokens[0]) return false;
            return isSubsequence(baseTokens, userTokens);
        });
    }

    const toSend = [];
    let notFoundCount = 0;
    let ambiguousCount = 0;
    let noTokenCount = 0;

    ranking.forEach((entry, idx) => {
        const position = idx + 1;

        if (MANUAL_USER_OVERRIDE[entry.name]) {
            const user = allUsers.find((u) => u.id === MANUAL_USER_OVERRIDE[entry.name]);
            if (user && user.fcmTokens && user.fcmTokens.length > 0) {
                toSend.push({ ...entry, position, userId: user.id, tokens: user.fcmTokens });
            } else if (user) {
                noTokenCount++;
            } else {
                notFoundCount++;
            }
            return;
        }

        const { base, nickname } = parseName(entry.name);
        let candidates = candidatesFor(base);

        if (candidates.length > 1 && nickname) {
            const byNickname = candidates.filter((u) => norm(u.name).includes(norm(nickname)));
            if (byNickname.length === 1) candidates = byNickname;
        }

        if (candidates.length === 0) {
            notFoundCount++;
            return;
        }
        if (candidates.length > 1) {
            ambiguousCount++;
            return;
        }
        const user = candidates[0];
        if (!user.fcmTokens || user.fcmTokens.length === 0) {
            noTokenCount++;
            return;
        }
        toSend.push({ ...entry, position, userId: user.id, tokens: user.fcmTokens });
    });

    if (!dryRun) {
        for (const entry of toSend) {
            const title = "🏆 Ranking de Faxina";
            const body = `Olá ${entry.name}! Você está na posição ${entry.position}º do ranking de faxina, com ${entry.count} presença${entry.count === 1 ? "" : "s"} confirmada${entry.count === 1 ? "" : "s"}.`;
            await db.collection("notifications_queue").add({
                tokens: entry.tokens,
                title,
                body,
                data: { type: "cleaning_ranking", position: String(entry.position), count: String(entry.count) },
                tenantId: TENANT_ID,
                env: ENV,
                status: "pending",
                createdAt: FieldValue.serverTimestamp(),
            });
        }
    }

    return {
        dryRun,
        totalRanking: ranking.length,
        queued: dryRun ? 0 : toSend.length,
        wouldQueue: toSend.length,
        notFound: notFoundCount,
        ambiguous: ambiguousCount,
        noToken: noTokenCount,
    };
}

module.exports = { computeAndQueueRanking };
