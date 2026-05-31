// Autor: Gabriel Benevides Bosso
// RA: 24013653

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Define as interfaces TypeScript (contratos de dados) utilizadas pelo módulo
// de perguntas e respostas da plataforma.
// Essas interfaces garantem consistência e segurança de tipos entre as
// Cloud Functions e os dados trafegados entre o app mobile e o backend.
// =============================================================================

// INTERFACE: SendQuestionData
// Define a estrutura dos dados que o cliente (app mobile) deve enviar
// ao chamar a Cloud Function "sendQuestion".
//   - startupId: identifica para qual startup a pergunta será enviada.
//   - texto: conteúdo textual da pergunta escrita pelo usuário.
//   - isPrivada: flag booleana que determina se a pergunta é exclusiva
//     para investidores (true) ou visível publicamente (false).
export interface SendQuestionData {
  startupId: string;
  texto: string;
  isPrivada: boolean;
}

// INTERFACE: GetPerguntasData
// Define a estrutura dos dados que o cliente deve enviar
// ao chamar a Cloud Function "getPerguntas".
//   - startupId: identifica de qual startup as perguntas devem ser buscadas.
export interface GetPerguntasData {
  startupId: string;
}
