// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para ofertas de compra/venda e matching seguro do balcão.
/* Guilherme Henrique Moreira - 25006702 */

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Este arquivo é o núcleo do sistema de balcão (order book) da plataforma.
// Contém duas Cloud Functions principais:
//   1. createOffer: permite que usuários criem ofertas de compra ("buy") ou
//      venda ("sell") de tokens de uma startup no mercado secundário.
//   2. tryMatching (interna): tenta encontrar e casar automaticamente ofertas
//      opostas compatíveis logo após a criação de uma nova ordem, executando
//      a transferência de tokens e saldo de forma atômica (ACID).
// =============================================================================

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { registerWalletSnapshot } from "../../users/handlers/walletHandlers";

// TIPO DE OFERTA:
// Define os dois únicos tipos de ordem aceitos pelo sistema do balcão.
type OfferType = "buy" | "sell";

// TIPO DE ORDEM ABERTA (OpenOrder):
// Estrutura interna usada para passar os dados de uma nova ordem
// para a função de matching sem precisar re-ler o documento do Firestore.
type OpenOrder = {
  userId: string;
  startupId: string;
  type: OfferType;
  quantity: number;
  pricePerToken: number;
};

// FUNÇÃO AUXILIAR: toPositiveNumber
// Converte qualquer valor desconhecido (unknown) para um número finito positivo.
// Retorna 0 caso a conversão resulte em NaN ou Infinity, evitando cálculos inválidos.
function toPositiveNumber(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

// FUNÇÃO AUXILIAR: getReservedBuyTotal
// Calcula o total de saldo já comprometido (reservado) em ordens de compra abertas
// de um usuário. Esse valor é descontado do saldo disponível ao criar uma nova
// oferta de compra, evitando que o usuário use o mesmo saldo duas vezes.
async function getReservedBuyTotal(userId: string): Promise<number> {
  // CONSULTA NO FIRESTORE:
  // Busca todas as ordens de compra ("buy") com status "open" do usuário.
  const snapshot = await db
    .collection("orders")
    .where("userId", "==", userId)
    .where("type", "==", "buy")
    .where("status", "==", "open")
    .get();

  // SOMA DOS TOTAIS RESERVADOS:
  // Acumula o totalPrice de cada ordem aberta para obter o valor total bloqueado.
  return snapshot.docs.reduce((total, doc) => {
    const data = doc.data();
    return total + toPositiveNumber(data.totalPrice);
  }, 0);
}

// FUNÇÃO AUXILIAR: getReservedSellQuantity
// Calcula a quantidade de tokens já comprometida (reservada) em ordens de venda
// abertas de um usuário para uma startup específica. Assim, o usuário não pode
// criar mais ofertas de venda do que a quantidade de tokens que possui disponível.
async function getReservedSellQuantity(
  userId: string,
  startupId: string,
): Promise<number> {
  // CONSULTA NO FIRESTORE:
  // Filtra apenas as ordens de venda ("sell") abertas daquele usuário para aquela startup.
  const snapshot = await db
    .collection("orders")
    .where("userId", "==", userId)
    .where("startupId", "==", startupId)
    .where("type", "==", "sell")
    .where("status", "==", "open")
    .get();

  // SOMA DAS QUANTIDADES RESERVADAS:
  // Soma a quantidade de tokens de cada ordem aberta.
  return snapshot.docs.reduce((total, doc) => {
    const data = doc.data();
    return total + toPositiveNumber(data.quantity);
  }, 0);
}

// FUNÇÃO PRINCIPAL: createOffer
// Permite que um usuário autenticado crie uma nova oferta de compra ou venda
// de tokens no mercado secundário (balcão). Após criar a oferta no Firestore,
// tenta realizar o matching automático com ofertas opostas existentes.
export const createOffer = onCall(async (request) => {
  // VERIFICAÇÃO DE AUTENTICAÇÃO:
  // Garante que apenas usuários logados podem criar ofertas.
  requireAuthenticatedUser(request);

  // EXTRAÇÃO DOS PARÂMETROS DA REQUISIÇÃO:
  // Converte e normaliza os dados enviados pelo cliente.
  const uid = request.auth!.uid;
  const startupId = String(request.data?.startupId ?? "").trim();
  const type = String(request.data?.type ?? "") as OfferType;
  const quantity = toPositiveNumber(request.data?.quantity);
  const pricePerToken = toPositiveNumber(request.data?.pricePerToken);

  // VALIDAÇÃO DE CAMPOS OBRIGATÓRIOS:
  // Todos os campos são necessários para criar uma oferta válida.
  if (!startupId || !type || !quantity || !pricePerToken) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios faltando.");
  }

  // VALIDAÇÃO DO TIPO DE ORDEM:
  // Apenas "buy" (compra) e "sell" (venda) são aceitos.
  if (type !== "buy" && type !== "sell") {
    throw new HttpsError("invalid-argument", "Tipo de ordem inválido.");
  }

  // VALIDAÇÃO DE VALORES POSITIVOS:
  // Garante que quantidade e preço sejam números estritamente positivos.
  if (quantity <= 0 || pricePerToken <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade e preço devem ser positivos.",
    );
  }

  // NORMALIZAÇÃO PARA INTEIRO:
  // Tokens são indivisíveis; Math.floor garante apenas quantidades inteiras.
  const quantityInt = Math.floor(quantity);

  if (quantityInt <= 0) {
    throw new HttpsError("invalid-argument", "Quantidade inválida.");
  }

  // CÁLCULO DO TOTAL DA OFERTA:
  // Valor total que a oferta representa (quantidade * preço unitário).
  const totalPrice = quantityInt * pricePerToken;

  try {
    // LEITURA DO USUÁRIO:
    // Verifica se o usuário existe e obtém seus dados (saldo e tokens).
    const userDoc = await db.collection("usuarios").doc(uid).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    // LEITURA DA STARTUP:
    // Verifica se a startup existe e obtém seus dados (preço mínimo etc.).
    const startupDoc = await db.collection("startups").doc(startupId).get();

    if (!startupDoc.exists) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    const userData = userDoc.data()!;
    const startupData = startupDoc.data()!;

    // VALIDAÇÃO PARA OFERTAS DE COMPRA (BUY):
    // Verifica se o preço ofertado respeita o mínimo da plataforma e
    // se o saldo disponível (descontando reservas de ordens abertas) é suficiente.
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

      // SALDO DISPONÍVEL REAL:
      // Desconta o total já comprometido em outras ordens de compra abertas.
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

    // VALIDAÇÃO PARA OFERTAS DE VENDA (SELL):
    // Verifica se o usuário possui tokens suficientes disponíveis,
    // descontando tokens já comprometidos em outras ordens de venda abertas.
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

    // CRIAÇÃO DA OFERTA NO FIRESTORE:
    // Insere o documento da nova ordem na coleção "orders" com status "open".
    // originalQuantity guarda a quantidade inicial para fins de histórico e relatórios.
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

    // TENTATIVA DE MATCHING AUTOMÁTICO:
    // Após criar a ordem, tenta casar automaticamente com ofertas opostas existentes.
    // Se o matching falhar por qualquer razão, o erro é apenas logado como aviso
    // (warn) e a oferta permanece aberta para ser casada manualmente ou depois.
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
    // TRATAMENTO DE ERROS:
    // Re-propaga erros já formatados (HttpsError) ou encapsula erros genéricos.
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", `Erro: ${e}`);
  }
});

// FUNÇÃO INTERNA: tryMatching
// Algoritmo de matching do balcão: percorre as ordens opostas abertas para a
// mesma startup, em ordem cronológica (FIFO - First In, First Out), e tenta
// casar (match) a nova ordem com as existentes que tenham preço compatível.
// Cada par casado executa a transferência de tokens e saldo dentro de uma
// transação atômica separada, garantindo consistência.
async function tryMatching(
  newOfferId: string,
  newOffer: OpenOrder,
): Promise<void> {
  // DETERMINAÇÃO DO TIPO OPOSTO:
  // Se a nova oferta é de compra ("buy"), procura por ofertas de venda ("sell") e vice-versa.
  const oppositeType: OfferType = newOffer.type === "buy" ? "sell" : "buy";

  // BUSCA DE OFERTAS OPOSTAS ABERTAS:
  // Consulta no Firestore as ordens do tipo oposto para a mesma startup,
  // com status "open", ordenadas por data de criação (mais antigas primeiro - FIFO).
  const offerSnapshot = await db
    .collection("orders")
    .where("startupId", "==", newOffer.startupId)
    .where("type", "==", oppositeType)
    .where("status", "==", "open")
    .orderBy("createdAt", "asc")
    .get();

  // Se não houver ofertas opostas, encerra sem fazer nada.
  if (offerSnapshot.empty) return;

  // Quantidade restante da nova oferta a ser casada. Diminui a cada match bem-sucedido.
  let remainingNewQuantity = newOffer.quantity;

  // ITERAÇÃO SOBRE OFERTAS OPOSTAS:
  // Para cada oferta oposta candidata, verifica compatibilidade de preço e executa o match.
  for (const offerDoc of offerSnapshot.docs) {
    // Para quando toda a nova oferta já foi casada.
    if (remainingNewQuantity <= 0) break;

    const offer = offerDoc.data();

    // PREVENÇÃO DE AUTO-NEGOCIAÇÃO:
    // Um usuário não pode casar uma oferta com outra do próprio usuário.
    if (offer.userId === newOffer.userId) {
      continue;
    }

    const offerQuantity = Number(offer.quantity ?? 0);

    // Pula ofertas sem quantidade disponível.
    if (offerQuantity <= 0) continue;

    // VERIFICAÇÃO DE COMPATIBILIDADE DE PREÇO:
    // Para compra (buy): o preço ofertado pelo comprador deve ser >= preço do vendedor.
    // Para venda (sell): o preço ofertado pelo vendedor deve ser <= preço do comprador.
    // O preço final do negócio é sempre o da oferta existente (a mais antiga no livro).
    const compatiblePrice =
      newOffer.type === "buy"
        ? newOffer.pricePerToken >= Number(offer.pricePerToken)
        : newOffer.pricePerToken <= Number(offer.pricePerToken);

    if (!compatiblePrice) continue;

    // IDENTIFICAÇÃO DE COMPRADOR E VENDEDOR:
    // Determina quem é o comprador e quem é o vendedor com base no tipo da nova oferta.
    const buyerId = newOffer.type === "buy" ? newOffer.userId : offer.userId;
    const sellerId = newOffer.type === "sell" ? newOffer.userId : offer.userId;

    // PREÇO DO NEGÓCIO (PRICE DISCOVERY):
    // O preço usado é sempre o da oferta existente (a ordem mais antiga no livro de ordens).
    const price = Number(offer.pricePerToken);

    // QUANTIDADE CASADA:
    // Determina o menor valor entre o que ainda falta casar da nova oferta
    // e a quantidade disponível na oferta existente.
    const matchedQuantity = Math.min(remainingNewQuantity, offerQuantity);
    
    // CÁLCULO DE TAXAS:
    // FEE_RATE: taxa de 0,4% cobrada em cada lado da negociação do balcão.
    // totalBruto: valor bruto da negociação sem taxas.
    // totalComprador: o comprador paga o valor bruto + taxa (desembolso total).
    // totalVendedor: o vendedor recebe o valor bruto - taxa (crédito líquido).
    const FEE_RATE = 0.004;
    const totalBruto = matchedQuantity * price;
    const fee = totalBruto * FEE_RATE;
    const totalComprador = totalBruto + fee;
    const totalVendedor = totalBruto - fee;
    
    // QUANTIDADES RESTANTES APÓS O MATCH:
    // Calculadas antes da transação para uso posterior na atualização dos documentos.
    const remainingExistingQuantity = offerQuantity - matchedQuantity;
    const remainingAfterNew = remainingNewQuantity - matchedQuantity;

    // TRANSAÇÃO ATÔMICA DO MATCH:
    // Todas as leituras e escritas decorrentes de um match ocorrem dentro de uma
    // única transação do Firestore, garantindo que não ocorram estados inconsistentes.
    await db.runTransaction(async (t) => {
      // REFERÊNCIAS AOS DOCUMENTOS ENVOLVIDOS:
      const buyerRef = db.collection("usuarios").doc(buyerId);
      const sellerRef = db.collection("usuarios").doc(sellerId);
      const newOfferRef = db.collection("orders").doc(newOfferId);
      const offerRef = db.collection("orders").doc(offerDoc.id);
      const startupRef = db.collection("startups").doc(newOffer.startupId);

      // LEITURAS DENTRO DA TRANSAÇÃO (obrigatório para garantir consistência):
      const buyerDoc = await t.get(buyerRef);
      const sellerDoc = await t.get(sellerRef);
      const startupDoc = await t.get(startupRef);
      const newOfferDoc = await t.get(newOfferRef);
      const existingOfferDoc = await t.get(offerRef);

      // TRATAMENTO: COMPRADOR NÃO ENCONTRADO
      // Se o comprador não existe mais, cancela a ordem de compra e aborta o match.
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

      // TRATAMENTO: VENDEDOR NÃO ENCONTRADO
      // Se o vendedor não existe mais, cancela a ordem de venda e aborta o match.
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

      // VALIDAÇÃO: ORDENS AINDA EXISTEM
      // Garante que ambas as ordens ainda existem no momento da execução da transação.
      if (!newOfferDoc.exists || !existingOfferDoc.exists) {
        throw new HttpsError("not-found", "Ordem não encontrada.");
      }

      const buyerData = buyerDoc.data()!;
      const sellerData = sellerDoc.data()!;
      const startupData = startupDoc.exists ? startupDoc.data()! : {};

      const buyerSaldo = Number(buyerData.saldo ?? 0);
      const sellerTokens = sellerData.tokens ?? {};
      const sellerTokensStartup = Number(sellerTokens[newOffer.startupId] ?? 0);

      // VALIDAÇÃO DE SALDO DO COMPRADOR (dentro da transação):
      // Se o comprador não tem saldo suficiente e ele é o autor da oferta existente,
      // cancela aquela oferta. Se é o autor da nova oferta, lança erro.
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

      // VALIDAÇÃO DE TOKENS DO VENDEDOR (dentro da transação):
      // Se o vendedor não tem tokens suficientes e ele é o autor da oferta existente,
      // cancela aquela oferta. Se é o autor da nova oferta, lança erro.
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

      // ATUALIZAÇÃO DO COMPRADOR (tokens):
      // Usa set com merge para garantir que o campo de tokens seja inicializado
      // mesmo que não exista ainda no documento do comprador.
      t.set(buyerRef, {
        tokens: {
          [newOffer.startupId]: admin.firestore.FieldValue.increment(matchedQuantity)
        }
      }, { merge: true });

      // ATUALIZAÇÃO DO COMPRADOR (saldo):
      // Debita o total (bruto + taxa) do saldo do comprador.
      t.update(buyerRef, {
        saldo: admin.firestore.FieldValue.increment(-totalComprador),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ATUALIZAÇÃO DO VENDEDOR:
      // Credita o valor líquido (bruto - taxa) no saldo do vendedor e
      // remove os tokens vendidos de sua carteira.
      t.update(sellerRef, {
        saldo: admin.firestore.FieldValue.increment(totalVendedor),
        [`tokens.${newOffer.startupId}`]:
          admin.firestore.FieldValue.increment(-matchedQuantity),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ATUALIZAÇÃO DA NOVA OFERTA:
      // Reduz a quantidade restante da nova oferta. Se zerou, marca como "filled".
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

      // ATUALIZAÇÃO DA OFERTA EXISTENTE:
      // Reduz a quantidade restante da oferta que estava no livro. Se zerou, marca como "filled".
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

      // REGISTRO GLOBAL DA TRANSAÇÃO:
      // Cria um log imutável do negócio na coleção "transactions" com todos os detalhes,
      // incluindo a taxa cobrada, para fins de auditoria e contabilidade da plataforma.
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

      // NOMES PARA EXIBIÇÃO NAS CARTEIRAS:
      // Busca o nome e ticker da startup de forma resiliente.
      const startupName = startupData.title ?? startupData.nome ?? "Startup";
      const ticker = startupData.ticker ?? startupData.simbolo ?? "";

      // REGISTRO NA CARTEIRA DO COMPRADOR:
      // Adiciona o histórico de compra na subcoleção "transacoesCarteira" do comprador,
      // mostrando o valor total pago (com taxa) e a quantidade recebida.
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

      // REGISTRO NA CARTEIRA DO VENDEDOR:
      // Adiciona o histórico de venda na subcoleção "transacoesCarteira" do vendedor,
      // mostrando o valor líquido recebido (após taxa) e a quantidade vendida.
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

    // ATUALIZA O CONTADOR LOCAL após match bem-sucedido:
    remainingNewQuantity = remainingAfterNew;

    // SNAPSHOT DO PATRIMÔNIO (PÓS-MATCH):
    // Registra o estado atualizado do patrimônio de ambas as partes
    // para alimentar os gráficos de evolução da carteira no app.
    await Promise.all([
      registerWalletSnapshot(buyerId, "purchase"),
      registerWalletSnapshot(sellerId, "sale"),
    ]);
  }
}
