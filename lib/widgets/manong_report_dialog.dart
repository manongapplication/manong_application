import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/manong_report_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/card_container.dart';
import 'package:manong_application/widgets/image_picker_card.dart';
import 'package:manong_application/widgets/input_decorations.dart';

class ManongReportDialog extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final VoidCallback onSubmit;
  const ManongReportDialog({
    super.key,
    required this.serviceRequest,
    required this.onSubmit,
  });

  @override
  State<ManongReportDialog> createState() => _ManongReportDialogState();
}

class _ManongReportDialogState extends State<ManongReportDialog> {
  final Logger logger = Logger('ManongReportDialog');
  late ServiceRequest _serviceRequest;
  late VoidCallback _onSubmit;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? selectedSummaryIndex = 0;
  int _summaryCount = 0;
  List<File> _images = <File>[];
  String? _imagesError;
  bool _servicePaid = false;
  bool _isButtonLoading = false;
  String? _error;

  // More Details
  final TextEditingController _materialsUsedController =
      TextEditingController();
  final TextEditingController _laborDurationController =
      TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _issuesFoundController = TextEditingController();
  final TextEditingController _warrantyInfoController = TextEditingController();
  final TextEditingController _recommendationController =
      TextEditingController();
  bool? _customerPresent;
  bool _showMoreDetails = false;

  final List<Map<String, dynamic>> summaryCategories = [
    {
      'title': '✅ Fully Completed',
      'summaries': [
        'Successfully completed all service work',
        'Finished repairs as requested',
        'Completed installation successfully',
        'Performed maintenance and cleaning',
        'Fixed the issue and tested working',
      ],
    },
    {
      'title': '⚠️ Completed but Needs Follow-up',
      'summaries': [
        'Completed service with follow-up recommended',
        'Finished work but needs parts replacement',
        'Emergency repair completed, full service needed later',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    initializeComponents();
  }

  void initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _onSubmit = widget.onSubmit;
    _servicePaid = _serviceRequest.paymentStatus == PaymentStatus.paid;
  }

  Widget _buildShowMoreDetailsToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Additional Details (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _showMoreDetails = !_showMoreDetails;
            });
          },
          icon: Icon(
            _showMoreDetails ? Icons.expand_less : Icons.expand_more,
            color: AppColorScheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    if (!_showMoreDetails) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildEditableField(
          label: 'Materials Used',
          controller: _materialsUsedController,
          maxLines: 2,
          hintText: 'List materials used...',
        ),
        _buildEditableField(
          label: 'Labor Duration (hours)',
          controller: _laborDurationController,
          keyboardType: TextInputType.number,
          hintText: 'Enter hours worked...',
        ),
        _buildEditableField(
          label: 'Total Cost (₱)',
          controller: _totalCostController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          hintText: 'Enter total cost...',
        ),
        _buildCustomerPresentToggle(),
        _buildEditableField(
          label: 'Issues Found',
          controller: _issuesFoundController,
          maxLines: 2,
          hintText: 'Describe any issues found...',
        ),
        _buildEditableField(
          label: 'Recommendations',
          controller: _recommendationController,
          maxLines: 2,
          hintText: 'Provide recommendations...',
        ),
        _buildEditableField(
          label: 'Warranty Information',
          controller: _warrantyInfoController,
          maxLines: 2,
          hintText: 'Enter warranty details...',
        ),
      ],
    );
  }

  Widget _buildCustomerPresentToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Present',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            ChoiceChip(
              label: Text(
                'Yes',
                style: TextStyle(
                  color: _customerPresent == true
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: _customerPresent == true,
              onSelected: (selected) {
                setState(() {
                  _customerPresent = selected ? true : null;
                });
              },
              selectedColor: AppColorScheme.primaryColor,
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                'No',
                style: TextStyle(
                  color: _customerPresent == false
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: _customerPresent == false,
              onSelected: (selected) {
                setState(() {
                  _customerPresent = selected ? false : null;
                });
              },
              selectedColor: AppColorScheme.primaryColor,
              backgroundColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<int?> _showPaymentConfirmation() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Payment Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Did the customer pay for this service?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Option 1: Mark as paid
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yes, Mark as Paid',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Submit unpaid
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, 2);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'No, Submit as Unpaid',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 3: Cancel
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  void _submitManongReport(BuildContext context) async {
    if (!_servicePaid) {
      final action = await _showPaymentConfirmation();

      if (action == 0 || action == null) {
        // User canceled
        return;
      } else if (action == 1) {
        // User wants to mark as paid
        setState(() {
          _servicePaid = true;
        });
        // Wait a moment for UI update
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // If action == 2, continue with unpaid status
      logger.info('SQ $_servicePaid');
    }
    setState(() {
      _isButtonLoading = true;
      _error = null;
      _imagesError = null;
    });
    try {
      if (getSelectedSummary() == null) {
        SnackBarUtils.showWarning(
          context,
          'Please choose the summary in the options!',
        );
        return;
      }

      if (_images.isEmpty || _images.length > 3) {
        setState(() {
          _imagesError = 'You must upload between 1 and 3 images to continue.';
        });
      }

      if (!_formKey.currentState!.validate()) return;

      final details = ManongReport(
        id: 0,
        serviceRequestId: _serviceRequest.id!,
        manongId: _serviceRequest.manongId!,
        summary: getSelectedSummary()!,
        images: _images,
        details: _detailsController.text.isNotEmpty
            ? _detailsController.text
            : null,
        materialsUsed: _materialsUsedController.text.isNotEmpty
            ? _materialsUsedController.text
            : null,
        laborDuration: _laborDurationController.text.isNotEmpty
            ? int.tryParse(_laborDurationController.text)
            : null,
        issuesFound: _issuesFoundController.text.isNotEmpty
            ? _issuesFoundController.text
            : null,
        customerPresent: _customerPresent,
        totalCost: _totalCostController.text.isNotEmpty
            ? double.tryParse(_totalCostController.text)
            : null,
        warrantyInfo: _warrantyInfoController.text.isNotEmpty
            ? _warrantyInfoController.text
            : null,
        recommendations: _recommendationController.text.isNotEmpty
            ? _recommendationController.text
            : null,
      );

      logger.info('Manong Report Details ${details.images?.length}');

      final response = await ManongReportUtils().create(
        details: details,
        servicePaid: _servicePaid,
      );

      logger.info('Manong Report Respnse $response');

      if (response != null) {
        if (response['success'] == true) {
          SnackBarUtils.showSuccess(context, response['message']);
          Navigator.pop(context, {'success': true});
        } else {
          SnackBarUtils.showWarning(context, response['message']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error submitting manong report $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildUploadPhotos() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),

            Text(
              '${_images.length}/3',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          'Take photos of completed work as proof of service',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),

        const SizedBox(height: 12),

        ImagePickerCard(
          images: _images,
          onImageSelect: (List<File> images) {
            setState(() {
              _images = images;
            });
          },
        ),

        if (_imagesError != null) ...[
          const SizedBox(height: 4),
          Text(
            _imagesError ?? '',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w400),
          ),
        ],
      ],
    );
  }

  Widget _buildRequestPaid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.payments, color: AppColorScheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              _servicePaid ? 'Request is Paid' : 'Request is Unpaid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ],
        ),

        Switch(
          activeColor: AppColorScheme.primaryColor,
          inactiveTrackColor: AppColorScheme.backgroundGrey,
          value: _servicePaid,
          onChanged: _serviceRequest.paymentStatus == PaymentStatus.paid
              ? null
              : (value) {
                  setState(() {
                    _servicePaid = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildSummaryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequestPaid(),
        for (final category in summaryCategories) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              category['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int row = 0; row < 2; row++) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        int i = row * 2;
                        i < (row + 1) * 2 &&
                            i < (category['summaries'] as List<String>).length;
                        i++
                      ) ...[
                        if (i > row * 2) SizedBox(width: 8),
                        _buildChip(category, i),
                      ],
                    ],
                  ),
                ),
                if (row < 1) SizedBox(height: 8),
              ],
            ],
          ),
          if (category != summaryCategories.last) SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildChip(Map<String, dynamic> category, int index) {
    final summary = (category['summaries'] as List<String>)[index];
    final globalIndex = _getGlobalIndex(category, index);
    final active = selectedSummaryIndex == globalIndex;

    return FilterChip(
      label: Text(summary, style: TextStyle(fontSize: 12)),
      selected: active,
      onSelected: (_) {
        setState(() {
          selectedSummaryIndex = active ? null : globalIndex;
        });
      },
      selectedColor: AppColorScheme.primaryColor,
      backgroundColor: Colors.grey.shade300,
      labelStyle: TextStyle(
        color: active ? Colors.white : Colors.grey.shade700,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  int _getGlobalIndex(Map<String, dynamic> category, int localIndex) {
    int globalIndex = 0;
    for (final cat in summaryCategories) {
      final catSummaries = cat['summaries'] as List<String>;
      if (cat == category) {
        return globalIndex + localIndex;
      }
      globalIndex += catSummaries.length;
    }
    return globalIndex;
  }

  String? getSelectedSummary() {
    if (selectedSummaryIndex == null) return null;

    int currentIndex = 0;
    for (final category in summaryCategories) {
      final summaries = category['summaries'] as List<String>;
      if (selectedSummaryIndex! < currentIndex + summaries.length) {
        return summaries[selectedSummaryIndex! - currentIndex];
      }
      currentIndex += summaries.length;
    }
    return null;
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Manong Report',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildUploadPhotos(),
            const SizedBox(height: 14),
            _buildSummaryOptions(),
            const SizedBox(height: 14),

            _buildShowMoreDetailsToggle(),

            _buildAdditionalDetails(),

            const SizedBox(height: 14),
            Stack(
              children: [
                TextFormField(
                  controller: _detailsController,
                  decoration: inputDecoration('Enter details... (Optional)'),
                  maxLines: 5,
                  minLines: 3,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 20 || value.length > 300) {
                        return 'Details must be between 20 and 300 characters.';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      setState(() => _summaryCount = value.length),
                  keyboardType: TextInputType.multiline,
                ),
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: Text(
                    '$_summaryCount/300',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildState() {
    return Scrollbar(
      thickness: 6,
      radius: Radius.circular(3),
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildForm(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 8, right: 2),
        height: 520,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          color: AppColorScheme.backgroundGrey,
        ),
        child: Stack(
          children: [
            _buildState(),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isButtonLoading
                        ? null
                        : () {
                            _submitManongReport(context);
                            _onSubmit();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isButtonLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _materialsUsedController.dispose();
    _laborDurationController.dispose();
    _totalCostController.dispose();
    _issuesFoundController.dispose();
    _warrantyInfoController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }
}
