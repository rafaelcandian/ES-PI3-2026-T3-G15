// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Tipagens e interfaces para o módulo de usuários.

import * as FirebaseFirestore from "firebase-admin/firestore";

export interface UserDocument {
  uid: string;
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
  criado_em: FirebaseFirestore.Timestamp;
  saldo: number;
  tokens: Record<string, number>;
  isAdmin?: boolean;
}

export interface CreateUserData {
  uid: string;
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
}
