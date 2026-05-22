import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import { GetPerguntasData } from "../types/perguntasTypes";

export const getPerguntas = onCall(async (request) => {
  const data = request.data as GetPerguntasData;
  const { startupId } = data;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório.");
  }

  let isInvestor = false;

  if (request.auth && request.auth.uid) {
    const uid = request.auth.uid;
    const userDoc = await db.collection("usuarios").doc(uid).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data()!;
      const tokens = userData.tokens || {};
      if (tokens[startupId] && tokens[startupId] > 0) {
        isInvestor = true;
      }
    }
  }

  const perguntasRef = db.collection("startups").doc(startupId).collection("perguntas");
  const perguntasSnapshot = await perguntasRef.orderBy("createdAt", "asc").get();

  const results: any[] = [];

  perguntasSnapshot.forEach(doc => {
    const docData = doc.data();
    const isPrivada = docData.isPrivada || false;

    if (!isPrivada || isInvestor) {
      results.push({
        id: doc.id,
        autorNome: docData.autorNome,
        texto: docData.texto,
        isPrivada: isPrivada,
        createdAt: docData.createdAt,
      });
    }
  });

  return results;
});
