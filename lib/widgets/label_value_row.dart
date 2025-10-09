import 'package:flutter/material.dart';

class LabelValueRow extends StatelessWidget {
  final String? label;
  final String? value;
  final Widget? labelWidget;
  final Widget? valueWidget;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final List<Widget>? labelTrailing;
  final List<Widget>? valueTrailing;

  const LabelValueRow({
    super.key,
    this.label,
    this.value,
    this.labelWidget,
    this.valueWidget,
    this.labelStyle,
    this.valueStyle,
    this.labelTrailing,
    this.valueTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        labelWidget != null
            ? labelWidget!
            : Text(label ?? '', style: labelStyle ?? TextStyle(fontSize: 14)),
        if (valueTrailing != null) ...[Column(children: valueTrailing ?? [])],
        valueWidget != null
            ? valueWidget!
            : Text(value ?? '', style: valueStyle ?? TextStyle(fontSize: 14)),
        if (valueTrailing != null) ...[Column(children: valueTrailing ?? [])],
      ],
    );
  }
}
