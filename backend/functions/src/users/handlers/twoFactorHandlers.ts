// Autor: Rafael Antonio Candian
// RA: 25016954

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Implementa o sistema de autenticação em dois fatores (2FA) da plataforma,
// baseado em código OTP (One-Time Password) enviado por e-mail.
// Contém duas Cloud Functions:
//   1. sendLoginTwoFactorCode: gera um código de 6 dígitos, cria uma sessão
//      temporária no Firestore e dispara o e-mail com o código ao usuário.
//   2. verifyLoginTwoFactorCode: valida o código fornecido pelo usuário,
//      com proteção contra força bruta (limite de tentativas) e expiração.
// O código é armazenado de forma segura como hash SHA-256, nunca em texto puro.
// =============================================================================

import {randomInt, createHash} from "crypto";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";

import {db} from "../../shared/firebase";
import {requireAuthenticatedUser} from "../../shared/auth";

// CONSTANTES DE SEGURANÇA:
// SESSION_TTL_MINUTES: tempo de vida da sessão 2FA em minutos.
//   Após esse tempo, o código expira e um novo deve ser solicitado.
// MAX_ATTEMPTS: número máximo de tentativas de validação por sessão.
//   Previne ataques de força bruta onde um atacante tentaria todos os códigos possíveis.
const SESSION_TTL_MINUTES = 10;
const MAX_ATTEMPTS = 5;

// FUNÇÃO AUXILIAR: buildCodeHash
// Gera um hash SHA-256 a partir da combinação do ID de sessão e do código OTP.
// Isso garante que o código nunca seja armazenado em texto claro no banco de dados.
// O sessionId é incluído no hash para dificultar ataques de pré-computação (rainbow tables).
function buildCodeHash(sessionId: string, code: string): string {
  return createHash("sha256")
    .update(`${sessionId}:${code}`)
    .digest("hex");
}

// FUNÇÃO AUXILIAR: normalizeEmail
// Normaliza o e-mail removendo espaços e convertendo para minúsculas.
// Evita falhas de comparação por diferenças de capitalização ou espaços acidentais.
function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

// CONFIGURAÇÃO DE ACESSO PÚBLICO:
// As funções de 2FA precisam ser acessíveis publicamente porque o fluxo de verificação
// pode ocorrer antes do usuário estar completamente autenticado no app.
const publicCallableOptions = {
  cors: true,
  invoker: "public" as const,
};

// FUNÇÃO: sendLoginTwoFactorCode
// Gera e envia um código OTP de 6 dígitos ao e-mail do usuário autenticado.
// O processo:
//   1. Obtém o e-mail do usuário via Firebase Auth.
//   2. Gera um código aleatório de 6 dígitos.
//   3. Cria uma sessão no Firestore com o hash do código e prazo de expiração.
//   4. Envia o e-mail com o código via trigger da coleção "mail" (Firebase Extensions).
//   5. Retorna o sessionId para que o app possa usá-lo na verificação.
export const sendLoginTwoFactorCode = onCall(publicCallableOptions, async (request) => {
  // VERIFICAÇÃO DE AUTENTICAÇÃO:
  // O usuário precisa estar autenticado (ter passado pela 1ª fase) para solicitar o 2FA.
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;

  // OBTENÇÃO DO E-MAIL DO USUÁRIO:
  // Busca os dados do usuário no Firebase Authentication para obter o e-mail verificado.
  const authUser = await getAuth().getUser(uid);
  const email = authUser.email ?? request.auth!.token.email;

  // VALIDAÇÃO: E-MAIL OBRIGATÓRIO
  // Sem e-mail, não é possível enviar o código 2FA.
  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "Usuario sem e-mail cadastrado."
    );
  }

  // GERAÇÃO DO CÓDIGO OTP:
  // randomInt gera um número criptograficamente seguro entre 100000 e 999999,
  // garantindo sempre um código de exatamente 6 dígitos.
  const code = randomInt(100000, 1000000).toString();

  // CRIAÇÃO DA SESSÃO NO FIRESTORE:
  // A sessão armazena o hash do código, não o código em si, por segurança.
  const sessionRef = db.collection("loginTwoFactorSessions").doc();

  // CÁLCULO DO PRAZO DE EXPIRAÇÃO:
  // Converte o TTL em milissegundos e soma ao timestamp atual para definir a expiração.
  const expiresAt = Timestamp.fromMillis(
    Date.now() + SESSION_TTL_MINUTES * 60 * 1000
  );

  // ESCRITA DA SESSÃO NO FIRESTORE:
  // Persiste todos os metadados da sessão, incluindo o hash seguro do código.
  await sessionRef.set({
    uid,
    email: normalizeEmail(email),     // E-mail normalizado para comparação posterior
    codeHash: buildCodeHash(sessionRef.id, code), // Código nunca armazenado em texto puro
    attempts: 0,                       // Contador de tentativas inicia em zero
    consumed: false,                   // Flag para evitar reutilização do código
    createdAt: FieldValue.serverTimestamp(),
    expiresAt,                         // Timestamp de expiração do código
  });

  // ENVIO DO E-MAIL VIA FIREBASE EXTENSION:
  // Adiciona um documento na coleção "mail", que é monitorada pela extensão
  // "Firebase Email Trigger" para disparar o e-mail automaticamente.
  await db.collection("mail").add({
    to: [email],
    message: {
      subject: "Codigo de verificacao MesclaInvest",
      text:
        `Seu codigo de verificacao MesclaInvest e ${code}. ` +
        `Ele expira em ${SESSION_TTL_MINUTES} minutos.`,
      html:
        "<p>Seu codigo de verificacao MesclaInvest e " +
        `<strong>${code}</strong>.</p>` +
        `<p>Ele expira em ${SESSION_TTL_MINUTES} minutos.</p>`,
    },
    createdAt: FieldValue.serverTimestamp(),
  });

  // RETORNO: sessionId e tempo de expiração para o app gerenciar o fluxo de verificação.
  return {
    sessionId: sessionRef.id,
    expiresInMinutes: SESSION_TTL_MINUTES,
  };
});

// FUNÇÃO: verifyLoginTwoFactorCode
// Valida o código OTP fornecido pelo usuário durante o fluxo de 2FA.
// Implementa múltiplas camadas de segurança:
//   - Valida formato do código (exatamente 6 dígitos numéricos).
//   - Verifica se a sessão existe, não expirou e não foi consumida.
//   - Limita tentativas para prevenir força bruta (MAX_ATTEMPTS).
//   - Compara via hash para evitar timing attacks.
//   - Usa transação atômica para atualizar tentativas e marcar como consumido.
export const verifyLoginTwoFactorCode = onCall(publicCallableOptions, async (request) => {
  // EXTRAÇÃO E NORMALIZAÇÃO DOS DADOS DE ENTRADA:
  const data = request.data as {
    sessionId?: string;
    email?: string;
    code?: string;
  };

  const sessionId = data.sessionId?.trim() ?? "";
  const email = normalizeEmail(data.email ?? "");
  const code = data.code?.trim() ?? "";

  // VALIDAÇÃO DO FORMATO DOS DADOS:
  // O código deve ter exatamente 6 dígitos numéricos. Regex ^\d{6}$ garante isso.
  if (!sessionId || !email || !/^\d{6}$/.test(code)) {
    throw new HttpsError(
      "invalid-argument",
      "Informe a sessao, o e-mail e o codigo de 6 digitos."
    );
  }

  const sessionRef = db.collection("loginTwoFactorSessions").doc(sessionId);

  // TRANSAÇÃO ATÔMICA:
  // Todas as verificações e atualizações da sessão ocorrem dentro de uma transação
  // para garantir consistência e evitar condições de corrida (race conditions)
  // em tentativas simultâneas de validação.
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);

    // VERIFICAÇÃO DE EXISTÊNCIA DA SESSÃO:
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Sessao nao encontrada.");
    }

    const session = snapshot.data();

    if (!session) {
      throw new HttpsError("not-found", "Sessao nao encontrada.");
    }

    // VERIFICAÇÃO DE REUTILIZAÇÃO:
    // Um código já utilizado (consumed = true) não pode ser reutilizado,
    // impedindo replay attacks.
    if (session.consumed === true) {
      throw new HttpsError("failed-precondition", "Codigo ja utilizado.");
    }

    // VERIFICAÇÃO DE EXPIRAÇÃO:
    // Compara o timestamp de expiração com o momento atual.
    const expiresAt = session.expiresAt as Timestamp | undefined;
    if (!expiresAt || expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Codigo expirado.");
    }

    // VERIFICAÇÃO DE LIMITE DE TENTATIVAS (proteção contra força bruta):
    // Após MAX_ATTEMPTS tentativas incorretas, a sessão é bloqueada permanentemente.
    const attempts = (session.attempts as number | undefined) ?? 0;
    if (attempts >= MAX_ATTEMPTS) {
      throw new HttpsError(
        "resource-exhausted",
        "Limite de tentativas excedido."
      );
    }

    // VERIFICAÇÃO DO E-MAIL:
    // O e-mail fornecido deve corresponder ao e-mail registrado na sessão.
    // Em caso de falha, incrementa o contador de tentativas antes de lançar o erro.
    if (session.email !== email) {
      transaction.update(sessionRef, {
        attempts: FieldValue.increment(1),
        lastAttemptAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "Codigo invalido.");
    }

    // VERIFICAÇÃO DO CÓDIGO VIA HASH:
    // Compara o hash esperado (armazenado) com o hash do código fornecido.
    // Nunca compara o código em texto claro. Em caso de falha, incrementa tentativas.
    const expectedHash = session.codeHash as string | undefined;
    if (expectedHash !== buildCodeHash(sessionId, code)) {
      transaction.update(sessionRef, {
        attempts: FieldValue.increment(1),
        lastAttemptAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "Codigo invalido.");
    }

    // MARCAÇÃO DA SESSÃO COMO CONSUMIDA:
    // Após validação bem-sucedida, marca a sessão como consumida para
    // impedir que o mesmo código seja usado novamente.
    transaction.update(sessionRef, {
      consumed: true,
      verifiedAt: FieldValue.serverTimestamp(),
    });
  });

  // RETORNO DE SUCESSO:
  // Indica ao app que o código foi verificado e o 2FA foi concluído.
  return {verified: true};
});
