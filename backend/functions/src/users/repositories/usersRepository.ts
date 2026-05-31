// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Repositório para abstrair o acesso ao Firestore na coleção de usuários.

import {db} from "../../shared/firebase";
import {UserDocument} from "../types/usersTypes";
import {FieldValue} from "firebase-admin/firestore";

export async function getUserByUid(uid: string): Promise<UserDocument | null> {
  // LEITURA DO FIRESTORE:
  // Recupera as informações de um usuário com base no seu UID (Identificador Único).
  // Essa abstração previne repetição de código sempre que precisarmos dos dados de um usuário específico.
  const doc = await db.collection("usuarios").doc(uid).get();
  if (!doc.exists) {
    return null;
  }
  return doc.data() as UserDocument;
}

export async function createUserDocument(data: UserDocument): Promise<void> {
  // ESCRITA NO FIRESTORE (Criação):
  // Insere um novo documento na coleção "usuarios", utilizando o próprio uid como chave (ID do documento).
  // Isso facilita buscar o usuário de forma determinística posteriormente.
  await db.collection("usuarios").doc(data.uid).set(data);
}

export async function incrementUserBalance(uid: string, valor: number): Promise<void> {
  // ESCRITA NO FIRESTORE (Atualização Atômica):
  // Utiliza FieldValue.increment para aumentar (ou diminuir, se for negativo) o saldo do usuário
  // de forma segura contra concorrência (evitando que duas operações simultâneas sobreescrevam o valor de forma incorreta).
  await db.collection("usuarios").doc(uid).update({
    saldo: FieldValue.increment(valor),
  });
}
