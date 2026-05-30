// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Handler para listar todas as startups com filtros opcionais.

import {onCall} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {listAllStartups} from "../repositories/startupsRepository";

export const listStartups = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const filters = request.data as { stage?: string; status?: string } | undefined;

  const startups = await listAllStartups(filters);

  return {startups};
});
