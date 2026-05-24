import {randomInt, createHash} from "crypto";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";

import {db} from "../../shared/firebase";
import {requireAuthenticatedUser} from "../../shared/auth";

const SESSION_TTL_MINUTES = 10;
const MAX_ATTEMPTS = 5;

function buildCodeHash(sessionId: string, code: string): string {
  return createHash("sha256")
    .update(`${sessionId}:${code}`)
    .digest("hex");
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

const publicCallableOptions = {
  cors: true,
  invoker: "public" as const,
};

export const sendLoginTwoFactorCode = onCall(publicCallableOptions, async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const authUser = await getAuth().getUser(uid);
  const email = authUser.email ?? request.auth!.token.email;

  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "Usuario sem e-mail cadastrado."
    );
  }

  const code = randomInt(100000, 1000000).toString();
  const sessionRef = db.collection("loginTwoFactorSessions").doc();
  const expiresAt = Timestamp.fromMillis(
    Date.now() + SESSION_TTL_MINUTES * 60 * 1000
  );

  await sessionRef.set({
    uid,
    email: normalizeEmail(email),
    codeHash: buildCodeHash(sessionRef.id, code),
    attempts: 0,
    consumed: false,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt,
  });

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

  return {
    sessionId: sessionRef.id,
    expiresInMinutes: SESSION_TTL_MINUTES,
  };
});

export const verifyLoginTwoFactorCode = onCall(publicCallableOptions, async (request) => {
  const data = request.data as {
    sessionId?: string;
    email?: string;
    code?: string;
  };

  const sessionId = data.sessionId?.trim() ?? "";
  const email = normalizeEmail(data.email ?? "");
  const code = data.code?.trim() ?? "";

  if (!sessionId || !email || !/^\d{6}$/.test(code)) {
    throw new HttpsError(
      "invalid-argument",
      "Informe a sessao, o e-mail e o codigo de 6 digitos."
    );
  }

  const sessionRef = db.collection("loginTwoFactorSessions").doc(sessionId);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Sessao nao encontrada.");
    }

    const session = snapshot.data();

    if (!session) {
      throw new HttpsError("not-found", "Sessao nao encontrada.");
    }

    if (session.consumed === true) {
      throw new HttpsError("failed-precondition", "Codigo ja utilizado.");
    }

    const expiresAt = session.expiresAt as Timestamp | undefined;
    if (!expiresAt || expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "Codigo expirado.");
    }

    const attempts = (session.attempts as number | undefined) ?? 0;
    if (attempts >= MAX_ATTEMPTS) {
      throw new HttpsError(
        "resource-exhausted",
        "Limite de tentativas excedido."
      );
    }

    if (session.email !== email) {
      transaction.update(sessionRef, {
        attempts: FieldValue.increment(1),
        lastAttemptAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "Codigo invalido.");
    }

    const expectedHash = session.codeHash as string | undefined;
    if (expectedHash !== buildCodeHash(sessionId, code)) {
      transaction.update(sessionRef, {
        attempts: FieldValue.increment(1),
        lastAttemptAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "Codigo invalido.");
    }

    transaction.update(sessionRef, {
      consumed: true,
      verifiedAt: FieldValue.serverTimestamp(),
    });
  });

  return {verified: true};
});
