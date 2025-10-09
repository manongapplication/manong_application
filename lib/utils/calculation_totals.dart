import 'package:manong_application/models/service_request.dart';

class CalculationTotals {
  final double _serviceTaxRate = 0.12;
  double get serviceTaxRate => _serviceTaxRate;

  double calculateSubTotal(ServiceRequest? userServiceRequest) {
    double total = 0;

    if (userServiceRequest == null) return 0;

    if (userServiceRequest.subServiceItem?.fee != null) {
      total += userServiceRequest.subServiceItem!.fee!.toDouble();
    }

    if (userServiceRequest.urgencyLevel?.price != null) {
      total += userServiceRequest.urgencyLevel!.price!.toDouble();
    }

    return total;
  }

  double calculateServiceTaxAmount(ServiceRequest? userServiceRequest) {
    return calculateSubTotal(userServiceRequest) * _serviceTaxRate;
  }

  double calculateTotal(ServiceRequest? userServiceRequest) {
    double total = 0;

    if (userServiceRequest == null) return 0;

    if (userServiceRequest.subServiceItem?.fee != null) {
      total += userServiceRequest.subServiceItem!.fee!.toDouble();
    }

    if (userServiceRequest.urgencyLevel?.price != null) {
      total += userServiceRequest.urgencyLevel!.price!.toDouble();
    }

    return total + calculateServiceTaxAmount(userServiceRequest);
  }
}
