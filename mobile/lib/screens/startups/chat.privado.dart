import 'package:flutter/material.dart';
import 'package:mescla_invest/screens/startups/startup_data.dart';

class ChatPrivadoPage extends StatefulWidget {
  const ChatPrivadoPage({super.key});

  @override
  State<ChatPrivadoPage> createState() => _ChatPrivadoPageState();
}

class _ChatPrivadoPageState extends State<ChatPrivadoPage> {
  final TextEditingController _messageController = TextEditingController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Olá! Tenho dúvidas sobre a estratégia de expansão da startup.',
      isUser: true,
      time: '14:22',
    ),
    _ChatMessage(
      text: 'Claro! Estamos priorizando expansão regional antes de buscar novos mercados.',
      isUser: false,
      time: '14:24',
    ),
    _ChatMessage(
      text: 'Existe previsão de nova rodada após a captação atual?',
      isUser: true,
      time: '14:26',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          time: 'agora',
        ),
      );
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final dynamic arguments = ModalRoute.of(context)?.settings.arguments;
    final StartupData? startup =
    arguments is StartupData ? arguments : null;

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020818),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFC53D)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startup?.title ?? 'Chat privado',
              style: const TextStyle(
                color: Color(0xFFFFC53D),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const Text(
              'Canal privado do investidor',
              style: TextStyle(
                color: Color(0xFF9CADDD),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101731),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0x22FFC53D),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFFC53D),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este canal é exclusivo para investidores com tokens desta startup.',
                    style: TextStyle(
                      color: Color(0xFFB0B8D1),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                return _MessageBubble(message: message);
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF070A1E),
                border: Border(
                  top: BorderSide(
                    color: Color(0x12FFFFFF),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Digite sua pergunta privada...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF7D91C2),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF101731),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC53D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF0F1749),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFFFC53D)
              : const Color(0xFF101731),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
            color: const Color(0x12FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? const Color(0xFF0F1749)
                    : Colors.white,
                fontSize: 13,
                height: 1.45,
                fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color: isUser
                    ? const Color(0x990F1749)
                    : const Color(0xFF7D91C2),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}