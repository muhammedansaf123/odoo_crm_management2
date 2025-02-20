import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double fontSize;
  final double borderRadius;
  final double height;
  final bool isBackground;
  final bool isBorder;
  const CustomButton({
    super.key,
    this.isBackground = true,
    this.isBorder = false,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.teal,
    this.fontSize = 16,
    this.borderRadius = 8.0,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isBackground ? backgroundColor : Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.teal,width: 2),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        minimumSize: Size(double.infinity, height),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isBorder ? Colors.teal : Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
