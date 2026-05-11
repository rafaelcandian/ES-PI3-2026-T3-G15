// Autor:
// RA:
// Descrição: Repositório para abstrair o acesso ao Firestore na coleção de usuários.

import {db} from "../../shared/firebase";
import {UserDocument} from "../types/usersTypes";
import {FieldValue} from "firebase-admin/firestore";

export async function getUserByUid(uid: string): Promise<UserDocument | null> {
  const doc = await db.collection("usuarios").doc(uid).get();
  if (!doc.exists) {
    return null;
  }
  return doc.data() as UserDocument;
}

export async function createUserDocument(data: UserDocument): Promise<void> {
  await db.collection("usuarios").doc(data.uid).set(data);
}

export async function incrementUserBalance(uid: string, valor: number): Promise<void> {
  await db.collection("usuarios").doc(uid).update({
    saldo: FieldValue.increment(valor),
  });
}
