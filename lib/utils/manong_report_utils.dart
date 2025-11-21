import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_report_api_service.dart';
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/widgets/manong_report_dialog.dart';

class ManongReportUtils {
  final Logger logger = Logger('ManongReportUtils');
  Future<Map<String, dynamic>?> create({
    required ManongReport details,
    bool? servicePaid,
  }) async {
    try {
      final response = await ManongReportApiService().createManongReport(
        details: details,
        servicePaid: servicePaid,
      );

      if (response != null) {
        return response;
      }
    } catch (e) {
      logger.severe('Error creating manong report ${e.toString()}');
    }

    return null;
  }

  Future<Map<String, dynamic>?> update({
    required int id,
    required ManongReport details,
  }) async {
    try {
      final response = await ManongReportApiService().updateManongReport(
        id: id,
        details: details,
      );

      if (response != null) {
        return response;
      }
    } catch (e) {
      logger.severe('Error updating manong report ${e.toString()}');
    }

    return null;
  }

  Future<dynamic> showManongReport(
    BuildContext context, {
    required ServiceRequest serviceRequest,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: ManongReportDialog(
              serviceRequest: serviceRequest,
              onSubmit: () {},
            ),
          ),
        );
      },
    );
  }
}
