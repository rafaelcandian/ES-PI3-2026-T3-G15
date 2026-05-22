import 'package:cloud_functions/cloud_functions.dart';

class PerguntaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String?> enviarPergunta({
    required String startupId,
    required String texto,
    required bool isPrivada,
  }) async {
    try {
      await _functions.httpsCallable('sendQuestion').call({
        'startupId': startupId,
        'texto': texto,
        'isPrivada': isPrivada,
      });
      
      return null; // Sucesso
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Você precisa ser investidor para enviar perguntas privadas.';
      } else if (e.code == 'invalid-argument') {
        return 'Dados inválidos. Verifique os campos e tente novamente.';
      }
      return 'Erro ao enviar pergunta: ${e.message}';
    } catch (e) {
      return 'Erro inesperado ao enviar pergunta.';
    }
  }

  Future<List<Map<String, dynamic>>> buscarPerguntas(String startupId) async {
    try {
      final result = await _functions.httpsCallable('getPerguntas').call({
        'startupId': startupId,
      });

      final List<dynamic> data = result.data as List<dynamic>? ?? [];
      
      return data.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
