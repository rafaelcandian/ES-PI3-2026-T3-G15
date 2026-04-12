import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Classe responsável por TODA a lógica de autenticação (backend)
class AuthService {

  // Instância do Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instância do banco de dados (Firestore)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CADASTRO DE USUÁRIO
  
  Future<String?> register({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
  }) async {
    try {

      // 🔹 Cria usuário no Firebase Authentication
      // Aqui só salva EMAIL e SENHA
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // 🔹 Pega o ID único do usuário (UID)
      String uid = user.user!.uid;

      // 🔹 Salva os dados adicionais no Firestore
      // (nome, cpf, telefone não ficam no Auth)
      await _db.collection('usuarios').doc(uid).set({
        'nome': nome,
        'email': email,
        'cpf': cpf,
        'telefone': telefone,
      });

      // Se deu tudo certo, retorna null
      return null;

    } catch (e) {
      // Se der erro, retorna o erro em texto
      return e.toString();
    }
  }

  // LOGIN
  Future<String?> login(String email, String senha) async {
    try {

      // Faz login com email e senha
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      return null;

    } catch (e) {
      return e.toString();
    }
  }

  // RECUPERAR SENHA
  Future<String?> resetPassword(String email) async {
    try {

      // Envia email de redefinição de senha
      await _auth.sendPasswordResetEmail(email: email);

      return null;

    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {

    // Encerra a sessão do usuário
    await _auth.signOut();
  }

  // USUÁRIO ATUAL

  User? get currentUser {

    // Retorna o usuário logado (ou null se não tiver)
    return _auth.currentUser;
  }
}