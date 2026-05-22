// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para as ofertas de compra e venda e sistema de matching.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";

// cancelar oferta
export const cancelOffer =onCall(async (request) =>{
    requireAuthenticatedUser(request);

    // fica mais facil pegar o orderId que não existe dentro da coleção orders
    // então precisa criar
    const orderId = request.data.orderId;
    const uid = request.auth!.uid;

    if(!orderId) throw new HttpsError("invalid-argument", "camp obrigatorio faltando");

    const ordToCanc = await db.collection("orders").doc(orderId).get();
    if(!ordToCanc) throw new HttpsError("not-found", "Ordem não encontrada");

});