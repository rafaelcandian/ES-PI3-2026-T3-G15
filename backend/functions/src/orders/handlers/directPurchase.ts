// Autor: Gabriel Benevides Bosso
// RA: 24013653
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

  // VALIDAÇÃO 1: Verifica se os dados mínimos necessários para a compra foram enviados pelo cliente.
  // Isso evita que a função prossiga com dados corrompidos ou incompletos.
  if (!startupId || !quantity || !pricePerToken) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes.");
  }

  // VALIDAÇÃO 2: Garante que os valores numéricos de quantidade e preço sejam estritamente positivos.
  // Evita ataques de injeção de valores negativos que poderiam adulterar o saldo do usuário.
  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade e preço devem ser positivos.",
    );
  }

  const quantityInt = Math.floor(quantity);

  // CÁLCULO DE TAXA E TOTAIS:
  // 1. totalPrice: o valor base da compra sem taxas.
  // 2. fee: taxa administrativa da plataforma (0.4% do valor total).
  // 3. totalComTaxa: valor final que será descontado do saldo do usuário.
  const totalPrice = quantityInt * pricePerToken;
  const fee = totalPrice * 0.004;
  const totalComTaxa = totalPrice + fee;

  // TRANSAÇÃO ATÔMICA:
  // Utilizamos runTransaction para garantir que todas as leituras e escritas no Firestore 
  // ocorram de forma consistente. Se qualquer validação falhar no meio do processo 
  // (ex: saldo insuficiente detectado), todas as alterações são revertidas automaticamente, 
  // mantendo a integridade dos dados e evitando "condição de corrida".
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
    if (saldoAtual < totalComTaxa) {
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

    // DÉBITO DO COMPRADOR E ATUALIZAÇÃO DA CARTEIRA:
    // Deduz de forma atômica o valor total com taxas do saldo financeiro do usuário
    // e incrementa a respectiva quantidade de tokens recém-adquiridos.
    transaction.update(userRef, {
      saldo: FieldValue.increment(-totalComTaxa),
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

    // ATUALIZAÇÃO DE TOKENS DA STARTUP:
    // Subtrai os tokens recém-comprados do montante disponível na startup e, caso seja
    // o primeiro investimento do usuário nesta empresa, incrementa o contador de investidores.
    transaction.update(startupRef, startupUpdate);

    const transactionRef = db.collection("transactions").doc();
    transaction.set(transactionRef, {
      buyerId: uid,
      startupId,
      quantity: quantityInt,
      pricePerToken,
      totalPrice,
      fee,
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
      fee,
      totalPrice: totalComTaxa,
      amount: -totalComTaxa,
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
