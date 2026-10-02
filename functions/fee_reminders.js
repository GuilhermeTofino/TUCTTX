/**
 * Lembretes de mensalidade (pré-vencimento e atraso). Lógica pura, sem Firebase.
 *
 * A mensalidade de um mês vence no dia FEE_DUE_DAY desse mesmo mês. O "hoje" vem
 * de São Paulo (ver event_reminders.js), não do fuso do servidor.
 */
const FEE_DUE_DAY = 10;
const PRE_DUE_DAYS = 3;        // aviso antecipado: faltam 3 dias
const OVERDUE_REPEAT_DAYS = 7; // quem segue em atraso é lembrado a cada 7 dias

const MONTH_NAMES = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
    "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];

const DAY_MS = 24 * 3600 * 1000;

/** Dias de [today] {y, m (1-12), d} até o vencimento de [fee]; negativo = vencida. */
function daysUntilDue(fee, today) {
    const due = Date.UTC(fee.year, fee.month - 1, FEE_DUE_DAY);
    return Math.round((due - Date.UTC(today.y, today.m - 1, today.d)) / DAY_MS);
}

/**
 * O que fazer com a mensalidade hoje:
 *  - 'pre_due'      pendente, faltam PRE_DUE_DAYS dias
 *  - 'due_today'    pendente, vence hoje
 *  - 'overdue_new'  pendente e já vencida: vira 'late' e avisa
 *  - 'overdue_again' já 'late' e o último aviso foi há OVERDUE_REPEAT_DAYS dias ou mais
 *  - null           nada (paga, ainda longe do vencimento, aviso recente)
 * [lastReminderAt]: Date do último aviso de atraso, se houver.
 */
function classifyFee(fee, today, lastReminderAt) {
    const days = daysUntilDue(fee, today);
    if (fee.status === "pending") {
        if (days === PRE_DUE_DAYS) return "pre_due";
        if (days === 0) return "due_today";
        if (days < 0) return "overdue_new";
        return null;
    }
    if (fee.status === "late" && days < 0) {
        if (!lastReminderAt) return "overdue_again";
        const todayMs = Date.UTC(today.y, today.m - 1, today.d);
        const sinceDays = Math.floor((todayMs - lastReminderAt.getTime()) / DAY_MS);
        return sinceDays >= OVERDUE_REPEAT_DAYS ? "overdue_again" : null;
    }
    return null;
}

function monthLabel(fee) {
    return `${MONTH_NAMES[fee.month - 1]}/${fee.year}`;
}

/**
 * Monta o push de um membro. [kind]: 'pre_due' | 'due_today' | 'overdue';
 * [fees]: as mensalidades envolvidas (várias só no atraso).
 */
function buildFeePush({ kind, fees, firstName }) {
    const data = { type: "finance_reminder", category: "fee", kind };
    if (kind === "pre_due") {
        return {
            title: "💰 Mensalidade vence em breve",
            body: `Olá ${firstName}! A mensalidade de ${monthLabel(fees[0])} vence em ${PRE_DUE_DAYS} dias (dia ${FEE_DUE_DAY}).`,
            data,
        };
    }
    if (kind === "due_today") {
        return {
            title: "💰 Mensalidade vence hoje",
            body: `Olá ${firstName}! A mensalidade de ${monthLabel(fees[0])} vence hoje.`,
            data,
        };
    }
    const body = fees.length === 1
        ? `Olá ${firstName}! A mensalidade de ${monthLabel(fees[0])} está em atraso.`
        : `Olá ${firstName}! Você tem ${fees.length} mensalidades em atraso (${fees.map(monthLabel).join(", ")}).`;
    return { title: "💰 Mensalidade em Atraso", body, data };
}

module.exports = {
    FEE_DUE_DAY, PRE_DUE_DAYS, OVERDUE_REPEAT_DAYS,
    daysUntilDue, classifyFee, monthLabel, buildFeePush,
};
