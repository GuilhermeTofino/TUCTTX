/**
 * Interruptores por tenant, lidos de `settings/features` (Firestore).
 * Tudo que é novidade visível para os membros nasce DESLIGADO: a função pode estar
 * publicada e dormente até alguém ligar. Documento ou chave ausente = desligado.
 *
 * Chaves:
 *  - eventReminders      lembretes diários de véspera/dia (sendEventReminders)
 *  - presenceRemovedPush aviso aos admins quando alguém desmarca presença
 *  - feeReminders        lembretes de mensalidade: pré-vencimento e atraso (sendFeeReminders)
 */
const FEATURE_KEYS = ["eventReminders", "presenceRemovedPush", "feeReminders"];

/** Só `true` liga: qualquer outra coisa (ausente, "true", 1) mantém desligado. */
function isFeatureEnabled(settingsData, key) {
    if (!FEATURE_KEYS.includes(key)) throw new Error(`Interruptor desconhecido: ${key}`);
    return settingsData != null && settingsData[key] === true;
}

module.exports = { FEATURE_KEYS, isFeatureEnabled };
