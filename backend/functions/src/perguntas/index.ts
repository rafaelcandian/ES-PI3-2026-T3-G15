// Autor: Gabriel Benevides Bosso
// RA: 24013653

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Ponto de entrada (barrel export) do módulo de perguntas.
// Centraliza e re-exporta todas as Cloud Functions do módulo "perguntas",
// facilitando a importação no arquivo principal (src/index.ts) e evitando
// que outros módulos precisem conhecer a estrutura interna de pastas.
// =============================================================================

// EXPORTAÇÃO DAS CLOUD FUNCTIONS DO MÓDULO:
// - sendQuestion: permite que usuários enviem perguntas para uma startup.
// - getPerguntas: retorna a lista de perguntas de uma startup (com controle de acesso).
export { sendQuestion } from "./handlers/sendQuestion";
export { getPerguntas } from "./handlers/getPerguntas";
