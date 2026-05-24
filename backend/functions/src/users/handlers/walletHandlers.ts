// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Funções para o gerenciamento de saldo, tokens e dashboard da carteira.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";

export const getBalance = onCall(async (request) => {
  requireAuthenticatedUser(request);
  const uid = request.auth!.uid;

  try {
    const doc = await db.collection("usuarios").doc(uid).get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "Usuario não encontrado");
    }

    const data = doc.data()!;

    return {
      saldo: data.saldo ?? 0,
      tokens: data.tokens ?? {},
    };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", "Erro interno");
  }
});

export const loadWallet = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const valor = Number(request.data.valor);

  if (!valor || valor <= 0) {
    throw new HttpsError("invalid-argument", "valor invalido");
  }

  try {
    await db.collection("usuarios").doc(uid).update({
      saldo: admin.firestore.FieldValue.increment(valor),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await registerWalletSnapshot(uid, "deposit");

    return {
      success: true,
      valorAdicionado: valor,
    };
  } catch (e) {
    console.error("Erro no loadWallet:", e);

    if (e instanceof HttpsError) throw e;

    throw new HttpsError(
      "internal",
      `Erro ao carregar carteira: ${e}`
    );
  }
});

async function validateBalance(
  uid: string,
  valor: number
): Promise<boolean> {
  const doc = await db.collection("usuarios").doc(uid).get();

  if (!doc.exists) return false;

  const saldo = doc.data()!.saldo ?? 0;

  return saldo >= valor;
}

export const verifyBalance = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const valorRaw = request.data.valor;

  const valor =
    typeof valorRaw === "string" ? parseFloat(valorRaw) : valorRaw;

  if (isNaN(valor)) {
    throw new HttpsError("invalid-argument", "valor obrigatorio");
  }

  const suf = await validateBalance(uid, valor);

  return {
    suf,
    valor,
  };
});

type WalletChartPeriod =
  | "1h"
  | "24h"
  | "1sem"
  | "1mes"
  | "6meses"
  | "1ano";

type WalletChartPoint = {
  label: string;
  value: number;
  createdAt: string;
};

type WalletSnapshotData = {
  patrimonioTotal: number;
  saldo: number;
  valorAtivos: number;
  tokensTotais: number;
};

function pad(value: number): string {
  return value.toString().padStart(2, "0");
}

function normalizePeriod(periodRaw: unknown): WalletChartPeriod {
  const period = String(periodRaw ?? "1mes");

  const validPeriods: WalletChartPeriod[] = [
    "1h",
    "24h",
    "1sem",
    "1mes",
    "6meses",
    "1ano",
  ];

  if (validPeriods.includes(period as WalletChartPeriod)) {
    return period as WalletChartPeriod;
  }

  return "1mes";
}

function getPeriodConfig(period: WalletChartPeriod): {
  startDate: Date;
  maxPoints: number;
  bucketType: "5min" | "hour" | "day" | "week" | "month";
} {
  const now = new Date();

  switch (period) {
  case "1h":
    return {
      startDate: new Date(now.getTime() - 60 * 60 * 1000),
      maxPoints: 12,
      bucketType: "5min",
    };

  case "24h":
    return {
      startDate: new Date(now.getTime() - 24 * 60 * 60 * 1000),
      maxPoints: 24,
      bucketType: "hour",
    };

  case "1sem":
    return {
      startDate: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
      maxPoints: 14,
      bucketType: "day",
    };

  case "1mes":
    return {
      startDate: new Date(
        now.getFullYear(),
        now.getMonth() - 1,
        now.getDate()
      ),
      maxPoints: 30,
      bucketType: "day",
    };

  case "6meses":
    return {
      startDate: new Date(
        now.getFullYear(),
        now.getMonth() - 6,
        now.getDate()
      ),
      maxPoints: 24,
      bucketType: "week",
    };

  case "1ano":
    return {
      startDate: new Date(
        now.getFullYear() - 1,
        now.getMonth(),
        now.getDate()
      ),
      maxPoints: 12,
      bucketType: "month",
    };
  }
}

function getWeekStart(date: Date): Date {
  const newDate = new Date(date);
  const day = newDate.getDay();
  const diff = day === 0 ? -6 : 1 - day;

  newDate.setDate(newDate.getDate() + diff);
  newDate.setHours(0, 0, 0, 0);

  return newDate;
}

function getBucketDate(
  date: Date,
  bucketType: "5min" | "hour" | "day" | "week" | "month"
): Date {
  const bucket = new Date(date);

  switch (bucketType) {
  case "5min": {
    const minutes = Math.floor(bucket.getMinutes() / 5) * 5;
    bucket.setMinutes(minutes, 0, 0);
    return bucket;
  }

  case "hour":
    bucket.setMinutes(0, 0, 0);
    return bucket;

  case "day":
    bucket.setHours(0, 0, 0, 0);
    return bucket;

  case "week":
    return getWeekStart(bucket);

  case "month":
    bucket.setDate(1);
    bucket.setHours(0, 0, 0, 0);
    return bucket;
  }
}

function getBucketKey(date: Date): string {
  return date.toISOString();
}

function getBucketLabel(
  date: Date,
  bucketType: "5min" | "hour" | "day" | "week" | "month"
): string {
  switch (bucketType) {
  case "5min":
    return `${pad(date.getHours())}:${pad(date.getMinutes())}`;

  case "hour":
    return `${pad(date.getHours())}:00`;

  case "day":
    return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}`;

  case "week":
    return `Sem. ${pad(date.getDate())}/${pad(date.getMonth() + 1)}`;

  case "month":
    return `${pad(date.getMonth() + 1)}/${date.getFullYear()}`;
  }
}

async function calculateWalletSnapshotData(
  uid: string
): Promise<WalletSnapshotData> {
  const userRef = db.collection("usuarios").doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "Usuario não encontrado");
  }

  const userData = userDoc.data()!;
  const saldo = Number(userData.saldo ?? 0);
  const tokens = userData.tokens ?? {};

  let valorAtivos = 0;
  let tokensTotais = 0;

  for (const [startupId, quantidadeRaw] of Object.entries(tokens)) {
    const quantidade = Number(quantidadeRaw);

    if (!quantidade || quantidade <= 0) continue;

    const startupDoc = await db
      .collection("startups")
      .doc(startupId)
      .get();

    if (!startupDoc.exists) continue;

    const startupData = startupDoc.data()!;

    const valorToken = Number(
      startupData.tokenValue ??
      startupData.valorToken ??
      startupData.valorFixoTokens ??
      0
    );

    valorAtivos += quantidade * valorToken;
    tokensTotais += quantidade;
  }

  return {
    patrimonioTotal: saldo + valorAtivos,
    saldo,
    valorAtivos,
    tokensTotais,
  };
}

export async function registerWalletSnapshot(
  uid: string,
  eventType: string
): Promise<void> {
  try {
    const userRef = db.collection("usuarios").doc(uid);
    const snapshotData = await calculateWalletSnapshotData(uid);

    await userRef.collection("patrimonioHistorico").add({
      valor: Number(snapshotData.patrimonioTotal.toFixed(2)),
      saldo: Number(snapshotData.saldo.toFixed(2)),
      valorAtivos: Number(snapshotData.valorAtivos.toFixed(2)),
      tokensTotais: snapshotData.tokensTotais,
      eventType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("Erro no registerWalletSnapshot:", e);
    throw e;
  }
}

export const getWalletChart = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const uid = request.auth!.uid;
  const period = normalizePeriod(request.data?.period);
  const config = getPeriodConfig(period);

  try {
    const snapshot = await db
      .collection("usuarios")
      .doc(uid)
      .collection("patrimonioHistorico")
      .where(
        "createdAt",
        ">=",
        admin.firestore.Timestamp.fromDate(config.startDate)
      )
      .orderBy("createdAt", "asc")
      .get();

    const buckets = new Map<
      string,
      {
        label: string;
        value: number;
        createdAt: Date;
      }
    >();

    snapshot.docs.forEach((doc) => {
      const data = doc.data();

      if (!data.createdAt) return;

      const createdAt =
        data.createdAt as admin.firestore.Timestamp;

      const date = createdAt.toDate();
      const valor = Number(data.valor ?? 0);

      if (valor <= 0) return;

      const bucketDate = getBucketDate(date, config.bucketType);
      const key = getBucketKey(bucketDate);

      const current = buckets.get(key);

      if (!current || date > current.createdAt) {
        buckets.set(key, {
          label: getBucketLabel(bucketDate, config.bucketType),
          value: valor,
          createdAt: date,
        });
      }
    });

    let points: WalletChartPoint[] = Array.from(buckets.values())
      .sort((a, b) => {
        return a.createdAt.getTime() - b.createdAt.getTime();
      })
      .slice(-config.maxPoints)
      .map((point) => {
        return {
          label: point.label,
          value: Number(point.value.toFixed(2)),
          createdAt: point.createdAt.toISOString(),
        };
      });

    if (points.length < 2) {
      const current = await calculateWalletSnapshotData(uid);
      const now = new Date();

      if (current.patrimonioTotal > 0) {
        const start = config.startDate;
        const startBucket = getBucketDate(start, config.bucketType);
        const nowBucket = getBucketDate(now, config.bucketType);

        points = [
          {
            label: getBucketLabel(startBucket, config.bucketType),
            value: Number(current.patrimonioTotal.toFixed(2)),
            createdAt: start.toISOString(),
          },
          {
            label: getBucketLabel(nowBucket, config.bucketType),
            value: Number(current.patrimonioTotal.toFixed(2)),
            createdAt: now.toISOString(),
          },
        ];
      }
    }

    return {
      period,
      points,
    };
  } catch (e) {
    console.error("Erro no getWalletChart:", e);

    if (e instanceof HttpsError) throw e;

    throw new HttpsError(
      "internal",
      "Erro ao carregar gráfico da carteira"
    );
  }
});