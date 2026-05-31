// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para as ofertas de compra e venda e sistema de matching.
/* Guilherme Henrique Moreira - 25006702 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";
import * as admin from "firebase-admin";

// cancelar oferta
export const cancelOffer =onCall(async (request) =>{
    requireAuthenticatedUser(request);

    // fica mais facil pegar o orderId que não existe dentro da coleção orders
    // então precisa criar
    const {orderId} = request.data;
    const uid = request.auth!.uid;

    // verifica se existe o orderId fornecido, em erro joga invalid argument
    if(!orderId) throw new HttpsError("invalid-argument", "Campo obrigatório faltando");

    try{
        // declara ordToCanc (ordem para cancelar) e espera o firestore para pegar as informações
        const ordToCanc = await db.collection("orders").doc(orderId).get();
        if(!ordToCanc) throw new HttpsError("not-found", "Ordem não encontrada"); // se não vier nada, não achou

        // pega os dados da ordem
        const orderData = ordToCanc.data()!; // garante que vai vir um não null (tratamento ali em cima)
        // se a ordem e o usuario que quis cancelar não tiverem o mesmo UID
        // a permissão vai ser negada
        if(orderData.userId !== uid) throw new HttpsError("permission-denied", "Usuario invalido");

        // verifica se o status não é open, se sim ele joga erro, no caso de ser open ele procede
        if(orderData.status !== "open") throw new HttpsError("failed-precondition", "Ordem não esta aberta");

        // atualiza o documento para cancelado
        await db.collection("orders").doc(orderId).update({status: "cancelled"});

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

        return {sucess: true};
    }catch(e){
        if(e instanceof HttpsError) throw e;
        throw new HttpsError("internal", `Erro: ${e}`);
    }
});