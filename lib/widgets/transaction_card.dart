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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // bg-gray-50
        border: Border.all(color: Colors.grey[100]!), // border-gray-100
        borderRadius: BorderRadius.circular(16), // rounded-xl
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: // Amount Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),

                PriceTag(
                  price: paymentTransaction.amount,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColorScheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),

                if (paymentTransaction.paymentIdOnGateway != null) ...[
                  Text(
                    isRefundType ? 'Refund Id' : 'Payment Id',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          isRefundType
                              ? paymentTransaction.refundIdOnGateway ?? ''
                              : paymentTransaction.paymentIdOnGateway ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final id =
                              paymentTransaction.paymentIdOnGateway ?? '';
                          if (id.isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: id));
                            SnackBarUtils.showInfo(
                              navigatorKey.currentContext!,
                              'Payment ID copied to clipboard',
                            );
                          }
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: // Transaction Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Request Number',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentTransaction.metadata?['requestNumber'] ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
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
        : '${paymentTransaction.type.name}${paymentTransaction.status == PaymentStatus.pending ? ' - Pending' : ''}';

    String firstSentence =
        user != null &&
            user?.role == UserRole.manong &&
            paymentTransaction.userId != user?.id
        ? 'User'
        : 'You have';

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: PaymentTypeUtils.bgColor(
                    paymentTransaction.type,
                    paymentTransaction.status,
                  ),
                ),
                child: Text(
                  paymentType.toUpperCase(),
                  style: TextStyle(
                    color: PaymentTypeUtils.color(
                      paymentTransaction.type,
                      paymentTransaction.status,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),

              Text(
                createdDateFormatted,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildAmountArea(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '$firstSentence ${paymentTransaction.type == TransactionType.refund ? 'refunded' : paymentTransaction.status.name} ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                  WidgetSpan(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: PriceTag(price: paymentTransaction.amount),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(
                    text: ' via ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: PaymentProviderUtils.readable(
                      paymentTransaction.provider,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' for ${paymentTransaction.metadata?['subServiceType']} under ${paymentTransaction.metadata?['serviceType']} service.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
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
