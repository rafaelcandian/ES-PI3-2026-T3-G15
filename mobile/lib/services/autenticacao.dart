import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mescla_invest/services/totp_service.dart';

class TwoFactorLoginResult {
  final String email;
  final String senha;
  final bool setupRequired;
  final String? secret;
  final String? otpAuthUri;

  const TwoFactorLoginResult({
    required this.email,
    required this.senha,
    required this.setupRequired,
    this.secret,
    this.otpAuthUri,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TotpService _totp = TotpService();

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
      final user = credential.user;

      if (user == null) {
        throw Exception('Usuario nao encontrado');
      }

      final userRef = _db.collection('usuarios').doc(user.uid);
      final userDoc = await userRef.get();
      final data = userDoc.data() ?? <String, dynamic>{};
      final twoFactor = Map<String, dynamic>.from(data['twoFactor'] ?? {});
      final enabled = twoFactor['enabled'] == true;
      final secret = twoFactor['secret'] as String?;

      final setupRequired = !enabled || secret == null || secret.isEmpty;
      String? setupSecret;
      String? otpAuthUri;

      if (setupRequired) {
        setupSecret = _totp.generateSecret();
        otpAuthUri = _totp.buildOtpAuthUri(
          issuer: 'MesclaInvest',
          account: userEmail,
          secret: setupSecret,
        );

        await userRef.set({
          'twoFactor': {
            'enabled': false,
            'pendingSecret': setupSecret,
            'pendingCreatedAt': FieldValue.serverTimestamp(),
            'issuer': 'MesclaInvest',
          },
        }, SetOptions(merge: true));
      }

      await _auth.signOut();

      return TwoFactorLoginResult(
        email: userEmail,
        senha: senha,
        setupRequired: setupRequired,
        secret: setupSecret,
        otpAuthUri: otpAuthUri,
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
    } catch (e) {
      await _auth.signOut();
      throw Exception('Erro ao iniciar verificacao: $e');
    }
  }

  Future<String?> verifyTwoFactorLogin({
    required String email,
    required String senha,
    required String code,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final user = credential.user;

      if (user == null) {
        await _auth.signOut();
        return 'Usuario nao encontrado.';
      }

      final userRef = _db.collection('usuarios').doc(user.uid);
      final userDoc = await userRef.get();
      final data = userDoc.data() ?? <String, dynamic>{};
      final twoFactor = Map<String, dynamic>.from(data['twoFactor'] ?? {});
      final enabled = twoFactor['enabled'] == true;
      final secret = enabled
          ? twoFactor['secret'] as String?
          : twoFactor['pendingSecret'] as String?;

      if (secret == null || secret.isEmpty) {
        await _auth.signOut();
        return 'Chave de autenticacao nao encontrada.';
      }

      if (!_totp.verifyCode(secret, code)) {
        await _auth.signOut();
        return 'Codigo invalido.';
      }

      if (!enabled) {
        await userRef.update({
          'twoFactor.enabled': true,
          'twoFactor.secret': secret,
          'twoFactor.pendingSecret': FieldValue.delete(),
          'twoFactor.pendingCreatedAt': FieldValue.delete(),
          'twoFactor.enabledAt': FieldValue.serverTimestamp(),
          'twoFactor.issuer': 'MesclaInvest',
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Senha incorreta.';
      }

      return 'Erro ao concluir login.';
    } catch (e) {
      return 'Erro ao validar codigo: $e';
    }
  }

  Future<TwoFactorLoginResult> resetTwoFactorSetup({
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
