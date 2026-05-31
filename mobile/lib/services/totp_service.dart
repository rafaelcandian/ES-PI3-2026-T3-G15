// Autor: Rafael Antonio Candian
// RA: 25016954

import 'dart:math';
import 'dart:typed_data';

/* Implementação do Algoritmo TOTP (Time-based One-Time Password) conforme RFC 6238.
   O serviço deriva tokens de 6 dígitos a partir de uma chave secreta e da janela de tempo atual,
   utilizando HMAC-SHA1 para garantir a integridade e unicidade do código. */
class TotpService {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const int _periodSeconds = 30;
  static const int _digits = 6;

  String generateSecret({int length = 20}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return _base32Encode(bytes);
  }

  String buildOtpAuthUri({
    required String issuer,
    required String account,
    required String secret,
  }) {
    final label = Uri.encodeComponent('$issuer:$account');
    final query = Uri(
      queryParameters: {
        'secret': secret,
        'issuer': issuer,
        'algorithm': 'SHA1',
        'digits': _digits.toString(),
        'period': _periodSeconds.toString(),
      },
    ).query;

    return 'otpauth://totp/$label?$query';
  }

  /* Protocolo de Verificação com Janela de Tolerância (Drift).
     Considera o tempo atual e aplica um offset (window) para mitigar dessincronização 
     de clock entre o servidor e o dispositivo do usuário, conforme recomenda a RFC. */
  bool verifyCode(String secret, String code, {int window = 1}) {
    final normalizedCode = code.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final counter = now ~/ _periodSeconds;

    for (var offset = -window; offset <= window; offset++) {
      if (generateCode(secret, counter: counter + offset) == normalizedCode) {
        return true;
      }
    }

    return false;
  }

  /* Motor de derivação do token (Hotp Motor).
     1. Decodifica a semente Base32 para bytes puros.
     2. Calcula o contador de tempo (Unix Epoch / 30s).
     3. Gera o Hash HMAC-SHA1 da semente combinada com o contador.
     4. Aplica 'Dynamic Truncation' para extrair 31 bits do hash e converter em 6 dígitos decimais. */
  String generateCode(String secret, {int? counter}) {
    final key = _base32Decode(secret);
    /* O contador incrementa a cada 30 segundos conforme o padrão RFC */
    final timeCounter =
        counter ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _periodSeconds;
    final counterBytes = Uint8List(8);
    var value = timeCounter;

    /* Converte o contador para bytes Big-endian */
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xff;
      value >>= 8;
    }

    /* Aplica HMAC-SHA1 para derivar o código */
    final hash = _hmacSha1(key, counterBytes);
    final offset = hash.last & 0x0f;
    final binary =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    final otp = binary % pow(10, _digits).toInt();

    return otp.toString().padLeft(_digits, '0');
  }

  String _base32Encode(List<int> bytes) {
    var output = StringBuffer();
    var buffer = 0;
    var bitsLeft = 0;

    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        output.write(_alphabet[(buffer >> (bitsLeft - 5)) & 31]);
        bitsLeft -= 5;
      }
    }

    if (bitsLeft > 0) {
      output.write(_alphabet[(buffer << (5 - bitsLeft)) & 31]);
    }

    return output.toString();
  }

  List<int> _base32Decode(String input) {
    final normalized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    var buffer = 0;
    var bitsLeft = 0;
    final output = <int>[];

    for (final char in normalized.runes) {
      final value = _alphabet.indexOf(String.fromCharCode(char));
      if (value < 0) continue;

      buffer = (buffer << 5) | value;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }

    return output;
  }

  List<int> _hmacSha1(List<int> key, List<int> message) {
    var normalizedKey = List<int>.from(key);

    if (normalizedKey.length > 64) {
      normalizedKey = _sha1(normalizedKey);
    }

    if (normalizedKey.length < 64) {
      normalizedKey = [
        ...normalizedKey,
        ...List<int>.filled(64 - normalizedKey.length, 0),
      ];
    }

    final outerKeyPad = normalizedKey.map((byte) => byte ^ 0x5c).toList();
    final innerKeyPad = normalizedKey.map((byte) => byte ^ 0x36).toList();
    final innerHash = _sha1([...innerKeyPad, ...message]);

    return _sha1([...outerKeyPad, ...innerHash]);
  }

  /* Implementação manual do SHA-1 (Secure Hash Algorithm 1).
     Opera sobre blocos de 512 bits, realizando 80 iterações de funções bitwise 
     (AND, OR, XOR, ROTL) para gerar o resumo de 160 bits necessário para o HMAC. */
  List<int> _sha1(List<int> message) {
    final bytes = List<int>.from(message);
    final bitLength = bytes.length * 8;

    bytes.add(0x80);
    while ((bytes.length % 64) != 56) {
      bytes.add(0);
    }

    for (var i = 7; i >= 0; i--) {
      bytes.add((bitLength >> (i * 8)) & 0xff);
    }

    var h0 = 0x67452301;
    var h1 = 0xefcdab89;
    var h2 = 0x98badcfe;
    var h3 = 0x10325476;
    var h4 = 0xc3d2e1f0;

    for (var chunkStart = 0; chunkStart < bytes.length; chunkStart += 64) {
      final words = List<int>.filled(80, 0);

      for (var i = 0; i < 16; i++) {
        final j = chunkStart + i * 4;
        words[i] =
            ((bytes[j] << 24) |
                (bytes[j + 1] << 16) |
                (bytes[j + 2] << 8) |
                bytes[j + 3]) &
            0xffffffff;
      }

      for (var i = 16; i < 80; i++) {
        words[i] = _rotl(
          words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16],
          1,
        );
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      for (var i = 0; i < 80; i++) {
        late int f;
        late int k;

        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5a827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ed9eba1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8f1bbcdc;
        } else {
          f = b ^ c ^ d;
          k = 0xca62c1d6;
        }

        final temp = (_rotl(a, 5) + f + e + k + words[i]) & 0xffffffff;
        e = d;
        d = c;
        c = _rotl(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
    }

    return [
      ..._int32ToBytes(h0),
      ..._int32ToBytes(h1),
      ..._int32ToBytes(h2),
      ..._int32ToBytes(h3),
      ..._int32ToBytes(h4),
    ];
  }

  int _rotl(int value, int shift) {
    return ((value << shift) | (value >> (32 - shift))) & 0xffffffff;
  }

  List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }
}
