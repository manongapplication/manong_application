import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/feedback_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';

class FeedbackUtils {
  final Logger logger = Logger('FeedbackUtils');

  Future<void> createFeedback({
    required int serviceRequestId,
    required int revieweeId,
    required int rating,
    String? comment,
    BottomNavProvider? navProvider,
  }) async {
    try {
      logger.info('_createFeedback started');
      final response = await FeedbackApiService().createFeedback(
        serviceRequestId: serviceRequestId,
        revieweeId: revieweeId,
        rating: rating,
        comment: comment,
      );

      if (response != null && response['data'] != null) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response['message'] ?? 'Feedback submitted successfully',
        );
        navProvider?.setHasNoFeedback(false);
      } else {
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          response?['message'] ?? 'Failed to create feedback',
        );
      }
    } catch (e) {
      logger.severe('Error creating feedback $e');
    }
  }

  Future<void> leaveAReviewDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController commentController,
    required int commentCount,
    required ServiceRequest serviceRequest,
    BottomNavProvider? navProvider,
    VoidCallback? onClose,
  }) async {
    int rating = 0;
    String? errorRating;
    bool isButtonLoadingModal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    Text(
                      'Leave a star rating and an optional comment to share your experience.',
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                rating = index + 1;
                                errorRating = null;
                              });

                              if (rating <= 2) {
                                dissastisfiedDialog(
                                  context: context,
                                  rating: rating,
                                  serviceRequestId: serviceRequest.id!,
                                  reveweeId: serviceRequest.manongId!,
                                  formKey: formKey,
                                  commentController: commentController,
                                  commentCount: commentCount,
                                  onClose: () => onClose,
                                );
                                return;
                              }
                            },
                            child: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: AppColorScheme.gold,
                              size: 48,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    Column(
                      children: [
                        Form(
                          key: formKey,
                          child: Stack(
                            children: [
                              TextFormField(
                                onChanged: (value) {
                                  setModalState(
                                    () => commentCount = value.length,
                                  );
                                },
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (value.length < 5 ||
                                        value.length > 300) {
                                      return 'Review must be between 5 and 300 characters.';
                                    }
                                  }
                                  return null;
                                },
                                controller: commentController,
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
                                  '$commentCount/300',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          errorRating ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),

                        const SizedBox(height: 4),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isButtonLoadingModal
                                ? null
                                : () async {
                                    if (rating == 0) {
                                      setModalState(() {
                                        errorRating =
                                            'Please select a star rating before submitting.';
                                      });

                                      return;
                                    }

                                    setModalState(() {
                                      isButtonLoadingModal = true;
                                    });

                                    if (!formKey.currentState!.validate()) {
                                      setModalState(() {
                                        isButtonLoadingModal = false;
                                      });
                                      return;
                                    }

                                    await createFeedback(
                                      serviceRequestId: serviceRequest.id!,
                                      revieweeId: serviceRequest.manongId!,
                                      rating: rating,
                                      comment: commentController.text.isNotEmpty
                                          ? commentController.text
                                          : null,
                                      navProvider: navProvider,
                                    );

                                    Navigator.of(
                                      navigatorKey.currentContext!,
                                    ).pop();

                                    if (onClose != null) onClose();
                                  },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColorScheme.primaryColor,
                            ),
                            child: isButtonLoadingModal
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Submit'),
                          ),
                        ),
                      ],
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

  Future<void> dissastisfiedDialog({
    required BuildContext context,
    required int rating,
    required int serviceRequestId,
    required int reveweeId,
    required GlobalKey<FormState> formKey,
    required TextEditingController commentController,
    required int commentCount,
    VoidCallback? onClose,
  }) async {
    final List<String> reasons = [
      'Service was slower than expected',
      'Poor quality of work',
      'Staff were unhelpful or rude',
      'Service was too expensive',
    ];

    int? selectedReasonIndex;
    bool isButtonLoadingModal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (builder) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return WillPopScope(
              onWillPop: () async {
                commentController.clear();
                setModalState(() => commentCount = 0);
                return true;
              },
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                    left: 18,
                    right: 18,
                    top: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Why were you dissatisfied?',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),

                          Positioned(
                            top: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                commentController.clear();
                                setModalState(() => commentCount = 0);
                                Navigator.of(context).pop();

                                if (onClose != null) onClose();
                              },
                              child: Icon(Icons.close, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Please select at least 1 reason for your rating, or optionally leave a comment.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: List.generate(reasons.length, (index) {
                                final selectedReason = reasons[index];
                                final active = selectedReasonIndex == index;
                                return FilterChip(
                                  label: Text(
                                    selectedReason,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onSelected: (_) {
                                    setModalState(() {
                                      if (selectedReasonIndex == index) {
                                        selectedReasonIndex = null;
                                      } else {
                                        selectedReasonIndex = index;
                                      }
                                    });
                                  },
                                  selectedColor: AppColorScheme.primaryColor,
                                  backgroundColor: Colors.grey.shade300,
                                  selected: active,
                                  labelStyle: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  showCheckmark: false,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Form(
                        key: formKey,
                        child: Stack(
                          children: [
                            TextFormField(
                              onChanged: (value) {
                                setModalState(
                                  () => commentCount = value.length,
                                );
                              },
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (value.length < 20 || value.length > 300) {
                                    return 'Review must be between 20 and 300 characters.';
                                  }
                                }
                                return null;
                              },
                              controller: commentController,
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
                                '$commentCount/300',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isButtonLoadingModal
                              ? null
                              : () {
                                  setModalState(() {
                                    isButtonLoadingModal = true;
                                  });

                                  if (!formKey.currentState!.validate()) {
                                    setModalState(() {
                                      isButtonLoadingModal = false;
                                    });
                                    return;
                                  }

                                  createFeedback(
                                    serviceRequestId: serviceRequestId,
                                    revieweeId: reveweeId,
                                    rating: rating,
                                    comment: selectedReasonIndex != null
                                        ? '${reasons[selectedReasonIndex!]}${commentController.text.isNotEmpty ? ' - ${commentController.text}' : ''}'
                                        : (commentController.text.isNotEmpty
                                              ? commentController.text
                                              : null),
                                  );

                                  Navigator.of(
                                    navigatorKey.currentContext!,
                                  ).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColorScheme.primaryColor,
                          ),
                          child: isButtonLoadingModal
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
