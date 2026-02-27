import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/payment_transaction.dart';
import 'package:manong_application/models/transaction_type.dart';
import 'package:manong_application/models/user_role.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/date_utils.dart';
import 'package:manong_application/utils/payment_provider_utils.dart';
import 'package:manong_application/utils/payment_type_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/price_tag.dart';

class TransactionCard extends StatelessWidget {
  final PaymentTransaction paymentTransaction;
  final AppUser? user;
  const TransactionCard({
    super.key,
    required this.paymentTransaction,
    this.user,
  });

  Widget _buildAmountArea() {
    bool isRefundType = paymentTransaction.type == TransactionType.refund;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                PriceTag(
                  price: paymentTransaction.amount,
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColorScheme.primaryColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (paymentTransaction.paymentIdOnGateway != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    isRefundType ? 'REFUND ID' : 'PAYMENT ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isRefundType
                              ? paymentTransaction.refundIdOnGateway ?? ''
                              : paymentTransaction.paymentIdOnGateway ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColorScheme.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          final id =
                              paymentTransaction.paymentIdOnGateway ?? '';
                          if (id.isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: id));
                            SnackBarUtils.showInfo(
                              navigatorKey.currentContext!,
                              'Payment ID copied',
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColorScheme.primaryColor.withOpacity(
                              0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.copy,
                            size: 12,
                            color: AppColorScheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Request Number Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'REQUEST NO.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentTransaction.metadata?['requestNumber'] ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime createdAt = DateTime.parse(
      paymentTransaction.createdAt.toString(),
    );
    String createdDateFormatted = formatRelativeDate(createdAt);

    String paymentType = paymentTransaction.refundRequest != null
        ? paymentTransaction.refundRequest?.amount == paymentTransaction.amount
              ? 'Full Refund'
              : 'Partial Refund'
        : paymentTransaction.type.name.toUpperCase();

    String firstSentence =
        user != null &&
            user?.role == UserRole.manong &&
            paymentTransaction.userId != user?.id
        ? 'User'
        : 'You';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with type and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: PaymentTypeUtils.bgColor(
                    paymentTransaction.type,
                    paymentTransaction.status,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PaymentTypeUtils.color(
                      paymentTransaction.type,
                      paymentTransaction.status,
                    ).withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      paymentTransaction.type == TransactionType.refund
                          ? Icons.undo_rounded
                          : Icons.payment_rounded,
                      size: 12,
                      color: PaymentTypeUtils.color(
                        paymentTransaction.type,
                        paymentTransaction.status,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentType,
                      style: TextStyle(
                        color: PaymentTypeUtils.color(
                          paymentTransaction.type,
                          paymentTransaction.status,
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Date
              Text(
                createdDateFormatted,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Amount area
          _buildAmountArea(),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: firstSentence,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text:
                        ' ${paymentTransaction.type == TransactionType.refund ? 'refunded' : paymentTransaction.status.name} ',
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  WidgetSpan(
                    child: PriceTag(
                      price: paymentTransaction.amount,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(
                    text: ' via ',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: PaymentProviderUtils.readable(
                      paymentTransaction.provider,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                  TextSpan(
                    text: ' for ',
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text:
                        paymentTransaction.metadata?['subServiceType'] ??
                        'service',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(
                    text: ' under ',
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: paymentTransaction.metadata?['serviceType'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(
                    text: ' service.',
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
