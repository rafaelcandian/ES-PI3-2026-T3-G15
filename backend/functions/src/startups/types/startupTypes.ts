// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Tipagens e interfaces para o módulo de startups.

import * as FirebaseFirestore from "firebase-admin/firestore";

export interface StartupDocument {
  title: string;
  subtitle: string;
  tag: string;
  equity: number;
  tokens: number;
  tokenValue: number;
  progress: number;
  goal: number;
  image: string;
  stage: string;
  status: string;
  totalTokens: number;
  investorsCount: number;
  description: string;
  market: string;
  valuation: number;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}

export interface StartupResponseDTO extends StartupDocument {
  id: string;
}
