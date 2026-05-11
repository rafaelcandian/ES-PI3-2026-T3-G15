// Autor:
// RA:
// Descrição: Repositório para abstrair o acesso ao Firestore na coleção de ordens.

import {db} from "../../shared/firebase";

export const ordersCollection = db.collection("orders");

export async function getOpenOrdersByStartup(
  startupId: string,
  type: "buy" | "sell"
): Promise<FirebaseFirestore.QuerySnapshot> {
  return ordersCollection
    .where("startupId", "==", startupId)
    .where("type", "==", type)
    .where("status", "==", "open")
    .orderBy("createdAt", "asc")
    .get();
}
