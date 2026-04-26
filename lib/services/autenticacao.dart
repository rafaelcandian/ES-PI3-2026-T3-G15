import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // CADASTRO
  // =========================
  Future<String?> register({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
  }) async {
    try {
      // 1. Cria usuário no Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      String uid = userCredential.user!.uid;

      // 2. Salva dados no Firestore
      await _db.collection("usuarios").doc(uid).set({
        "nome": nome,
        "email": email,
        "cpf": cpf,
        "telefone": telefone,
        "uid": uid,
        "criado_em": Timestamp.now(),
      });

      return null; // sucesso
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "E-mail já está em uso";
      } else if (e.code == 'weak-password') {
        return "Senha muito fraca";
      } else {
        return "Erro no cadastro";
      }
    } catch (e) {
      return "Erro inesperado";
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<String?> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Usuário não encontrado";
      } else if (e.code == 'wrong-password') {
        return "Senha incorreta";
      } else {
        return "Erro no login";
      }
    }
  }

  // =========================
  // RECUPERAR SENHA
  // =========================
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return "Erro ao enviar email";
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========================
  // USUÁRIO ATUAL
  // =========================
  User? get currentUser => _auth.currentUser;
}