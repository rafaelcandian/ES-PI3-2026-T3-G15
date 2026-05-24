import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TwoFactorLoginResult {
  final String sessionId;
  final String email;
  final String senha;

  const TwoFactorLoginResult({
    required this.sessionId,
    required this.email,
    required this.senha,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      String uid = userCredential.user!.uid;

      // 2. Salva dados no Firestore
      await _db.collection("usuarios").doc(uid).set({
        "nome": nome,
        "email": email,
        "cpf": cpf,
        "telefone": telefone,
        "uid": uid,
        "criado_em": Timestamp.now(),

        // Novos campos para saldo e tokens
        "saldo": 0.0,
        "tokens": {},
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
      await _auth.signInWithEmailAndPassword(email: email, password: senha);

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

  Future<TwoFactorLoginResult> startTwoFactorLogin(
    String email,
    String senha,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final userEmail = credential.user?.email ?? email;
      final callable = _functions.httpsCallable('sendLoginTwoFactorCode');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);

      await _auth.signOut();

      return TwoFactorLoginResult(
        sessionId: data['sessionId'] as String,
        email: userEmail,
        senha: senha,
      );
    } on FirebaseAuthException catch (e) {
      await _auth.signOut();

      if (e.code == 'user-not-found') {
        throw Exception("Usuario nao encontrado");
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Senha incorreta");
      } else {
        throw Exception("Erro no login");
      }
    } on FirebaseFunctionsException catch (e) {
      await _auth.signOut();
      throw Exception(e.message ?? 'Erro ao enviar codigo de verificacao');
    } catch (e) {
      await _auth.signOut();
      throw Exception('Erro ao iniciar verificacao: $e');
    }
  }

  Future<String?> verifyTwoFactorLogin({
    required String email,
    required String senha,
    required String sessionId,
    required String code,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyLoginTwoFactorCode');
      await callable.call({
        'sessionId': sessionId,
        'email': email,
        'code': code,
      });

      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'deadline-exceeded') {
        return 'Codigo expirado. Solicite um novo codigo.';
      } else if (e.code == 'permission-denied') {
        return 'Codigo invalido.';
      } else if (e.code == 'not-found') {
        return 'Sessao de verificacao nao encontrada.';
      }

      return e.message ?? 'Erro ao validar codigo.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Senha incorreta.';
      }

      return 'Erro ao concluir login.';
    } catch (e) {
      return 'Erro ao validar codigo: $e';
    }
  }

  Future<TwoFactorLoginResult> resendTwoFactorCode({
    required String email,
    required String senha,
  }) async {
    return startTwoFactorLogin(email, senha);
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
