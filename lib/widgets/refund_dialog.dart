import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/refund_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/api/service_request_api_service.dart'; // Add this import

class RefundDialog {
  static Future<void> show(
    BuildContext context, {
    required ServiceRequest request,
    VoidCallback? onClose,
  }) async {
    final reasonController = TextEditingController();
    int reasonCount = 0;
    int? selectedReasonIndex;
    bool isButtonLoading = false;
    final formKey = GlobalKey<FormState>();

    final List<String> reasons = [
      'Accidentally created the request',
      'Manong hasn\'t arrived yet',
      'Found another service provider',
      'Changed my mind about the service',
      'Wrong service or details selected',
      'Duplicate request created',
      'Other (please specify)',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                  left: 18,
                  right: 18,
                  top: 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Text(
                            'State your reason for refund',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              onClose?.call();
                            },
                            child: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please select a reason for your refund or leave a short note below:',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(reasons.length, (index) {
                          final active = selectedReasonIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: FilterChip(
                              label: Text(
                                reasons[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: active,
                              onSelected: (_) {
                                setModalState(() {
                                  selectedReasonIndex = active
                                      ? null
                                      : index; // toggle
                                });
                              },
                              selectedColor: AppColorScheme.primaryColor,
                              backgroundColor: Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Form(
                      key: formKey,
                      child: Stack(
                        children: [
                          TextFormField(
                            onChanged: (value) {
                              setModalState(() => reasonCount = value.length);
                            },
                            validator: (value) {
                              // Case 1: No reason selected
                              if (selectedReasonIndex == null) {
                                return 'Please select at least one reason.';
                              }

                              // Case 2: "Other (please specify)" selected → must type
                              if (reasons[selectedReasonIndex!] ==
                                  'Other (please specify)') {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please specify your reason.';
                                }
                                if (value.trim().length < 20 ||
                                    value.trim().length > 300) {
                                  return 'Reason must be between 20 and 300 characters.';
                                }
                              }

                              return null;
                            },
                            controller: reasonController,
                            decoration: inputDecoration(
                              'Write a comment (optional)',
                            ),
                            maxLines: 5,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),

                          Positioned(
                            bottom: 4,
                            right: 8,
                            child: Text(
                              '$reasonCount/300',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isButtonLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isButtonLoading = true);

                                String reasonText = '';

                                final reason = selectedReasonIndex != null
                                    ? reasons[selectedReasonIndex!]
                                    : '';
                                final note = reasonController.text.trim();

                                if (reason.isNotEmpty) {
                                  reasonText = reason;
                                }

                                if (note.isNotEmpty) {
                                  if (reason.isNotEmpty) {
                                    reasonText += '. $note';
                                  } else {
                                    reasonText = note;
                                  }
                                }

                                Map<String, dynamic>? response =
                                    await RefundUtils().create(
                                      request,
                                      reasonText,
                                    );

                                if (response != null) {
                                  if (response['data'] != null) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).pop();
                                    onClose?.call();

                                    // Fetch the latest service request status
                                    ServiceRequest? updatedRequest;
                                    try {
                                      updatedRequest =
                                          await ServiceRequestApiService()
                                              .fetchServiceRequest(request.id!);
                                    } catch (e) {
                                      // If fetching fails, use the original request
                                      updatedRequest = request;
                                    }

                                    // Show success dialog
                                    await showDialog(
                                      context: navigatorKey.currentContext!,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                            response['success'] == true
                                                ? 'Refund Requested'
                                                : 'Error',
                                          ),
                                          content: Text(
                                            response['message'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                // Close the dialog and pop with updated data
                                                Navigator.of(context).pop();
                                                Navigator.pop(
                                                  navigatorKey.currentContext!,
                                                  {
                                                    'updated': true,
                                                    'status':
                                                        updatedRequest
                                                            ?.status ??
                                                        request.status,
                                                  },
                                                );
                                              },
                                              child: Text('Okay'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Show error in dialog instead of snackbar
                                    await showDialog(
                                      context: navigatorKey.currentContext!,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Error'),
                                          content: Text(
                                            response['message'] ??
                                                'Unknown error occurred',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Okay'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                } else {
                                  // Show error in dialog instead of snackbar
                                  await showDialog(
                                    context: navigatorKey.currentContext!,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Error'),
                                        content: Text(
                                          'Error creating refund request! Please Try again later.',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Okay'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }

                                setModalState(() => isButtonLoading = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: isButtonLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Refund'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
