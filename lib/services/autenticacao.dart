// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// Classe responsável por TODA a lógica de autenticação (backend)
class AuthService {

  // Instância do Firebase Authentication (MOCK)
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instância do banco de dados (Firestore) (MOCK)
  // final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CADASTRO DE USUÁRIO
  
  Future<String?> register({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay de rede
    // Apenas validação básica, sem persistência
    if (email.isEmpty || senha.isEmpty) {
      return "Preencha todos os campos.";
    }
    return null; // Sucesso
  }

  // LOGIN
  Future<String?> login(String email, String senha) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay de rede
    if (email == "admin@mescla.com" && senha == "123456") {
      return null; // Login bem-sucedido
    } else {
      return "Login inválido";
    }
  }

  // RECUPERAR SENHA
  Future<String?> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay de rede
    return null; // Sucesso
  }

  // LOGOUT
  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay de rede
    // Não faz nada no mock
  }

  // USUÁRIO ATUAL

  // User? get currentUser {
  //   return _auth.currentUser;
  // }
  // MOCADO: Sempre retorna null para simular não logado
  dynamic get currentUser => null;
}