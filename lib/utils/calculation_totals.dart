import 'package:manong_application/models/service_request.dart';

class CalculationTotals {
  final double _serviceTaxRate = 0.12;
  double get serviceTaxRate => _serviceTaxRate;

  double calculateSubTotal(ServiceRequest? userServiceRequest) {
    double total = 0;

    if (userServiceRequest == null) return 0;

    if (userServiceRequest.subServiceItem?.cost != null) {
      total += userServiceRequest.subServiceItem!.cost!.toDouble();
    }

    if (userServiceRequest.urgencyLevel?.price != null) {
      total += userServiceRequest.urgencyLevel!.price!.toDouble();
    }

    return total;
  }

  double calculateServiceTaxAmount(
    ServiceRequest? userServiceRequest,
    double tax,
  ) {
    return calculateSubTotal(userServiceRequest) * tax;
  }

  double calculateTotal(
    ServiceRequest? userServiceRequest,
    double? meters,
    double? tax,
  ) {
    double total = 0;

    if (userServiceRequest == null || meters == null || tax == null) return 0;

    if (userServiceRequest.subServiceItem?.fee != null) {
      total += userServiceRequest.subServiceItem!.fee!.toDouble();
    }

    if (userServiceRequest.urgencyLevel?.price != null) {
      total += userServiceRequest.urgencyLevel!.price!.toDouble();
    }

    // return total +
    //     calculateServiceTaxAmount(userServiceRequest, tax) +
    //     distanceFee(
    //       meters: meters,
    //       ratePerKm: userServiceRequest.serviceItem?.ratePerKm ?? 0,
    //     );

    return total;
  }

  double distanceFee({required double meters, required double ratePerKm}) {
    final distanceKm = meters / 1000;
    double totalPrice = distanceKm * ratePerKm;

    if (totalPrice >= 400) {
      totalPrice = 400;
    }
    return totalPrice;
  }
}
