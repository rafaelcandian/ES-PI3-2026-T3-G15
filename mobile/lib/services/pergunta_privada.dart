/* Victória Nobre - 25016398 */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/* Canal direto de comunicação entre investidor e startup para dúvidas privadas */
class PerguntaPrivadaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> enviarPerguntaPrivada({
    required String startupId,
    required String startupNome,
    required String pergunta,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final textoPergunta = pergunta.trim();

    if (startupId.trim().isEmpty) {
      throw Exception('Startup inválida.');
    }

    if (textoPergunta.isEmpty) {
      throw Exception('Digite uma pergunta antes de enviar.');
    }

    await _firestore
        .collection('startups')
        .doc(startupId)
        .collection('perguntasPrivadas')
        .add({
          'startupId': startupId,
          'startupNome': startupNome,
          'pergunta': textoPergunta,
          'resposta': '',
          'respondida': false,
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listarPerguntasPrivadas({
    required String startupId,
  }) {
    return _firestore
        .collection('startups')
        .doc(startupId)
        .collection('perguntasPrivadas')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
