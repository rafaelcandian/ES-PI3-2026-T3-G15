// Autor: Gabriel Benevides Bosso
// RA: 24013653

export interface SendQuestionData {
  startupId: string;
  texto: string;
  isPrivada: boolean;
}

export interface GetPerguntasData {
  startupId: string;
}
