/* Victória Nobre - 25016398 */
/* Guilherme Henrique Moreira - 25006702 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mescla_invest/services/totp_service.dart';

/* Objeto de Transferência de Dados (DTO) para o estado da autenticação multifator.
   Encapsula a transição de estados entre o Firebase Auth (Identidade) e o desafio de token (Segurança). */
class TwoFactorLoginResult {
  final String email;
  final String senha;
  final bool setupRequired; /* Flag que indica a ausência de semente TOTP no registro do usuário (Enrolment) */
  final String? secret; /* Chave Base32 gerada via entropia segura para provisionamento de apps autenticadores */
  final String? otpAuthUri; /* URI em conformidade com o Google Authenticator para configuração via Deep Link ou QR Code */
  final bool requiresVerification; /* Gatilho lógico para a navegação forçada à tela de desafio de token */

  const TwoFactorLoginResult({
    required this.email,
    required this.senha,
    required this.setupRequired,
    this.secret,
    this.otpAuthUri,
    this.requiresVerification = false,
  });
}

/* Serviço de Fachada (Facade Pattern) que orquestra a segurança de acesso da plataforma.
   Implementa a segregação entre Autenticação (Firebase Auth) e Autorização/Perfil (Firestore). */
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TotpService _totp = TotpService();

  // =========================
  // CADASTRO
  // =========================
  /* Registra novo usuário e inicializa perfil no Firestore com saldo zerado */
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

  /* Inicia o protocolo de desafio 2FA. Implementa o padrão 'Fail-safe': se o usuário possui 2FA,
     a sessão do Firebase é encerrada imediatamente após a validação da senha, 
     impedindo qualquer acesso aos dados do Firestore antes da prova de posse do token temporal. */
  Future<TwoFactorLoginResult> startTwoFactorLogin(
    String email,
    String senha,
  ) async {
    try {
      /* Primeiro autentica no Firebase para validar e-mail e senha */
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final userEmail = credential.user?.email ?? email;
      final user = credential.user;

      if (user == null) {
        throw Exception('Usuario nao encontrado');
      }

      /* Busca configurações de segurança personalizadas do usuário */
      final userRef = _db.collection('usuarios').doc(user.uid);
      final userDoc = await userRef.get();

      final data = userDoc.data() ?? <String, dynamic>{};
      final twoFactor = Map<String, dynamic>.from(
        data['twoFactor'] ?? {},
      );

      final enabled = twoFactor['enabled'] == true;
      final secret = twoFactor['secret'] as String?;

      // 2FA DESATIVADO → LOGIN NORMAL
      if (!enabled || secret == null || secret.isEmpty) {
        return TwoFactorLoginResult(
          email: userEmail,
          senha: senha,
          setupRequired: false,
          requiresVerification: false,
        );
      }

      // 2FA ATIVO → OBRIGA VERIFICAÇÃO DE CÓDIGO TOTP
      /* Desloga temporariamente até que o código correto seja fornecido no próximo passo */
      await _auth.signOut();

      return TwoFactorLoginResult(
        email: userEmail,
        senha: senha,
        setupRequired: false,
        requiresVerification: true,
      );
    } on FirebaseAuthException catch (e) {
      await _auth.signOut();

      if (e.code == 'user-not-found') {
        throw Exception("Usuario nao encontrado");
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception("Senha incorreta");
      } else {
        throw Exception("Erro no login");
      }
    } catch (e) {
      await _auth.signOut();
      throw Exception('Erro ao iniciar verificacao: $e');
    }
  }

  /* Provisiona uma nova semente de segurança (Seed) usando o TotpService. 
     O segredo é persistido no Firestore com status pendente (Merge: true), seguindo o 
     princípio de defesa em profundidade até que a primeira validação seja concluída. */
  Future<TwoFactorLoginResult> createTwoFactorSetup() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuario nao autenticado');
    }

    final userEmail = user.email ?? '';
    final secret = _totp.generateSecret();
    final otpAuthUri = _totp.buildOtpAuthUri(
      issuer: 'MesclaInvest',
      account: userEmail,
      secret: secret,
    );

    /* Salva o segredo como pendente até que o usuário confirme o primeiro código com sucesso */
    await _db.collection('usuarios').doc(user.uid).set({
      'twoFactor': {
        'enabled': false,
        'pendingSecret': secret,
        'pendingCreatedAt': FieldValue.serverTimestamp(),
        'issuer': 'MesclaInvest',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return TwoFactorLoginResult(
      email: userEmail,
      senha: '',
      setupRequired: true,
      secret: secret,
      otpAuthUri: otpAuthUri,
    );
  }

  Future<String?> confirmTwoFactorSetup(String code) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return 'Usuario nao autenticado.';
      }

      final userRef = _db.collection('usuarios').doc(user.uid);
      final userDoc = await userRef.get();
      final data = userDoc.data() ?? <String, dynamic>{};
      final twoFactor = Map<String, dynamic>.from(data['twoFactor'] ?? {});
      final pendingSecret = twoFactor['pendingSecret'] as String?;

      if (pendingSecret == null || pendingSecret.isEmpty) {
        return 'Chave de autenticacao nao encontrada.';
      }

      if (!_totp.verifyCode(pendingSecret, code)) {
        return 'Codigo invalido.';
      }

      await userRef.set({
        'twoFactor': {
          'enabled': true,
          'secret': pendingSecret,
          'pendingSecret': FieldValue.delete(),
          'pendingCreatedAt': FieldValue.delete(),
          'enabledAt': FieldValue.serverTimestamp(),
          'issuer': 'MesclaInvest',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Erro ao ativar 2FA: $e';
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
      final secret = twoFactor['secret'] as String?;

      // Se não tiver 2FA ativo, libera login normal
      if (!enabled || secret == null || secret.isEmpty) {
        return null;
      }

      if (!_totp.verifyCode(secret, code)) {
        await _auth.signOut();
        return 'Codigo invalido.';
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
