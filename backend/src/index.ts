// Autor: 
// RA: 
// Descrição: Ponto de entrada das Cloud Functions e inicialização do Firebase Admin.

import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';
import app from './app';

// Inicializa o Firebase Admin SDK apenas se ainda não foi inicializado
if (!admin.apps.length) {
  admin.initializeApp();
}

// Exporta o app Express como uma Cloud Function
export const api = onRequest(app);
