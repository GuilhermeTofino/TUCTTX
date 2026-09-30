/**
 * Retenção dos comprovantes de mensalidade: cada arquivo vive na pasta do ano a
 * que se refere (`.../receipts/{ano}/{userId}/{requestId}`) e pode ser apagado
 * quando o ano acaba. Isolado do index.js para poder ser testado sem Firebase.
 */

/** Ano da pasta `receipts/{ano}/` de um caminho do Storage; null se não for comprovante. */
function receiptYearFromPath(filePath) {
    const match = /\/receipts\/(\d{4})\//.exec(`/${filePath}`);
    return match ? Number(match[1]) : null;
}

/** Expirado = comprovante de um ano anterior ao atual. O ano corrente nunca expira. */
function isExpiredReceipt(filePath, currentYear) {
    const year = receiptYearFromPath(filePath);
    return year !== null && year < currentYear;
}

module.exports = { receiptYearFromPath, isExpiredReceipt };
