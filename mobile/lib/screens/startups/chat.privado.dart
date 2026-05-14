import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mescla_invest/screens/startups/startup_data.dart';
import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

class ChatPrivadoPage extends StatefulWidget {
  const ChatPrivadoPage({super.key});

  @override
  State<ChatPrivadoPage> createState() => _ChatPrivadoPageState();
}

class _ChatPrivadoPageState extends State<ChatPrivadoPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _verificandoAcesso = true;
  bool _temAcesso = false;
  bool _enviando = false;
  bool _verificacaoIniciada = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _verificarAcesso(StartupData startup) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || startup.id.isEmpty) {
        if (!mounted) return;

        setState(() {
          _temAcesso = false;
          _verificandoAcesso = false;
        });

        return;
      }

      final ativoDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('ativos')
          .doc(startup.id)
          .get();

      final data = ativoDoc.data();

      final quantidadeTokens =
          (data?['quantidadeTokens'] as num?)?.toInt() ?? 0;

      if (!mounted) return;

      setState(() {
        _temAcesso = ativoDoc.exists && quantidadeTokens > 0;
        _verificandoAcesso = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _temAcesso = false;
        _verificandoAcesso = false;
      });
    }
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(StartupData startup) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FirebaseFirestore.instance
        .collection('startups')
        .doc(startup.id)
        .collection('chatsPrivados')
        .doc(uid)
        .collection('mensagens');
  }

  Future<void> _sendMessage(StartupData startup) async {
    final text = _messageController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || user == null || _enviando || !_temAcesso) return;

    setState(() {
      _enviando = true;
    });

    try {
      await _messagesRef(startup).add({
        'texto': text,
        'senderId': user.uid,
        'senderEmail': user.email,
        'startupId': startup.id,
        'startupNome': startup.title,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      await FirebaseFirestore.instance
          .collection('startups')
          .doc(startup.id)
          .collection('chatsPrivados')
          .doc(user.uid)
          .set({
        'startupId': startup.id,
        'startupNome': startup.title,
        'userId': user.uid,
        'userEmail': user.email,
        'ultimaMensagem': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível enviar a mensagem.');
    } finally {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = ModalRoute.of(context)?.settings.arguments;
    final StartupData? startup = arguments is StartupData ? arguments : null;

    if (startup == null) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          backgroundColor: AppColors.fundo,
          elevation: 0,
          title: const Text(
            'Chat privado',
            style: TextStyle(
              color: AppColors.destaque,
              fontWeight: FontWeight.w900,
            ),
          ),
          iconTheme: const IconThemeData(
            color: AppColors.destaque,
          ),
        ),
        body: const Center(
          child: Text(
            'Startup não encontrada.',
            style: TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (!_verificacaoIniciada) {
      _verificacaoIniciada = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verificarAcesso(startup);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.destaque,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startup.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.destaque,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Canal privado do investidor',
              style: TextStyle(
                color: AppColors.textoMuitoFraco,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const _AtmosphericBackground(),

          if (_verificandoAcesso)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.destaque,
              ),
            )
          else if (!_temAcesso)
            _BlockedAccess(startup: startup)
          else
            Column(
              children: [
                const _PrivateChannelBanner(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesRef(startup)
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.destaque,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar mensagens.',
                            style: TextStyle(
                              color: AppColors.textoFraco,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const _EmptyChatState();
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final message = _ChatMessage.fromFirestore(docs[index]);

                          return _MessageBubble(message: message);
                        },
                      );
                    },
                  ),
                ),

                _MessageInputBar(
                  controller: _messageController,
                  loading: _enviando,
                  onSend: () => _sendMessage(startup),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ===================== BACKGROUND =====================

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.azul.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -130,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.destaque.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.roxo.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BANNER =====================

class _PrivateChannelBanner extends StatelessWidget {
  const _PrivateChannelBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: premiumCardDecoration(
        radius: 20,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.destaque.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.destaque.withOpacity(0.28),
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppColors.destaque,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Este canal é exclusivo para investidores com tokens desta startup.',
              style: TextStyle(
                color: AppColors.textoFraco,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== ACESSO BLOQUEADO =====================

class _BlockedAccess extends StatelessWidget {
  final StartupData startup;

  const _BlockedAccess({
    required this.startup,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: premiumCardDecoration(
            radius: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.destaque.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.destaque.withOpacity(0.28),
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.destaque,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Canal privado bloqueado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para acessar o chat privado da ${startup.title}, você precisa possuir tokens desta startup.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textoFraco,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destaque,
                    side: const BorderSide(
                      color: AppColors.bordaDestaque,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Voltar para detalhes',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== EMPTY STATE =====================

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: premiumCardDecoration(
            radius: 24,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.destaque,
                size: 38,
              ),
              SizedBox(height: 14),
              Text(
                'Nenhuma mensagem ainda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Envie sua primeira pergunta privada para iniciar a conversa com a startup.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoFraco,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== INPUT =====================

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(
            top: BorderSide(
              color: AppColors.bordaClara,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: AppColors.textoPrincipal,
                ),
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Digite sua pergunta privada...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: loading ? null : onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.destaqueClaro,
                      AppColors.destaqueEscuro,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.destaque.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: loading
                    ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: AppColors.fundo,
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  color: AppColors.fundo,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== MODEL =====================

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  factory _ChatMessage.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final senderId = data['senderId']?.toString() ?? '';
    final text = data['texto']?.toString() ?? '';
    final createdAt = data['createdAt'];

    return _ChatMessage(
      text: text,
      isUser: senderId == currentUid,
      time: _formatTime(createdAt),
    );
  }

  static String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'agora';

    final date = value.toDate();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

// ===================== BUBBLE =====================

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 290,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.destaque : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
            color: AppColors.bordaClara,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? AppColors.fundo : AppColors.textoPrincipal,
                fontSize: 13,
                height: 1.45,
                fontWeight: isUser ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color: isUser
                    ? AppColors.fundo.withOpacity(0.65)
                    : AppColors.textoMuitoFraco,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}