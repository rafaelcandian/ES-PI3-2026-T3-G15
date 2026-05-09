// Autor: 
// RA: 
// Descrição: Controlador responsável por gerenciar as requisições relacionadas aos Usuários (perfil, carteira e depósitos).

import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { CreateUserDTO, UserModel } from '../models/user.model';

// Cria um novo usuário
export const createUser = async (req: Request, res: Response) => {
  try {
    const { uid, nome, email, cpf, telefone } = req.body as CreateUserDTO;

    // Validação de campos obrigatórios
    if (!uid || !nome || !email || !cpf || !telefone) {
      return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
    }

    const db = admin.firestore();
    const userRef = db.collection('usuarios').doc(uid);
    const userDoc = await userRef.get();

    // Verifica se já existe
    if (userDoc.exists) {
      return res.status(409).json({ error: 'Usuário já existe' });
    }

    // Prepara o modelo a ser salvo
    const newUser: UserModel = {
      uid,
      nome,
      email,
      cpf,
      telefone,
      criado_em: admin.firestore.Timestamp.now(),
      saldo: 0,
      tokens: {}
    };

    // Cria o documento
    await userRef.set(newUser);

    return res.status(201).json(newUser);
  } catch (error) {
    console.error('Erro ao criar usuário:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Busca o perfil de um usuário
export const getProfile = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    const db = admin.firestore();
    const userDoc = await db.collection('usuarios').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    return res.status(200).json(userDoc.data() as UserModel);
  } catch (error) {
    console.error('Erro ao buscar perfil:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Busca apenas a carteira (saldo e tokens) de um usuário
export const getWallet = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    const db = admin.firestore();
    const userDoc = await db.collection('usuarios').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const data = userDoc.data() as UserModel;
    return res.status(200).json({
      saldo: data.saldo,
      tokens: data.tokens
    });
  } catch (error) {
    console.error('Erro ao buscar carteira:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Adiciona saldo ao usuário usando operação atômica
export const deposit = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;
    const { valor } = req.body;

    if (valor === undefined || typeof valor !== 'number' || valor <= 0)
      return res.status(400).json({ error: 'Valor inválido. O valor deve ser maior que 0.' });
  }

    const db = admin.firestore();
  const userRef = db.collection('usuarios').doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return res.status(404).json({ error: 'Usuário não encontrado' });
  }

  // Incrementa atômicamente
  await userRef.update({
    saldo: admin.firestore.FieldValue.increment(valor)
  });

  // Busca o documento atualizado para retornar o novo saldo
  const updatedDoc = await userRef.get();
  const updatedData = updatedDoc.data() as UserModel;

  return res.status(200).json({ novoSaldo: updatedData.saldo });
} catch (error) {
  console.error('Erro ao depositar saldo:', error);
  return res.status(500).json({ error: 'Erro interno do servidor' });
}
};
