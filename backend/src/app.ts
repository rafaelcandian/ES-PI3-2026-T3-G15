// Autor: 
// RA: 
// Descrição: Configuração principal do aplicativo Express, incluindo middlewares e rotas.

import express from 'express';
import cors from 'cors';
import userRoutes from './routes/user.routes';
import startupRoutes from './routes/startup.routes';

const app = express();

// Middlewares globais
app.use(express.json());
app.use(cors({ origin: true }));

// Rotas da API
app.use('/', userRoutes);
app.use('/', startupRoutes);

// Rota de Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

export default app;
