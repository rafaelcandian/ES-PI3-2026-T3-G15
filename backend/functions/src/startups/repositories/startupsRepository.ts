// Autor:
// RA:
// Descrição: Repositório para abstrair o acesso ao Firestore na coleção de startups.

import {db} from "../../shared/firebase";
import {StartupDocument, StartupResponseDTO} from "../types/startupTypes";

export const startupsCollection = db.collection("startups");

export async function getStartupById(id: string): Promise<StartupResponseDTO | null> {
  const doc = await startupsCollection.doc(id).get();
  if (!doc.exists) {
    return null;
  }
  return {id: doc.id, ...(doc.data() as StartupDocument)};
}

export async function listAllStartups(
  filters?: { stage?: string; status?: string }
): Promise<StartupResponseDTO[]> {
  let query: FirebaseFirestore.Query = startupsCollection;

  if (filters?.stage) {
    query = query.where("stage", "==", filters.stage);
  }

  if (filters?.status) {
    query = query.where("status", "==", filters.status);
  }

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as StartupDocument),
  }));
}
