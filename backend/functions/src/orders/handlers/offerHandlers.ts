// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para ofertas de compra/venda e matching seguro do balcão.

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { registerWalletSnapshot } from "../../users/handlers/walletHandlers";

type OfferType = "buy" | "sell";

type OpenOrder = {
  userId: string;
  startupId: string;
  type: OfferType;
  quantity: number;
  pricePerToken: number;
};

function toPositiveNumber(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

async function getReservedBuyTotal(userId: string): Promise<number> {
  const snapshot = await db
    .collection("orders")
    .where("userId", "==", userId)
    .where("type", "==", "buy")
    .where("status", "==", "open")
    .get();

  return snapshot.docs.reduce((total, doc) => {
    const data = doc.data();
    return total + toPositiveNumber(data.totalPrice);
  }, 0);
}

async function getReservedSellQuantity(
  userId: string,
  startupId: string,
): Promise<number> {
  const snapshot = await db
    .collection("orders")
    .where("userId", "==", userId)
    .where("startupId", "==", startupId)
    .where("type", "==", "sell")
    .where("status", "==", "open")
    .get();

  return snapshot.docs.reduce((total, doc) => {
    const data = doc.data();
    return total + toPositiveNumber(data.quantity);
  }, 0);
}

export const createOffer = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const startupId = String(request.data?.startupId ?? "").trim();
  const type = String(request.data?.type ?? "") as OfferType;
  const quantity = toPositiveNumber(request.data?.quantity);
  const pricePerToken = toPositiveNumber(request.data?.pricePerToken);

  if (!startupId || !type || !quantity || !pricePerToken) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios faltando.");
  }

  if (type !== "buy" && type !== "sell") {
    throw new HttpsError("invalid-argument", "Tipo de ordem inválido.");
  }

  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade e preço devem ser positivos.",
    );
  }

  const quantityInt = Math.floor(quantity);

  if (quantityInt <= 0) {
    throw new HttpsError("invalid-argument", "Quantidade inválida.");
  }

  const totalPrice = quantityInt * pricePerToken;

  try {
    const userDoc = await db.collection("usuarios").doc(uid).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const startupDoc = await db.collection("startups").doc(startupId).get();

    if (!startupDoc.exists) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    if (type === "buy") {
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

      const saldo = Number(userData.saldo ?? 0);
      const reservado = await getReservedBuyTotal(uid);
      const disponivel = saldo - reservado;

      if (disponivel < totalPrice) {
        throw new HttpsError(
          "failed-precondition",
          `Saldo insuficiente. Disponível considerando ordens abertas: R$ ${disponivel.toFixed(2)}.`,
        );
      }
    }

    if (type === "sell") {
      const tokens = userData.tokens ?? {};
      const tokensStartup = Number(tokens[startupId] ?? 0);
      const reservado = await getReservedSellQuantity(uid, startupId);
      const disponivel = tokensStartup - reservado;

      if (disponivel < quantityInt) {
        throw new HttpsError(
          "failed-precondition",
          `Tokens insuficientes. Disponível considerando ordens abertas: ${disponivel} tokens.`,
        );
      }
    }

    const newOfferRef = await db.collection("orders").add({
      userId: uid,
      startupId,
      type,
      quantity: quantityInt,
      originalQuantity: quantityInt,
      pricePerToken,
      totalPrice,
      status: "open",
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      await tryMatching(newOfferRef.id, {
        userId: uid,
        startupId,
        type,
        quantity: quantityInt,
        pricePerToken,
      });
    } catch (matchingError) {
      console.warn("Matching ignorado após criação da ordem:", matchingError);
    }

    return { success: true };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", `Erro: ${e}`);
  }
});

async function tryMatching(
  newOfferId: string,
  newOffer: OpenOrder,
): Promise<void> {
  const oppositeType: OfferType = newOffer.type === "buy" ? "sell" : "buy";

  const offerSnapshot = await db
    .collection("orders")
    .where("startupId", "==", newOffer.startupId)
    .where("type", "==", oppositeType)
    .where("status", "==", "open")
    .orderBy("createdAt", "asc")
    .get();

  if (offerSnapshot.empty) return;

  let remainingNewQuantity = newOffer.quantity;

  for (const offerDoc of offerSnapshot.docs) {
    if (remainingNewQuantity <= 0) break;

    const offer = offerDoc.data();

    if (offer.userId === newOffer.userId) {
      continue;
    }

    const offerQuantity = Number(offer.quantity ?? 0);

    if (offerQuantity <= 0) continue;

    const compatiblePrice =
      newOffer.type === "buy"
        ? newOffer.pricePerToken >= Number(offer.pricePerToken)
        : newOffer.pricePerToken <= Number(offer.pricePerToken);

    if (!compatiblePrice) continue;

    const buyerId = newOffer.type === "buy" ? newOffer.userId : offer.userId;
    const sellerId = newOffer.type === "sell" ? newOffer.userId : offer.userId;
    const price = Number(offer.pricePerToken);
    const matchedQuantity = Math.min(remainingNewQuantity, offerQuantity);
    
    const FEE_RATE = 0.004;
    const totalBruto = matchedQuantity * price;
    const fee = totalBruto * FEE_RATE;
    const totalComprador = totalBruto + fee;
    const totalVendedor = totalBruto - fee;
    
    const remainingExistingQuantity = offerQuantity - matchedQuantity;
    const remainingAfterNew = remainingNewQuantity - matchedQuantity;

    await db.runTransaction(async (t) => {
      const buyerRef = db.collection("usuarios").doc(buyerId);
      const sellerRef = db.collection("usuarios").doc(sellerId);
      const newOfferRef = db.collection("orders").doc(newOfferId);
      const offerRef = db.collection("orders").doc(offerDoc.id);
      const startupRef = db.collection("startups").doc(newOffer.startupId);

      const buyerDoc = await t.get(buyerRef);
      const sellerDoc = await t.get(sellerRef);
      const startupDoc = await t.get(startupRef);
      const newOfferDoc = await t.get(newOfferRef);
      const existingOfferDoc = await t.get(offerRef);

      if (!buyerDoc.exists) {
        const invalidBuyOrderRef =
          newOffer.type === "buy" ? newOfferRef : offerRef;

        t.update(invalidBuyOrderRef, {
          status: "cancelled",
          cancelReason: "Comprador não encontrado.",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return;
      }

      if (!sellerDoc.exists) {
        const invalidSellOrderRef =
          newOffer.type === "sell" ? newOfferRef : offerRef;

        t.update(invalidSellOrderRef, {
          status: "cancelled",
          cancelReason: "Vendedor não encontrado.",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return;
      }

      if (!newOfferDoc.exists || !existingOfferDoc.exists) {
        throw new HttpsError("not-found", "Ordem não encontrada.");
      }

      const buyerData = buyerDoc.data()!;
      const sellerData = sellerDoc.data()!;
      const startupData = startupDoc.exists ? startupDoc.data()! : {};

      const buyerSaldo = Number(buyerData.saldo ?? 0);
      const sellerTokens = sellerData.tokens ?? {};
      const sellerTokensStartup = Number(sellerTokens[newOffer.startupId] ?? 0);

      if (buyerSaldo < totalComprador) {
        if (newOffer.type === "sell") {
          t.update(offerRef, {
            status: "cancelled",
            cancelReason: "Saldo insuficiente do comprador.",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          return;
        }

        throw new HttpsError(
          "failed-precondition",
          "Saldo insuficiente do comprador.",
        );
      }

      if (sellerTokensStartup < matchedQuantity) {
        if (newOffer.type === "buy") {
          t.update(offerRef, {
            status: "cancelled",
            cancelReason: "Tokens insuficientes do vendedor.",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          return;
        }

        throw new HttpsError(
          "failed-precondition",
          "Tokens insuficientes do vendedor.",
        );
      }

      t.set(buyerRef, {
        tokens: {
          [newOffer.startupId]: admin.firestore.FieldValue.increment(matchedQuantity)
        }
      }, { merge: true });

      t.update(buyerRef, {
        saldo: admin.firestore.FieldValue.increment(-totalComprador),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      t.update(sellerRef, {
        saldo: admin.firestore.FieldValue.increment(totalVendedor),
        [`tokens.${newOffer.startupId}`]:
          admin.firestore.FieldValue.increment(-matchedQuantity),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      t.update(newOfferRef, {
        quantity: remainingAfterNew,
        remainingQuantity: remainingAfterNew,
        filledQuantity: admin.firestore.FieldValue.increment(
          matchedQuantity,
        ),
        totalPrice: remainingAfterNew * newOffer.pricePerToken,
        status: remainingAfterNew <= 0 ? "filled" : "open",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      t.update(offerRef, {
        quantity: remainingExistingQuantity,
        remainingQuantity: remainingExistingQuantity,
        filledQuantity: admin.firestore.FieldValue.increment(
          matchedQuantity,
        ),
        totalPrice:
          remainingExistingQuantity * Number(offer.pricePerToken),
        status: remainingExistingQuantity <= 0 ? "filled" : "open",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const regRef = db.collection("transactions").doc();
      t.set(regRef, {
        buyerId,
        sellerId,
        startupId: newOffer.startupId,
        quantity: matchedQuantity,
        pricePerToken: price,
        totalPrice: totalBruto,
        fee: fee,
        type: "balcao",
        createdAt: admin.firestore.Timestamp.now(),
      });

      const startupName = startupData.title ?? startupData.nome ?? "Startup";
      const ticker = startupData.ticker ?? startupData.simbolo ?? "";

      const buyerWalletRef = buyerRef.collection("transacoesCarteira").doc();
      t.set(buyerWalletRef, {
        type: "purchase",
        operationType: "compra",
        status: "completed",
        startupId: newOffer.startupId,
        startupName,
        ticker,
        quantity: matchedQuantity,
        pricePerToken: price,
        subtotal: totalBruto,
        fee: fee,
        totalPrice: totalComprador,
        amount: -totalComprador,
        description: `Compra de ${matchedQuantity} tokens de ${startupName}`,
        method: "balcao_trade",
        source: "balcao",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const sellerWalletRef = sellerRef.collection("transacoesCarteira").doc();
      t.set(sellerWalletRef, {
        type: "sale",
        operationType: "venda",
        status: "completed",
        startupId: newOffer.startupId,
        startupName,
        ticker,
        quantity: matchedQuantity,
        pricePerToken: price,
        subtotal: totalBruto,
        fee: fee,
        totalPrice: totalVendedor,
        amount: totalVendedor,
        description: `Venda de ${matchedQuantity} tokens de ${startupName}`,
        method: "balcao_trade",
        source: "balcao",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    remainingNewQuantity = remainingAfterNew;

    await Promise.all([
      registerWalletSnapshot(buyerId, "purchase"),
      registerWalletSnapshot(sellerId, "sale"),
    ]);
  }
}
