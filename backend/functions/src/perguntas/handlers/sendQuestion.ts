// Autor: Gabriel Benevides Bosso
// RA: 24013653

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Implementa a Cloud Function "sendQuestion", que permite que usuários
// autenticados enviem perguntas para uma startup específica.
// Suporta dois tipos de pergunta:
//   - Públicas: qualquer usuário autenticado pode enviar.
//   - Privadas: apenas investidores (detentores de tokens) da startup podem enviar,
//     garantindo exclusividade e engajamento do ecossistema de investimento.
// =============================================================================

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { db } from "../../shared/firebase";
import { Timestamp } from "firebase-admin/firestore";
import { SendQuestionData } from "../types/perguntasTypes";

// FUNÇÃO PRINCIPAL: sendQuestion
// Valida os dados recebidos, verifica permissões e persiste a pergunta
// na subcoleção "perguntas" da startup correspondente no Firestore.
export const sendQuestion = onCall(async (request) => {
  // VERIFICAÇÃO DE AUTENTICAÇÃO:
  // Apenas usuários logados podem enviar perguntas.
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  // EXTRAÇÃO DOS DADOS DA REQUISIÇÃO:
  // startupId: qual startup receberá a pergunta.
  // texto: o conteúdo da pergunta escrita pelo usuário.
  // isPrivada: flag que indica se a pergunta é restrita a investidores.
  const data = request.data as SendQuestionData;
  const { startupId, texto, isPrivada } = data;

  // VALIDAÇÃO DE CAMPOS OBRIGATÓRIOS:
  // startupId e texto são obrigatórios. O texto não pode ser vazio ou apenas espaços.
  if (!startupId || !texto || texto.trim() === "") {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes ou texto vazio.");
  }

  // LEITURA DO PERFIL DO USUÁRIO:
  // Busca o documento do usuário no Firestore para obter seu nome
  // e verificar se é investidor (quando a pergunta for privada).
  const userRef = db.collection("usuarios").doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const userData = userDoc.data()!;

  // VERIFICAÇÃO DE PERMISSÃO PARA PERGUNTAS PRIVADAS:
  // Perguntas privadas são um privilégio exclusivo de investidores da startup.
  // Verifica se o usuário possui pelo menos 1 token da startup em sua carteira.
  if (isPrivada) {
    const tokens = userData.tokens || {};
    const hasTokens = tokens[startupId] && tokens[startupId] > 0;
    if (!hasTokens) {
      throw new HttpsError("permission-denied", "Você precisa ser investidor para enviar perguntas privadas");
    }
  }

  // OBTENÇÃO DO NOME DO AUTOR:
  // Usa o nome cadastrado do usuário. Caso não esteja disponível, usa um fallback genérico.
  const autorNome = userData.nome || "Usuário Desconhecido";

  // REFERÊNCIA PARA O NOVO DOCUMENTO:
  // A pergunta é salva como subcoleção "perguntas" dentro do documento da startup.
  // O .doc() sem argumento gera um ID único automaticamente.
  const perguntaRef = db.collection("startups").doc(startupId).collection("perguntas").doc();

  // ESCRITA NO FIRESTORE:
  // Persiste a pergunta com todos os metadados necessários para exibição e auditoria.
  await perguntaRef.set({
    autorId: uid,           // ID do autor para possível moderação/identificação
    autorNome: autorNome,   // Nome exibido publicamente junto à pergunta
    texto: texto.trim(),    // Texto da pergunta com espaços extras removidos
    isPrivada: isPrivada,   // Flag de visibilidade (pública ou restrita a investidores)
    createdAt: Timestamp.now(), // Timestamp para ordenação cronológica
  });

  // RETORNO DE SUCESSO:
  return {
    message: "Pergunta enviada com sucesso"
  };
});
