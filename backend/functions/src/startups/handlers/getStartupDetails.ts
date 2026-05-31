// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Handler para recuperar os detalhes de uma startup específica por ID.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {getStartupById} from "../repositories/startupsRepository";

export const getStartupDetails = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const {id} = request.data as { id?: string };

  if (!id) {
    throw new HttpsError("invalid-argument", "ID da startup é obrigatório.");
  }

  // BUSCA DETALHADA:
  // Chama o repositório para buscar a startup específica com base no ID recebido.
  // Como o ID é o identificador único do documento no Firestore, a busca é rápida e direta.
  const startup = await getStartupById(id);
  if (!startup) {
    throw new HttpsError("not-found", "Startup não encontrada.");
  }

  return startup;
});
