// Autor: 
// RA: 
// Descrição: Define as rotas HTTP relacionadas aos Usuários, conectando os endpoints aos controladores correspondentes.

import { Router } from 'express';
import {
  createUser,
  getProfile,
  getWallet,
  deposit
} from '../controllers/user.controller';

const router = Router();

// Rota para criar um novo usuário
router.post('/users', createUser);

// Rota para buscar o perfil de um usuário específico
router.get('/users/:uid', getProfile);

// Rota para buscar apenas a carteira (saldo e tokens) de um usuário
router.get('/users/:uid/wallet', getWallet);

// Rota para adicionar saldo na carteira do usuário
router.post('/users/:uid/deposit', deposit);

export default router;
