// Autor:
// RA:
// Descrição: Executa a compra direta de uma oferta específica do balcão.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";
import {registerWalletSnapshot} from "../../users/handlers/walletHandlers";

export const executeSellOffer = onCall(async (request) => {
  requireAuthenticatedUser(request);

  console.log('executeSellOffer chamado:', {
    uid: request.auth?.uid,
    data: request.data,
    orderId: request.data?.orderId,
    quantity: request.data?.quantity,
  });


  const buyerId = request.auth!.uid;
  const orderId = String(request.data?.orderId ?? "").trim();
  const quantity = Number(request.data?.quantity ?? 0);

  if (!orderId || quantity <= 0) {
    throw new HttpsError("invalid-argument", "Dados da compra inválidos.");
  }

  const quantityInt = Math.floor(quantity);

  await db.runTransaction(async (transaction) => {
    const orderRef = db.collection("orders").doc(orderId);
    const orderDoc = await transaction.get(orderRef);

    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    const orderData = orderDoc.data()!;

    if (orderData.status !== "open") {
      throw new HttpsError("failed-precondition", "Oferta não está disponível.");
    }

    if (orderData.type !== "sell") {
      throw new HttpsError(
        "failed-precondition",
        "A oferta selecionada não é de venda.",
      );
    }

    const sellerId = String(orderData.userId ?? "");
    const startupId = String(orderData.startupId ?? "");

    if (sellerId === buyerId) {
      throw new HttpsError(
        "failed-precondition",
        "Você não pode comprar sua própria oferta.",
      );
    }

    const availableQuantity = Number(orderData.quantity ?? 0);

    if (availableQuantity < quantityInt) {
      throw new HttpsError(
        "failed-precondition",
        `A oferta possui apenas ${availableQuantity} tokens disponíveis.`,
      );
    }

    const pricePerToken = Number(orderData.pricePerToken ?? 0);
    const totalPrice = quantityInt * pricePerToken;

    const buyerRef = db.collection("usuarios").doc(buyerId);
    const sellerRef = db.collection("usuarios").doc(sellerId);
    const startupRef = db.collection("startups").doc(startupId);

    const buyerDoc = await transaction.get(buyerRef);
    const sellerDoc = await transaction.get(sellerRef);
    const startupDoc = await transaction.get(startupRef);

    if (!buyerDoc.exists) {
      throw new HttpsError("not-found", "Comprador não encontrado.");
    }

    if (!sellerDoc.exists) {
      throw new HttpsError("not-found", "Vendedor não encontrado.");
    }

    const buyerData = buyerDoc.data()!;
    const sellerData = sellerDoc.data()!;
    const startupData = startupDoc.exists ? startupDoc.data()! : {};

    const saldoAtual = Number(buyerData.saldo ?? 0);
    const sellerTokens = sellerData.tokens ?? {};
    const sellerTokensStartup = Number(sellerTokens[startupId] ?? 0);

    if (saldoAtual < totalPrice) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    if (sellerTokensStartup < quantityInt) {
      throw new HttpsError(
        "failed-precondition",
        "O vendedor não possui tokens suficientes.",
      );
    }

    transaction.update(buyerRef, {
      saldo: admin.firestore.FieldValue.increment(-totalPrice),
      [`tokens.${startupId}`]:
        admin.firestore.FieldValue.increment(quantityInt),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(sellerRef, {
      saldo: admin.firestore.FieldValue.increment(totalPrice),
      [`tokens.${startupId}`]:
        admin.firestore.FieldValue.increment(-quantityInt),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const remainingQuantity = availableQuantity - quantityInt;

    transaction.update(orderRef, {
      quantity: remainingQuantity,
      remainingQuantity,
      filledQuantity: admin.firestore.FieldValue.increment(quantityInt),
      totalPrice: remainingQuantity * pricePerToken,
      status: remainingQuantity <= 0 ? "filled" : "open",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const startupName = startupData.title ?? startupData.nome ?? "Startup";
    const ticker = startupData.ticker ?? startupData.simbolo ?? "";

    transaction.set(db.collection("transactions").doc(), {
      buyerId,
      sellerId,
      startupId,
      quantity: quantityInt,
      pricePerToken,
      totalPrice,
      type: "balcao",
      createdAt: admin.firestore.Timestamp.now(),
    });

    transaction.set(buyerRef.collection("transacoesCarteira").doc(), {
      type: "purchase",
      operationType: "compra",
      status: "completed",
      startupId,
      startupName,
      ticker,
      quantity: quantityInt,
      pricePerToken,
      subtotal: totalPrice,
      fee: 0,
      totalPrice,
      amount: -totalPrice,
      description: `Compra de ${quantityInt} tokens de ${startupName}`,
      method: "balcao_trade",
      source: "balcao",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(sellerRef.collection("transacoesCarteira").doc(), {
      type: "sale",
      operationType: "venda",
      status: "completed",
      startupId,
      startupName,
      ticker,
      quantity: quantityInt,
      pricePerToken,
      subtotal: totalPrice,
      fee: 0,
      totalPrice,
      amount: totalPrice,
      description: `Venda de ${quantityInt} tokens de ${startupName}`,
      method: "balcao_trade",
      source: "balcao",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await registerWalletSnapshot(buyerId, "purchase");

  return {
    success: true,
    message: "Compra realizada com sucesso.",
  };
});