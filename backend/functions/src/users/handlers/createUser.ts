// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Handler para criação de novos usuários no banco de dados.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getUserByUid, createUserDocument} from "../repositories/usersRepository";
import {Timestamp} from "firebase-admin/firestore";
import {CreateUserData} from "../types/usersTypes";

export const createUser = onCall(async (request) => {
  const data = request.data as CreateUserData;
  const {uid, nome, email, cpf, telefone} = data;

  if (!uid || !nome || !email || !cpf || !telefone) {
    throw new HttpsError("invalid-argument", "Campos obrigatórios ausentes.");
  }

  const existingUser = await getUserByUid(uid);
  if (existingUser) {
    throw new HttpsError("already-exists", "Usuário já existe.");
  }

  await createUserDocument({
    uid,
    nome,
    email,
    cpf,
    telefone,
    saldo: 0,
    tokens: {},
    criado_em: Timestamp.now(),
    isAdmin: false,
  });

  return {message: "Usuário criado com sucesso!"};
});
