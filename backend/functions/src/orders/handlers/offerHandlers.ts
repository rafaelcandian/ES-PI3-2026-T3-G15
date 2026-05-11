// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para as ofertas de compra e venda e sistema de matching.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";

// criar oferta
export const createOffer = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const {startupId, type, quantity, pricePerToken} = request.data;

  if (!startupId || !type || !quantity || !pricePerToken) {
    throw new HttpsError("invalid-argument", "campos obrigatorios faltando");
  }

  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError("invalid-argument", "quantidade e preço devem ser positivos");
  }

  const totalPrice = (quantity * pricePerToken);

  try {
    const userDoc = await db.collection("usuarios").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "usuario não encontrado");
    }

    const userData = userDoc.data();

    // valida saldo para compra
    if (type === "buy") {
      const saldo = userData!.saldo ?? 0;
      if (saldo < totalPrice) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente");
      }
    }

    if (type === "sell") {
      const tokens = userData!.tokens ?? {};
      const tokensStartup = tokens[startupId] ?? 0;
      if (tokensStartup < quantity) {
        throw new HttpsError("failed-precondition", "tokens insuficientes");
      }
    }

    // criar oferta
    const newOfferRef = await db.collection("orders").add({
      userId: uid,
      startupId,
      type,
      quantity,
      pricePerToken,
      totalPrice,
      status: "open",
      createdAt: admin.firestore.Timestamp.now(),
    });

    await tryMatching(newOfferRef.id, {
      userId: uid,
      startupId,
      type,
      quantity,
      pricePerToken,
    });

    return {sucess: true};
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", `Erro: ${e}`);
  }
});

// Matching
/*  Sempre que for criada uma oferta de compra, o sistema vai procurar se existe uma oferta de venda equivalente
    isso seria o matching, quando acontece varias operações acontecem, debitar saldo comprador, creditar saldo do vendedor
    transferir os tokens, trocar o status, etc. Se alguma operação falhar tudo precisa ser revertido para evitar problemas
*/

// função chamada depois de criar uma oferta
async function tryMatching(newOfferId: string, newOffer: any): Promise<void> { // garante que devolve um dado quando termina (no caso aqui não garante pq é void)
  const opositeType = newOffer.type === "buy" ? "sell" : "buy"; // ternario, se o tipo da nova oferta for "buy" ele vai voltar como sell, se não fica como buy
  const offerSnapshot = await db.collection("orders").where("startupId", "==", newOffer.startupId).where("type", "==", opositeType).where("status", "==", "open").orderBy("createdAt", "asc").get();

  if (offerSnapshot.empty) return;

  for (const offerDoc of offerSnapshot.docs) {
    const offer = offerDoc.data();

    // verifica compatibilidade do preço
    const compatiblePrice = newOffer.type === "buy" ? newOffer.pricePerToken >= offer.pricePerToken : newOffer.pricePerToken <= offer.pricePerToken;

    if (!compatiblePrice) continue; // se não for compativel ele continua (obviamente)

    const buyerId = newOffer.type === "buy" ? newOffer.userId : offer.userId; // ternario
    const sellerId = newOffer.type === "sell" ? newOffer.userId : offer.userId;
    const price = offer.pricePerToken;
    const quantity = Math.min(newOffer.quantity, offer.quantity); // vai retornar o menor valor entre os dois argumentos
    const total = quantity * price;

    await db.runTransaction(async (t) => { // vai transcrever os arquivos do firebase (collections e documents)
      const buyerRef = db.collection("usuarios").doc(buyerId);
      const sellerRef = db.collection("usuarios").doc(sellerId);
      const newOfferRef = db.collection("orders").doc(newOfferId);
      const offerRef = db.collection("orders").doc(offerDoc.id);

      const buyerDoc = await t.get(buyerRef);
      const sellerDoc = await t.get(sellerRef);

      const buyerTokens = buyerDoc.data()?.tokens ?? {};
      const sellerTokens = sellerDoc.data()?.tokens ?? {};

      // debitar saldo do comprador
      t.update(buyerRef, {
        saldo: admin.firestore.FieldValue.increment(-total),
      });

      // adicionar saldo do vendedor
      t.update(sellerRef, {
        saldo: admin.firestore.FieldValue.increment(total),
      });

      // remover tokens do vendedor
      // remover tokens do vendedor
      t.update(sellerRef, {
        [`tokens.${newOffer.startupId}`]: Math.max(
          0,
          (sellerTokens[newOffer.startupId] ?? 0) - quantity
        ),
      });

      // adicionar tokens do comprador
      t.update(buyerRef, {
        [`tokens.${newOffer.startupId}`]:
                    (buyerTokens[newOffer.startupId] ?? 0) + quantity,
      });

      // troca o status para filled
      t.update(newOfferRef, {status: "filled"});
      t.update(offerRef, {status: "filled"});

      // faz o registro da transação
      const regRef = db.collection("transactions").doc();
      t.set(regRef, {
        buyerId: buyerId,
        sellerId: sellerId,
        startupId: newOffer.startupId,
        quantity: quantity,
        pricePerToken: price,
        totalPrice: total,
        createdAt: admin.firestore.Timestamp.now(),
      });
    });
    break;
  }
}
