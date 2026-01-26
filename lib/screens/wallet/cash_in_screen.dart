import 'package:flutter/material.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class CashInScreen extends StatefulWidget {
  const CashInScreen({super.key});

  @override
  State<CashInScreen> createState() => _CashInScreenState();
}

class _CashInScreenState extends State<CashInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: myAppBar(title: 'Cash In'));
  }
}
