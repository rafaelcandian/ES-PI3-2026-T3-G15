// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Handlers para as ofertas de compra e venda e sistema de matching.

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../../shared/auth";
import {db} from "../../shared/firebase";