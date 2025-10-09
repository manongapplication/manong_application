import 'package:flutter/material.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final String sign;
  final TextStyle? textStyle;

  const PriceTag({
    super.key,
    required this.price,
    this.sign = '₱',
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(sign.toString(), style: textStyle),
        const SizedBox(width: 4),
        Text(price.toString(), style: textStyle),
      ],
    );
  }
}
