// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Módulo compartilhado para validação de autenticação em Cloud Functions.

import {HttpsError} from "firebase-functions/https";

export function requireAuthenticatedUser(request: any): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado.");
  }
}
