import 'package:flutter/material.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class RequestRefundScreen extends StatefulWidget {
  final ServiceRequest serviceRequest;
  const RequestRefundScreen({super.key, required this.serviceRequest});

  @override
  State<RequestRefundScreen> createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends State<RequestRefundScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(title: 'Request a Refund'),
      body: Container(),
    );
  }
}
