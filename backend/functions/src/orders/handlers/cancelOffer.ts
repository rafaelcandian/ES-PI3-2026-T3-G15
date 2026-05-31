// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para as ofertas de compra e venda e sistema de matching.
/* Guilherme Henrique Moreira - 25006702 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import * as admin from "firebase-admin";

// cancelar oferta
export const cancelOffer = onCall(async (request) => {
    requireAuthenticatedUser(request);

    // fica mais facil pegar o orderId que não existe dentro da coleção orders
    // então precisa criar
    const { orderId } = request.data;
    const uid = request.auth!.uid;

    // VALIDAÇÃO DE PARÂMETROS:
    // Verifica se o identificador da ordem (orderId) foi devidamente fornecido na requisição.
    // Esta etapa é crucial para evitar consultas inválidas ou nulas no banco de dados.
    if (!orderId) throw new HttpsError("invalid-argument", "Campo obrigatório faltando");

    try {
        // declara ordToCanc (ordem para cancelar) e espera o firestore para pegar as informações
        const ordToCanc = await db.collection("orders").doc(orderId).get();
        if (!ordToCanc) throw new HttpsError("not-found", "Ordem não encontrada"); // se não vier nada, não achou

        // pega os dados da ordem
        const orderData = ordToCanc.data()!; // garante que vai vir um não null (tratamento ali em cima)
        // VALIDAÇÃO DE PERMISSÃO:
        // Assegura que o usuário que está solicitando o cancelamento seja estritamente o criador da ordem.
        // Garante a segurança e a integridade, prevenindo alterações não autorizadas por terceiros.
        if (orderData.userId !== uid) throw new HttpsError("permission-denied", "Usuario invalido");

        // verifica se o status não é open, se sim ele joga erro, no caso de ser open ele procede
        if (orderData.status !== "open") throw new HttpsError("failed-precondition", "Ordem não esta aberta");

        // ATUALIZAÇÃO DE STATUS:
        // Modifica o estado da ordem no banco de dados para "cancelled" (cancelada).
        // Isso remove a ordem das listagens ativas e impede futuras execuções ou interações de matching.
        await db.collection("orders").doc(orderId).update({ status: "cancelled" });

        // REGISTRO DE TRANSAÇÃO (HISTÓRICO):
        // Cria um registro imutável na coleção "transactions" denotando o cancelamento da ordem.
        // Este registro serve para auditoria, rastreabilidade e histórico de atividades do usuário e da startup.
        await db.collection("transactions").add({
            userId: uid,
            orderId: orderId,
            startupId: orderData.startupId,
            type: "cancelled", // cria o type cancelled 
            quantity: orderData.quantity,
            pricePerToken: orderData.pricePerToken,
            totalPrice: orderData.totalPrice,
            orderType: orderData.type, // mostra "buy" ou "sell" do tipo de ordem foi cancelada
            createdAt: admin.firestore.Timestamp.now(),
        });

        return { sucess: true };
    } catch (e) {
        if (e instanceof HttpsError) throw e;
        throw new HttpsError("internal", `Erro: ${e}`);
    }
});