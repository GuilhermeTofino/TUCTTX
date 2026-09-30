/**
 * Lembretes de eventos (véspera e dia). Lógica pura, sem Firebase, para testar.
 *
 * Os eventos guardam `date` como Timestamp (a hora está dentro dele). O dia de
 * São Paulo não usa horário de verão desde 2019, então UTC-3 fixo é exato.
 */
const SP_OFFSET_HOURS = 3; // America/Sao_Paulo = UTC-3

/** Partes (ano, mês, dia) da data de [date] no fuso de São Paulo. */
function saoPauloParts(date) {
    const shifted = new Date(date.getTime() - SP_OFFSET_HOURS * 3600 * 1000);
    return { y: shifted.getUTCFullYear(), m: shifted.getUTCMonth(), d: shifted.getUTCDate() };
}

/**
 * Janela [start, end) do dia de São Paulo que fica [offsetDays] dias depois de
 * [now]. `key` (YYYY-MM-DD) identifica o dia, usado como marca de "já enviado".
 */
function saoPauloDayWindow(now, offsetDays = 0) {
    const { y, m, d } = saoPauloParts(now);
    const startMs = Date.UTC(y, m, d + offsetDays, SP_OFFSET_HOURS, 0, 0);
    const start = new Date(startMs);
    const end = new Date(startMs + 24 * 3600 * 1000);
    const p = saoPauloParts(start);
    const pad = (n) => String(n).padStart(2, "0");
    return { start, end, key: `${p.y}-${pad(p.m + 1)}-${pad(p.d)}` };
}

/** "HH:mm" da hora do evento em São Paulo. */
function formatTimeSaoPaulo(date) {
    const shifted = new Date(date.getTime() - SP_OFFSET_HOURS * 3600 * 1000);
    const pad = (n) => String(n).padStart(2, "0");
    return `${pad(shifted.getUTCHours())}:${pad(shifted.getUTCMinutes())}`;
}

/** Monta o push. `type`: 'lembrete_vespera' | 'lembrete_dia'. */
function buildReminderPush({ type, event, eventId }) {
    const title = event.title || "Evento";
    const details = event.description ? `: ${event.description}` : "";
    const date = typeof event.date?.toDate === "function" ? event.date.toDate() : event.date;

    if (type === "lembrete_vespera") {
        return {
            title: `📅 Amanhã: ${title}`,
            body: `Amanhã tem ${title}${details}. Se prepare!`,
            data: { type, eventId: String(eventId), category: "event" },
        };
    }
    return {
        title: `🕯️ Hoje: ${title}`,
        body: `Hoje tem ${title} às ${formatTimeSaoPaulo(date)}${details}`,
        data: { type, eventId: String(eventId), category: "event" },
    };
}

/**
 * Tokens de quem recebe o lembrete: todo mundo que não é visitante; visitante só
 * se o evento for aberto a ele (`audience` inclui 'visitor'). Sem duplicados.
 */
function reminderTokens(users, event) {
    const visitorsAllowed = Array.isArray(event.audience) && event.audience.includes("visitor");
    const tokens = [];
    for (const user of users) {
        if (user.role === "visitor" && !visitorsAllowed) continue;
        if (Array.isArray(user.fcmTokens)) tokens.push(...user.fcmTokens);
    }
    return [...new Set(tokens)];
}

/** Divide em blocos (o FCM aceita até 500 tokens por envio). */
function chunk(list, size) {
    const out = [];
    for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
    return out;
}

module.exports = { saoPauloDayWindow, formatTimeSaoPaulo, buildReminderPush, reminderTokens, chunk };
