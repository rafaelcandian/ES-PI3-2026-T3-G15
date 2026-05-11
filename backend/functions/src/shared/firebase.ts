// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Inicialização e exportação da instância do Firestore.

import {getFirestore} from "firebase-admin/firestore";

export const db = getFirestore();
