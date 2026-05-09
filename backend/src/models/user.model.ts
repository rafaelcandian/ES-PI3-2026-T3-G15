// Autor: 
// RA: 
// Descrição: Define a interface do modelo de Usuário e os dados para transferência (DTO) na sua criação.

import * as admin from "firebase-admin";

export interface UserModel {
  uid: string;
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
  criado_em: admin.firestore.Timestamp;
  saldo: number;
  tokens: Record<string, number>;
}

export interface CreateUserDTO {
  uid: string;
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
}
