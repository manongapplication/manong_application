import 'package:flutter/material.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final String sign;
  final TextStyle? textStyle;
  final bool showDecimals;

  const PriceTag({
    super.key,
    required this.price,
    this.sign = '₱',
    this.textStyle,
    this.showDecimals = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(sign.toString(), style: textStyle),
        const SizedBox(width: 4),
        Text(
          showDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0),
          style: textStyle,
        ),
      ],
    );
  }
}
