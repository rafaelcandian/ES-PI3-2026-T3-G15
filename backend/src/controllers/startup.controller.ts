// Autor: 
// RA: 
// Descrição: Controlador responsável por gerenciar as requisições relacionadas às Startups do sistema.

import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { StartupModel, StartupResponseDTO } from '../models/startup.model';

// Lista todas as startups, com suporte a filtros
export const listStartups = async (req: Request, res: Response) => {
  try {
    const { stage, status } = req.query;
    
    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection('startups');

    // Aplica os filtros, caso existam na query
    if (stage) {
      query = query.where('stage', '==', stage as string);
    }
    if (status) {
      query = query.where('status', '==', status as string);
    }

    const snapshot = await query.get();
    
    const startups: StartupResponseDTO[] = [];
    snapshot.forEach(doc => {
      const data = doc.data() as StartupModel;
      startups.push({ id: doc.id, ...data });
    });

    return res.status(200).json(startups);
  } catch (error) {
    console.error('Erro ao listar startups:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Busca os detalhes completos de uma startup específica
export const getStartup = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    const db = admin.firestore();
    const doc = await db.collection('startups').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Startup não encontrada' });
    }

    const data = doc.data() as StartupModel;
    const response: StartupResponseDTO = { id: doc.id, ...data };
    
    return res.status(200).json(response);
  } catch (error) {
    console.error('Erro ao buscar startup:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Busca apenas as informações de tokens e equity de uma startup
export const getStartupTokens = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    const db = admin.firestore();
    const doc = await db.collection('startups').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Startup não encontrada' });
    }

    const data = doc.data() as StartupModel;
    
    return res.status(200).json({
      tokens: data.tokens,
      tokenValue: data.tokenValue,
      totalTokens: data.totalTokens,
      equity: data.equity
    });
  } catch (error) {
    console.error('Erro ao buscar tokens da startup:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};
