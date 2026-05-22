import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { Timestamp } from "firebase-admin/firestore";
import { SendQuestionData } from "../types/perguntasTypes";

export const sendQuestion = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  const data = request.data as SendQuestionData;
  const { startupId, texto, isPrivada } = data;

  if (!startupId || !texto || texto.trim() === "") {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes ou texto vazio.");
  }

  const userRef = db.collection("usuarios").doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const userData = userDoc.data()!;
  
  if (isPrivada) {
    const tokens = userData.tokens || {};
    const hasTokens = tokens[startupId] && tokens[startupId] > 0;
    if (!hasTokens) {
      throw new HttpsError("permission-denied", "Você precisa ser investidor para enviar perguntas privadas");
    }
  }

  const autorNome = userData.nome || "Usuário Desconhecido";

  const perguntaRef = db.collection("startups").doc(startupId).collection("perguntas").doc();
  
  await perguntaRef.set({
    autorId: uid,
    autorNome: autorNome,
    texto: texto.trim(),
    isPrivada: isPrivada,
    createdAt: Timestamp.now(),
  });

  return {
    message: "Pergunta enviada com sucesso"
  };
});
