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

export const getSaldo = onRequest(async (req, res) => {
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
            saldo: data.saldo  ?? 0,
            tokens: data.tokens ?? {},
        });
    }catch(e){
        res.status(500).json({error: "Erro interno"});
    }
});

export const loadCarteira = onRequest(async (req, res) => {
    if(req.method !== "POST"){
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
