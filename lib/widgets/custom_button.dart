import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed; // Callback para o evento de pressionar

  const CustomButton({Key? key, required this.buttonText, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // Ação ao pressionar o botão
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFFB74D), // Cor amarela (ou use outro tom de amarelo)
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Bordas arredondadas
        ),
        elevation: 5, // Sombra do botão
        shadowColor: Colors.black.withOpacity(0.2), // Cor da sombra
      ),
      child: Text(
        buttonText, // Texto que aparece no botão
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Texto em branco
        ),
      ),
    );
  }
}