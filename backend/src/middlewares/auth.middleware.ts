// Autor: 
// RA: 
// Descrição: Middleware de autenticação que valida o token do Firebase e injeta o uid na requisição.

import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token não fornecido' });
    }

    const token = authHeader.split('Bearer ')[1];
    
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      (req as any).uid = decodedToken.uid;
      return next();
    } catch (error) {
      return res.status(401).json({ error: 'Token inválido ou expirado' });
    }
  } catch (error) {
    return res.status(500).json({ error: 'Erro interno de autenticação' });
  }
};
