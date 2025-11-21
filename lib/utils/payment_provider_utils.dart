class PaymentProviderUtils {
  static String readable(String? provider) {
    if (provider == null || provider.isEmpty) return 'Unknown';

    switch (provider.toLowerCase()) {
      case 'gcash':
        return 'GCash';
      case 'paymaya':
        return 'PayMaya';
      case 'credit_card':
        return 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        // fallback to capitalizing first letter
        return provider[0].toUpperCase() + provider.substring(1);
    }
  }
}
