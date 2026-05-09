// Autor: 
// RA: 
// Descrição: Define o modelo de dados para a coleção de Startups e seu DTO de resposta.

export interface StartupModel {
  title: string;
  subtitle: string;
  tag: string;
  equity: number;
  tokens: number;
  tokenValue: number;
  progress: number;
  goal: number;
  image: string;
  
  // Novos campos adicionados
  stage: string;
  status: string;
  totalTokens: number;
  investorsCount: number;
  description: string;
  market: string;
  valuation: number;
}

export interface StartupResponseDTO extends StartupModel {
  id: string;
}
