// Autor: 
// RA: 
// Descrição: Handler para processar a compra direta de tokens de uma startup.

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { DirectPurchaseData } from "../types/orderTypes";

export const directPurchase = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  const data = request.data as DirectPurchaseData;
  const { startupId, quantity, pricePerToken } = data;

  if (!startupId || quantity === undefined || pricePerToken === undefined) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes.");
  }

  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError("invalid-argument", "Quantidade e preço devem ser positivos.");
  }

  const totalPrice = quantity * pricePerToken;

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

    const saldoAtual = userData.saldo || 0;
    if (saldoAtual < totalPrice) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    const tokensDisponiveis = startupData.tokens || 0;
    if (tokensDisponiveis < quantity) {
      throw new HttpsError("failed-precondition", "Tokens insuficientes na startup.");
    }

    const tokensAtuais = userData.tokens || {};
    const atual = tokensAtuais[startupId] || 0;
    const novoSaldo = saldoAtual - totalPrice;

    // Debita saldo e credita tokens
    const userUpdate: Record<string, any> = {
      saldo: FieldValue.increment(-totalPrice),
      [`tokens.${startupId}`]: FieldValue.increment(quantity),
    };
    transaction.update(userRef, userUpdate);

    // Decrementa tokens da startup
    const startupUpdate: Record<string, any> = {
      tokens: FieldValue.increment(-quantity),
    };

    // Incrementa investorsCount se for primeiro aporte
    if (atual === 0) {
      startupUpdate.investorsCount = FieldValue.increment(1);
    }
    transaction.update(startupRef, startupUpdate);

    // Registra transação
    const transactionRef = db.collection("transactions").doc();
    transaction.set(transactionRef, {
      buyerId: uid,
      startupId,
      quantity,
      pricePerToken,
      totalPrice,
      type: "direct",
      createdAt: Timestamp.now(),
    });

    // Salva snapshot em patrimonioHistorico
    const novosTokens = { ...tokensAtuais, [startupId]: atual + quantity };
    
    // Cálculo simplificado de valor de ativos para o histórico
    let valorAtivos = 0;
    for (const [sId, qty] of Object.entries(novosTokens)) {
      if (sId === startupId) {
        valorAtivos += (qty as number) * (startupData.tokenValue || pricePerToken);
      } else {
        // Usa o pricePerToken atual como fallback simples 
        valorAtivos += (qty as number) * pricePerToken;
      }
    }

    const historyRef = userRef.collection("patrimonioHistorico").doc();
    transaction.set(historyRef, {
      valor: novoSaldo + valorAtivos,
      saldo: novoSaldo,
      valorAtivos: valorAtivos,
      eventType: "purchase",
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return {
    message: "Compra realizada com sucesso!",
    tokensAdquiridos: quantity,
    totalPago: totalPrice,
  };
});
