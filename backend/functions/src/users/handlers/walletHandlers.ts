// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Funções para o gerenciamento de saldo e tokens da carteira.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";

// retorna saldo e tokens do usuario
export const getBalance = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  try {
    const doc = await db.collection("usuarios").doc(uid).get();
    if (!doc.exists) {
      throw new HttpsError("not-found", "Usuario não encontrado");
    }

    const data = doc.data()!;
    return {
      saldo: data.saldo ?? 0, // define como valor padrão 0 caso o saldo seja nulo (operador de coalescência)
      tokens: data.tokens ?? {}, // define um map vazio ({}) caso o tokens seja nulo
    };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", "Erro interno");
  }
});

// Carrega a carteira
export const loadWallet = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;
  const valor = request.data.valor;

  if (!valor || valor <= 0) {
    throw new HttpsError("invalid-argument", "valor invalido");
  }

  try {
    await db.collection("usuarios").doc(uid).update({
      saldo: admin.firestore.FieldValue.increment(valor),
    });
    return {success: true, valorAdicionado: valor};
  } catch (e) {
    throw new HttpsError("internal", "Erro ao carregar carteira");
  }
});

// função auxiliar para validar o saldo na carteira em comparação com o valor do token que deseja comprar
async function validateBalance(uid: string, valor: number): Promise<boolean> { // garante que vai retornar um dado boolean
  const doc = await db.collection("usuarios").doc(uid).get();
  if (!doc.exists) return false;
  const saldo = doc.data()!.saldo ?? 0; // define como valor padrão 0 caso o saldo seja nulo
  return saldo >= valor;
}

// retorna se tem saldo suficiente
export const verifyBalance = onCall(async (request) =>{
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;
  const valorRaw = request.data.valor;

  const valor = typeof valorRaw === "string" ? parseFloat(valorRaw) : valorRaw; // transforma o valor (string) em float removendo os espaços em branco no inicio e fim
  // retorna NaN(Not a Number) se o primeiro caractere for invalido

  if (isNaN(valor)) { // verifica se o uid ou valor estão presentes, se qualquer um dos dois não estiverem de acordo causa erro
    throw new HttpsError("invalid-argument", "valor obrigatorio");
  }

  const suf = await validateBalance(uid, valor); // puxa função auxiliar
  return {suf, valor};
});
