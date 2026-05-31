// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Módulo compartilhado para validação de autenticação em Cloud Functions.

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Centraliza a lógica de verificação de autenticação, evitando duplicação
// de código entre todos os handlers do backend.
// Qualquer Cloud Function que exija autenticação deve chamar esta função
// no início de sua execução, antes de qualquer lógica de negócio.
// =============================================================================

import {HttpsError} from "firebase-functions/https";

// FUNÇÃO: requireAuthenticatedUser
// Verifica se a requisição foi feita por um usuário autenticado no Firebase.
// O Firebase Functions v2 injeta automaticamente o token de autenticação
// no campo `request.auth` quando o cliente está logado.
// Se `request.auth` for nulo ou ausente (usuário não autenticado),
// lança um HttpsError com código "unauthenticated", que é retornado ao
// cliente como um erro HTTP 401 (Não Autorizado).
export function requireAuthenticatedUser(request: any): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado.");
  }
}
