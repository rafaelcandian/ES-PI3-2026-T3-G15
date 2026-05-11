// Autor:
// RA:
// Descrição: Handler para recuperar os detalhes de um usuário autenticado.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {getUserByUid} from "../repositories/usersRepository";

export const getUserDetails = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  const user = await getUserByUid(uid);
  if (!user) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  return {
    uid: user.uid,
    nome: user.nome,
    email: user.email,
    telefone: user.telefone,
    saldo: user.saldo,
    tokens: user.tokens,
  };
});
