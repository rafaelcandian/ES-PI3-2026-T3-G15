/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// RELACIONADO AO CARTEIRA SERVICE

// retorna saldo e tokens do usuario
export const getBalance = onRequest(async (req, res) => {
    if(req.method !== "POST"){
        res.status(405).send("Método não permitido");
    }

    const uid = req.query.uid as string;
    if(!uid){
        res.status(400).json({error: "uid obrigatorio"});
        return;
    }

    try{
        const doc = await admin.firestore().collection("usuarios").doc(uid).get();
        if(!doc.exists){
            res.status(404).json({error: "Usuario não encontrado"});
            return;
        }

        const data = doc.data()!;
        res.json({
            saldo: data.saldo  ?? 0, // define como valor padrão 0 caso o saldo seja nulo (operador de coalescência)
            tokens: data.tokens ?? {}, // define um map vazio ({}) caso o tokens seja nulo
        });
    }catch(e){
        res.status(500).json({error: "Erro interno"});
    }
});

// Carrega a carteira
export const loadWallet = onRequest(async (req, res) => {
    if(req.method !== "POST"){ // verifica se o metodo é POST
        res.status(405).json({error: "Metodo não permitido"});
        return;
    }

    const {uid, valor} = req.body;
    if(!uid || !valor || valor <= 0){
        res.status(400).json({error: "uid é um valior obrigatorio"});
        return;
    }

    try{
        await admin.firestore().collection("usuarios").doc(uid).update({
            saldo: admin.firestore.FieldValue.increment(valor),
        });
        res.json({success: true, valorAdicionado: valor});
    }catch(e){
        res.status(500).json({error: "Erro ao carregar carteira"});
    }
});

// função auxiliar para validar o saldo na carteira em comparação com o valor do token que deseja comprar
async function validateBalance(uid: string, valor: number): Promise<boolean>{
    const doc = await admin.firestore().collection("usuarios").doc(uid).get();
    if(!doc.exists) return false;
    const saldo = doc.data()!.saldo ?? 0; // define como valor padrão 0 caso o saldo seja nulo
    return saldo >= valor;
}

// retorna se tem saldo suficiente
export const verifyBalance = onRequest(async (req, res) =>{
    const uid = req.query.uid as string;
    const valor = parseFloat(req.query.valor as string); // transforma o valor (string) em float removendo os espaços em branco no inicio e fim
    // retorna NaN(Not a Number) se o primeiro caractere for invalido

    if(!uid || isNaN(valor)){ // verifica se o uid ou valor estão presentes, se qualquer um dos dois não estiverem de acordo causa erro
        res.status(400).json({error: "uid e valor obrigatorios"});
        return;
    }

    const suf = await validateBalance(uid, valor); // puxa função auxiliar
    res.json({suf, valor});
});

// RELACIONADO AO BALCAO SERVICE

// criar oferta
export const createOffer = onRequest(async(req, res) => {
    if(req.method !== "POST"){
        res.status(405).json({error: "metodo não permitido"});
        return;
    }

    const {uid, startupId, type, quantity, pricePerToken} = req.body;

    if(!uid || !startupId || !type || !quantity || !pricePerToken){
        res.status(400).json({error: "campos obrigatorios faltando"});
        return;
    }

    if(quantity <= 0 || pricePerToken <= 0){
        res.status(400).json({error: "quantidade e preço devem ser positivos"});
        return;
    }

    const totalPrice = (quantity * pricePerToken);

    try{
        const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
        if(!userDoc.exists){
            res.status(404).json({error: "usuario não encontrado"});
            return;
        }

        const userData = userDoc.data();

        // valida saldo para compra
        if(type === "buy"){
            const saldo = userData!.saldo ?? 0;
            if(saldo < totalPrice){
                res.status(400).json({error: "Saldo insuficiente"});
                return;
            }
        }

        if(type === "sell"){
            const tokens = userData!.tokens ?? {};
            const tokensStartup = tokens[startupId] ?? 0;
            if(tokensStartup < quantity){
                res.status(400).json({error: "tokens insuficientes"});
                return;
            }
        }

        // criar oferta
        const newOfferRef = await admin.firestore().collection("orders").add({
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

        res.json({sucess: true});
    }catch(e){
        res.status(500).json({error: "Erro: $e"})
    }
});

// Matching
/*  Sempre que for criada uma oferta de compra, o sistema vai procurar se existe uma oferta de venda equivalente
    isso seria o matching, quando acontece varias operações acontecem, debitar saldo comprador, creditar saldo do vendedor
    transferir os tokens, trocar o status, etc. Se alguma operação falhar tudo precisa ser revertido para evitar problemas
*/

// função chamada depois de criar uma oferta
async function tryMatching(newOfferId: string, newOffer: any): Promise<void> {
    const firestoreAdm = admin.firestore();
  const opositeType = newOffer.type === "buy" ? "sell" : "buy"; // ternario, se o tipo da nova oferta for "buy" ele vai voltar como sell, se não fica como buy
    const offerSnapshot = await firestoreAdm.collection("orders").where("startupId", "==", newOffer.startupId).where("type", "==", opositeType).where("status", "==", "open").orderBy("createdAt", "asc").get();

    if(offerSnapshot.empty) return;

    for(const offerDoc of offerSnapshot.docs){
        const offer = offerDoc.data();

        // verifica compatibilidade do preço
        const compatiblePrice = newOffer.type === "buy" ? newOffer.pricePerToken >= offer.pricePerToken : newOffer.pricePerToken <= offer.pricePerToken;

        if(!compatiblePrice) continue; // se não for compativel ele continua (obviamente)

        const buyerId = newOffer.type === "buy" ? newOffer.userId : offer.userId;
        const sellerId = newOffer.type === "sell" ? newOffer.userId : offer.userId;
        const price = offer.pricePerToken;
        const quantity = Math.min(newOffer.quantity, offer.quantity);
        const total = quantity * price;

        await firestoreAdm.runTransaction(async(t) => {
            const buyerRef = firestoreAdm.collection("usuarios").doc(buyerId);
            const sellerRef = firestoreAdm.collection("usuarios").doc(sellerId);
            const newOfferRef = firestoreAdm.collection("orders").doc(newOfferId);
            const offerRef = firestoreAdm.collection("orders").doc(offerDoc.id);

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
                saldo: admin.firestore.FieldValue.increment(total)
            });

            // remover tokens do vendedor
            t.update(sellerRef, {
                ['tokens.${newOffer.startupId}']: Math.max(0, (sellerTokens[newOffer.startupId] ?? 0) - quantity),
            });

            // adicionar tokens do comprador
            t.update(buyerRef, {
                ['tokens.${newOffer.startupId']: (buyerTokens[newOffer.startupId] ?? 0) + quantity,
            });

            // troca o status para filled
            t.update(newOfferRef, {status:"filled"});
            t.update(offerRef, {status: "filled"});

            // faz o registro da transação
            const regRef = firestoreAdm.collection("transactions").doc();
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