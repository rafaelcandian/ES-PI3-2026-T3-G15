// Autor: Gabriel Benevides Bosso
// RA: 24013653
// Descrição: Tipagens e interfaces para o módulo de ordens de compra e venda.

import * as FirebaseFirestore from "firebase-admin/firestore";

// INTERFACE DE DOCUMENTO DE ORDEM (OrderDocument):
// Define a estrutura estrita de como uma ordem (compra ou venda no balcão) é armazenada no Firestore.
// Assegura a consistência de tipos em todo o ecossistema (backend e frontend).
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

// INTERFACE DE CRIAÇÃO DE OFERTA (CreateOfferData):
// Estabelece a assinatura de dados esperada (payload) recebida do cliente no momento da
// criação de uma nova oferta de balcão (tanto de compra quanto de venda).
export interface CreateOfferData {
  startupId: string;
  type: "buy" | "sell";
  quantity: number;
  pricePerToken: number;
}

// INTERFACE DE COMPRA DIRETA (DirectPurchaseData):
// Modela os dados necessários enviados pela interface do usuário para executar
// uma operação de compra direta de tokens recém-emitidos por uma startup.
export interface DirectPurchaseData {
  startupId: string;
  quantity: number;
  pricePerToken: number;
}
