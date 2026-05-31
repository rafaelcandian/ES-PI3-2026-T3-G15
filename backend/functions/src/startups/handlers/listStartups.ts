// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Handler para listar todas as startups com filtros opcionais.

import {onCall} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {listAllStartups} from "../repositories/startupsRepository";

export const listStartups = onCall(async (request) => {
  requireAuthenticatedUser(request);

  // BUSCA E FILTROS:
  // Recebe possíveis parâmetros de filtro enviados pelo cliente (ex: estágio da startup ou status).
  // Esses filtros serão repassados para a função do repositório responsável por montar
  // a consulta adequada no banco de dados.
  const filters = request.data as { stage?: string; status?: string } | undefined;

  const startups = await listAllStartups(filters);

  return {startups};
});
