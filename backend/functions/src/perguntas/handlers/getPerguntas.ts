// Autor: Gabriel Benevides Bosso
// RA: 24013653

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Implementa a Cloud Function "getPerguntas", responsável por retornar a lista
// de perguntas cadastradas para uma startup específica.
// A função aplica controle de acesso baseado em papel (RBAC simplificado):
//   - Perguntas públicas: visíveis para qualquer usuário (autenticado ou não).
//   - Perguntas privadas: visíveis apenas para investidores da startup
//     (usuários que possuem ao menos 1 token da startup em sua carteira).
// =============================================================================

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import { GetPerguntasData } from "../types/perguntasTypes";

// FUNÇÃO PRINCIPAL: getPerguntas
// Retorna as perguntas de uma startup, filtrando perguntas privadas
// para usuários que não sejam investidores daquela startup.
export const getPerguntas = onCall(async (request) => {
  // EXTRAÇÃO DO PARÂMETRO PRINCIPAL:
  // startupId identifica de qual startup as perguntas devem ser buscadas.
  const data = request.data as GetPerguntasData;
  const { startupId } = data;

  // VALIDAÇÃO: startupId é obrigatório.
  // Sem ele, não é possível saber de qual startup buscar as perguntas.
  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório.");
  }

  // VERIFICAÇÃO DE STATUS DE INVESTIDOR:
  // Determina se o usuário autenticado possui tokens da startup.
  // Se não estiver autenticado, isInvestor permanece false (só verá perguntas públicas).
  let isInvestor = false;

  if (request.auth && request.auth.uid) {
    const uid = request.auth.uid;

    // LEITURA DO PERFIL DO USUÁRIO NO FIRESTORE:
    // Busca o documento do usuário para verificar sua carteira de tokens.
    const userDoc = await db.collection("usuarios").doc(uid).get();

    if (userDoc.exists) {
      const userData = userDoc.data()!;

      // VERIFICAÇÃO DE TOKENS:
      // O campo "tokens" é um mapa onde a chave é o startupId e o valor é a quantidade.
      // O usuário é considerado investidor se tiver pelo menos 1 token da startup.
      const tokens = userData.tokens || {};
      if (tokens[startupId] && tokens[startupId] > 0) {
        isInvestor = true;
      }
    }
  }

  // BUSCA DAS PERGUNTAS NO FIRESTORE:
  // As perguntas são armazenadas como subcoleção dentro do documento da startup.
  // Ordenadas por data de criação (mais antigas primeiro) para exibição cronológica.
  const perguntasRef = db.collection("startups").doc(startupId).collection("perguntas");
  const perguntasSnapshot = await perguntasRef.orderBy("createdAt", "asc").get();

  // FILTRAGEM E MONTAGEM DA RESPOSTA:
  // Percorre todos os documentos de perguntas e aplica o filtro de visibilidade:
  // - Perguntas públicas (isPrivada = false): incluídas para todos.
  // - Perguntas privadas (isPrivada = true): incluídas apenas se o usuário for investidor.
  const results: any[] = [];

  perguntasSnapshot.forEach(doc => {
    const docData = doc.data();
    const isPrivada = docData.isPrivada || false;

    // CONTROLE DE ACESSO POR PRIVACIDADE:
    // Apenas inclui a pergunta privada se o usuário for investidor da startup.
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

  // RETORNO DA LISTA FILTRADA DE PERGUNTAS:
  return results;
});
