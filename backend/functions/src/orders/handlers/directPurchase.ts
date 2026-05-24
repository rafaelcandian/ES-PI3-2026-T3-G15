// Autor:
// RA:
// Descrição: Handler para processar a compra direta de tokens de uma startup.

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { DirectPurchaseData } from "../types/orderTypes";
import { registerWalletSnapshot } from "../../users/handlers/walletHandlers";

export const directPurchase = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  const data = request.data as DirectPurchaseData;
  const startupId = String(data.startupId ?? "").trim();
  const quantity = Number(data.quantity);
  const pricePerToken = Number(data.pricePerToken);

  if (!startupId || !quantity || !pricePerToken) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes.");
  }

  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade e preço devem ser positivos.",
    );
  }

  const quantityInt = Math.floor(quantity);
  const totalPrice = quantityInt * pricePerToken;

  await db.runTransaction(async (transaction) => {
    const userRef = db.collection("usuarios").doc(uid);
    const startupRef = db.collection("startups").doc(startupId);

    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const startupDoc = await transaction.get(startupRef);
    if (!startupDoc.exists) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    const saldoAtual = Number(userData.saldo || 0);
    if (saldoAtual < totalPrice) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    const minBuyPrice = Number(
      startupData.minBuyPrice ??
        startupData.tokenValue ??
        startupData.valorToken ??
        1,
    );

    if (pricePerToken < minBuyPrice) {
      throw new HttpsError(
        "failed-precondition",
        `Preço mínimo de compra: R$ ${minBuyPrice.toFixed(2)}.`,
      );
    }

    const tokensDisponiveis = Number(startupData.tokens || 0);
    if (tokensDisponiveis < quantityInt) {
      throw new HttpsError(
        "failed-precondition",
        "Tokens insuficientes na startup.",
      );
    }

    const tokensAtuais = userData.tokens || {};
    const atual = Number(tokensAtuais[startupId] || 0);

    transaction.update(userRef, {
      saldo: FieldValue.increment(-totalPrice),
      [`tokens.${startupId}`]: FieldValue.increment(quantityInt),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const startupUpdate: Record<string, unknown> = {
      tokens: FieldValue.increment(-quantityInt),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (atual === 0) {
      startupUpdate.investorsCount = FieldValue.increment(1);
    }

    transaction.update(startupRef, startupUpdate);

    const transactionRef = db.collection("transactions").doc();
    transaction.set(transactionRef, {
      buyerId: uid,
      startupId,
      quantity: quantityInt,
      pricePerToken,
      totalPrice,
      type: "direct",
      createdAt: Timestamp.now(),
    });

    const startupName = startupData.title ?? startupData.nome ?? "Startup";
    const ticker = startupData.ticker ?? startupData.simbolo ?? "";

    const walletTransactionRef = userRef.collection("transacoesCarteira").doc();
    transaction.set(walletTransactionRef, {
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
      method: "direct_purchase",
      source: "startup",
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  await registerWalletSnapshot(uid, "purchase");

  return {
    message: "Compra realizada com sucesso!",
    tokensAdquiridos: quantityInt,
    totalPago: totalPrice,
  };
});
