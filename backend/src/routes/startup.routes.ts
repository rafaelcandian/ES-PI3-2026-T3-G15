// Autor: 
// RA: 
// Descrição: Define as rotas HTTP para acesso e leitura dos dados das Startups no sistema.

import { Router } from 'express';
import {
  listStartups,
  getStartup,
  getStartupTokens
} from '../controllers/startup.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Rota para listar todas as startups (suporta query params: stage, status)
router.get('/startups', authMiddleware, listStartups);

// Rota para buscar os detalhes de uma startup específica pelo ID
router.get('/startups/:id', authMiddleware, getStartup);

// Rota para buscar apenas os tokens e informações financeiras simplificadas de uma startup
router.get('/startups/:id/tokens', authMiddleware, getStartupTokens);

export default router;
