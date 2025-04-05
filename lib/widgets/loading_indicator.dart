import 'package:flutter/material.dart';

class SwapLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const SwapLoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/swap.png',
            width: size,
            height: size,
          ),
          const SizedBox(height: 16),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? const Color(0xFFFF8C00),
            ),
          ),
        ],
      ),
    );
  }
} 