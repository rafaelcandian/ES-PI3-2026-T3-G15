// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Repositório para abstrair o acesso ao Firestore na coleção de ordens.

import {db} from "../../shared/firebase";

// REFERÊNCIA DE COLEÇÃO:
// Exporta a referência direta para a coleção "orders", centralizando o acesso e facilitando
// manutenções futuras caso o nome da coleção mude no banco de dados.
export const ordersCollection = db.collection("orders");

export async function getOpenOrdersByStartup(
  startupId: string,
  type: "buy" | "sell"
): Promise<FirebaseFirestore.QuerySnapshot> {
  // QUERY DO FIRESTORE:
  // Essa busca (query) no banco de dados filtra a coleção "orders" pelas ordens que
  // pertencem a uma startup específica (startupId), que são de um tipo específico ("buy" ou "sell"),
  // e que ainda estão abertas ("open").
  // Por fim, ordena os resultados pela data de criação em ordem ascendente (as ordens mais antigas primeiro).
  return ordersCollection
    .where("startupId", "==", startupId)
    .where("type", "==", type)
    .where("status", "==", "open")
    .orderBy("createdAt", "asc")
    .get();
}
