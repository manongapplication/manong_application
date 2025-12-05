import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/dialog_utils.dart';
import 'package:manong_application/widgets/image_picker_card.dart';

class DetailedManongReportCard extends StatefulWidget {
  final ManongReport report;
  final VoidCallback? onTap;
  final Function(ManongReport)? onSave;
  final bool showFullDetails;
  final bool isManong;

  const DetailedManongReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onSave,
    this.showFullDetails = false,
    required this.isManong,
  });

  @override
  State<DetailedManongReportCard> createState() =>
      _DetailedManongReportCardState();
}

class _DetailedManongReportCardState extends State<DetailedManongReportCard> {
  late ManongReport _editableReport;
  bool _isEditing = false;
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _materialsUsedController =
      TextEditingController();
  final TextEditingController _laborDurationController =
      TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _issuesFoundController = TextEditingController();
  final TextEditingController _recommendationController =
      TextEditingController();
  final TextEditingController _warrantyInfoController = TextEditingController();
  bool? _customerPresent;
  final baseImageUrl = dotenv.env['APP_URL'];
  final Logger logger = Logger('DetailedManongReportCard');
  List<File> _images = <File>[];

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
    _editableReport = widget.report;
    _images = <File>[];
    _initializeControllers();
  }

  void _initializeControllers() {
    _summaryController.text = _editableReport.summary;
    _detailsController.text = _editableReport.details ?? '';
    _materialsUsedController.text = _editableReport.materialsUsed ?? '';
    _laborDurationController.text =
        _editableReport.laborDuration?.toString() ?? '';
    _totalCostController.text = _editableReport.totalCost?.toString() ?? '';
    _issuesFoundController.text = _editableReport.issuesFound ?? '';
    _recommendationController.text = _editableReport.recommendations ?? '';
    _warrantyInfoController.text = _editableReport.warrantyInfo ?? '';
    _customerPresent = _editableReport.customerPresent;
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _initializeControllers(); // Reset to original values
    });
  }

  void _saveChanges() {
    List<File>? imagesToSend;

    if (_images.isNotEmpty) {
      // Filter out server file paths and only include actual local files
      imagesToSend = _images.where((file) {
        final path = file.path;
        // Check if this is NOT a server file path
        final isServerPath =
            path.startsWith('uploads') ||
            path.startsWith('[') ||
            path.contains('manong_reports');
        return !isServerPath;
      }).toList();

      // If no valid new images, set to null
      if (imagesToSend.isEmpty) {
        imagesToSend = null;
      }
    }

    final updatedReport = _editableReport.copyWith(
      summary: _summaryController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      materialsUsed: _materialsUsedController.text.trim().isEmpty
          ? null
          : _materialsUsedController.text.trim(),
      laborDuration: _laborDurationController.text.trim().isEmpty
          ? null
          : int.tryParse(_laborDurationController.text.trim()),
      images: imagesToSend,
      issuesFound: _issuesFoundController.text.trim().isEmpty
          ? null
          : _issuesFoundController.text.trim(),
      customerPresent: _customerPresent,
      totalCost: _totalCostController.text.trim().isEmpty
          ? null
          : double.tryParse(_totalCostController.text.trim()),
      warrantyInfo: _warrantyInfoController.text.trim().isEmpty
          ? null
          : _warrantyInfoController.text.trim(),
      recommendations: _recommendationController.text.trim().isEmpty
          ? null
          : _recommendationController.text.trim(),
    );

    setState(() {
      _editableReport = updatedReport;
      _isEditing = false;
    });

    widget.onSave?.call(updatedReport);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Report',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '#${_editableReport.serviceRequestId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColorScheme.primaryColor,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_editableReport.createdAt != null) ...[
                  Text(
                    _formatDate(_editableReport.createdAt!),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
                if (_editableReport.createdAt != null) ...[
                  Text(
                    _formatTime(_editableReport.createdAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),

            if (widget.isManong && !_isEditing) ...[
              const SizedBox(width: 12),
              _buildEditButton(),
            ],

            if (_isEditing) ...[
              const SizedBox(width: 8),
              _buildActionButtons(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorScheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.edit, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _cancelEditing,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, size: 16, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _saveChanges,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
        ),
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

  Widget _buildImageSection() {
    // Only show "Upload Photos" section when editing
    if (_isEditing) {
      int actualImageCount = _images.expand((file) {
        final cleanedPaths = file.path
            .replaceAll(RegExp(r'[\[\]"]'), '')
            .replaceAll("\\", "/")
            .replaceAll("//", "/")
            .split(',')
            .where((path) => path.trim().isNotEmpty)
            .toList();
        return cleanedPaths;
      }).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upload Photos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '$actualImageCount/3',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'New photos replace existing • Upload proof of completed work',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ImagePickerCard(
            images: _images,
            onImageSelect: (List<File> images) {
              setState(() {
                _images = images.isNotEmpty ? images : [];
              });
            },
          ),
        ],
      );
    } else {
      // When not editing, just show the image grid if there are images
      if (_editableReport.images == null || _editableReport.images!.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildImageGrid();
    }
  }

  Widget _buildImageGrid() {
    if (_editableReport.images == null) return const SizedBox.shrink();
    final images = _editableReport.images;
    if (images != null && images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Images',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  controller: ScrollController(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: images!.expand((file) {
                      final cleanedPaths = file.path
                          .replaceAll(RegExp(r'[\[\]"]'), '')
                          .replaceAll("\\", "/")
                          .replaceAll("//", "/")
                          .split(',');

                      return cleanedPaths.map((path) {
                        final imageUrl = baseImageUrl != null
                            ? '$baseImageUrl/$path'
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                if (imageUrl.isNotEmpty) {
                                  showImageDialog(
                                    navigatorKey.currentContext!,
                                    imageUrl,
                                  );
                                }
                              },
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.broken_image),
                                      height: 150,
                                      width: 100,
                                    )
                                  : const Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    final isSelected = _summaryController.text == summary;

    return FilterChip(
      label: Text(summary, style: TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _summaryController.text = summary;
        });
      },
      selectedColor: AppColorScheme.primaryColor,
      backgroundColor: Colors.grey.shade300,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              onSelected: _isEditing
                  ? (selected) {
                      setState(() {
                        _customerPresent = selected ? true : null;
                      });
                    }
                  : null,
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
              onSelected: _isEditing
                  ? (selected) {
                      setState(() {
                        _customerPresent = selected ? false : null;
                      });
                    }
                  : null,
              selectedColor: AppColorScheme.primaryColor,
              backgroundColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColorScheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? AppColorScheme.primaryColor).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColorScheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColorScheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColorScheme.backgroundGrey,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 16),

              // Summary (editable when editing)
              if (_isEditing) ...[
                Visibility(
                  visible: false,
                  child: _buildEditableField(
                    label: 'Summary',
                    controller: _summaryController,
                    maxLines: 2,
                    hintText: 'Enter service summary...',
                  ),
                ),
                _buildSummaryOptions(),
              ] else ...[
                Text(
                  _editableReport.summary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Images Section (only shows upload UI when editing)
              _buildImageSection(),

              // Details Section (always show when there's content or when editing)
              if (_editableReport.details != null &&
                  _editableReport.details!.isNotEmpty) ...[
                _buildInfoSection('Details', _editableReport.details!),
              ] else if (_isEditing) ...[
                _buildEditableField(
                  label: 'Details',
                  controller: _detailsController,
                  maxLines: 3,
                  hintText: 'Enter service details...',
                ),
              ],

              // Additional Information in editing mode
              if (_isEditing) ...[
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
              ] else ...[
                // Display mode for additional information
                if (_editableReport.materialsUsed != null &&
                    _editableReport.materialsUsed!.isNotEmpty) ...[
                  _buildInfoSection(
                    'Materials Used',
                    _editableReport.materialsUsed!,
                  ),
                ],
                if (_editableReport.laborDuration != null) ...[
                  _buildInfoChip(
                    '${_editableReport.laborDuration}h Labor',
                    Icons.timer,
                  ),
                ],
                if (_editableReport.totalCost != null) ...[
                  _buildInfoChip(
                    '₱${_editableReport.totalCost!.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ],
                if (_editableReport.customerPresent == true) ...[
                  _buildInfoChip(
                    'Customer Present',
                    Icons.person,
                    Colors.green,
                  ),
                ],
                if (_editableReport.issuesFound != null &&
                    _editableReport.issuesFound!.isNotEmpty) ...[
                  _buildInfoSection(
                    'Issues Found',
                    _editableReport.issuesFound!,
                  ),
                ],
                if (_editableReport.recommendations != null &&
                    _editableReport.recommendations!.isNotEmpty) ...[
                  _buildInfoSection(
                    'Recommendations',
                    _editableReport.recommendations!,
                  ),
                ],
                if (_editableReport.warrantyInfo != null &&
                    _editableReport.warrantyInfo!.isNotEmpty) ...[
                  _buildInfoSection(
                    'Warranty Information',
                    _editableReport.warrantyInfo!,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    _materialsUsedController.dispose();
    _laborDurationController.dispose();
    _totalCostController.dispose();
    _issuesFoundController.dispose();
    _recommendationController.dispose();
    _warrantyInfoController.dispose();
    super.dispose();
  }
}
