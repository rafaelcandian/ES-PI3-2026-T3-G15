// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Tipagens e interfaces para o módulo de ordens de compra e venda.

import * as FirebaseFirestore from "firebase-admin/firestore";

export interface OrderDocument {
  userId: string;
  startupId: string;
  type: "buy" | "sell";
  quantity: number;
  pricePerToken: number;
  totalPrice: number;
  status: "open" | "filled" | "cancelled";
  createdAt: FirebaseFirestore.Timestamp;
}

export interface CreateOfferData {
  startupId: string;
  type: "buy" | "sell";
  quantity: number;
  pricePerToken: number;
}

export interface DirectPurchaseData {
  startupId: string;
  quantity: number;
  pricePerToken: number;
}
